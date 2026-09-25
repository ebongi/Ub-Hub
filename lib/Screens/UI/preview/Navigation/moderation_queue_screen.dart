import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:go_study/Screens/UI/preview/detailScreens/material_download_actions.dart';
import 'package:go_study/core/error_handler.dart';
import 'package:go_study/core/error_view.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/course_material.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/profile.dart';
import 'package:go_study/theme/app_radius.dart';
import 'package:go_study/theme/app_spacing.dart';

/// Admin-only queue of materials submitted by non-contributor users, awaiting
/// approve/reject — the UI front-end for moderate_material() (see
/// supabase/migrations/hybrid_content_moderation.sql). RLS already enforces
/// admin-only access to both the underlying data and the RPC; this screen
/// isn't itself a security boundary.
class ModerationQueueScreen extends StatefulWidget {
  const ModerationQueueScreen({super.key});

  @override
  State<ModerationQueueScreen> createState() => _ModerationQueueScreenState();
}

class _ModerationQueueScreenState extends State<ModerationQueueScreen> {
  late DatabaseService _db;
  late Stream<List<CourseMaterial>> _pendingStream;
  UserProfile? _userProfile;
  final Set<String> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _db = DatabaseService(uid: Supabase.instance.client.auth.currentUser?.id);
    _pendingStream = _db.getPendingMaterials();
    _db.userProfile.listen((profile) {
      if (mounted) setState(() => _userProfile = profile);
    });
  }

  Future<void> _approve(CourseMaterial material) async {
    setState(() => _busyIds.add(material.id));
    try {
      await _db.moderateMaterial(material.id, approve: true);
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(
          context,
          AppLocalizations.of(context)!.materialApprovedMessage,
        );
      }
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _busyIds.remove(material.id));
    }
  }

  Future<void> _reject(CourseMaterial material) async {
    final l10n = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.rejectReasonDialogTitle),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(hintText: l10n.rejectReasonHint),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.rejectButton,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busyIds.add(material.id));
    try {
      await _db.moderateMaterial(
        material.id,
        approve: false,
        reason: reasonController.text.trim().isEmpty
            ? null
            : reasonController.text.trim(),
      );
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(
          context,
          AppLocalizations.of(context)!.materialRejectedMessage,
        );
      }
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _busyIds.remove(material.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.moderationQueueTitle)),
      body: StreamBuilder<List<CourseMaterial>>(
        stream: _pendingStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(
              onRetry: () =>
                  setState(() => _pendingStream = _db.getPendingMaterials()),
            );
          }

          final pending = snapshot.data ?? [];
          if (pending.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.task_alt_rounded,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.noSubmissionsPendingMessage,
                    style: GoogleFonts.outfit(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: pending.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final material = pending[index];
              final isBusy = _busyIds.contains(material.id);
              final isPdf = material.fileType.toLowerCase() == 'pdf';

              return Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => openMaterialFile(
                        context: context,
                        dbService: _db,
                        userProfile: _userProfile,
                        material: material,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isPdf
                                ? Icons.picture_as_pdf_outlined
                                : Icons.description_outlined,
                            color: isPdf ? Colors.red : Colors.blue,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  material.title,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if ((material.description ?? '').isNotEmpty)
                                  Text(
                                    material.description!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isBusy ? null : () => _reject(material),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                            child: Text(l10n.rejectButton),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: FilledButton(
                            onPressed: isBusy ? null : () => _approve(material),
                            child: isBusy
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(l10n.approveButton),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
