import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:go_study/Screens/Shared/constanst.dart';
import 'package:go_study/Screens/Shared/premium_dialog.dart';
import 'package:go_study/core/error_handler.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/news_post.dart';
import 'package:go_study/services/profile.dart';

/// Admin-only screen to create or edit a [NewsPost]. Creation broadcasts the
/// post to every student (see [DatabaseService.createNewsPost]).
class NewsComposerScreen extends StatefulWidget {
  const NewsComposerScreen({super.key, this.existing});

  final NewsPost? existing;

  @override
  State<NewsComposerScreen> createState() => _NewsComposerScreenState();
}

class _NewsComposerScreenState extends State<NewsComposerScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late final DatabaseService _db;

  XFile? _pickedImage;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existing?.title ?? '');
    _bodyController = TextEditingController(text: widget.existing?.body ?? '');
    _db = DatabaseService(uid: Supabase.instance.client.auth.currentUser?.id);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 82,
    );
    if (picked != null) setState(() => _pickedImage = picked);
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final l10n = AppLocalizations.of(context)!;
    final userModel = context.read<UserModel>();
    if (userModel.role != UserRole.admin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.newsAdminOnlyMessage)),
      );
      Navigator.pop(context);
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);

    try {
      final title = _titleController.text.trim();
      final body = _bodyController.text.trim();

      String? imageUrl = widget.existing?.imageUrl;
      if (_pickedImage != null) {
        final Uint8List bytes = await _pickedImage!.readAsBytes();
        imageUrl = await _db.uploadNewsImage(bytes, title);
      }

      if (_isEditing) {
        await _db.updateNewsPost(
          widget.existing!.copyWith(
            title: title,
            body: body,
            imageUrl: imageUrl,
          ),
        );
      } else {
        await _db.createNewsPost(
          NewsPost(
            authorId: userModel.uid,
            authorName: userModel.name,
            title: title,
            body: body,
            imageUrl: imageUrl,
          ),
        );
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? l10n.newsPostUpdatedSnack : l10n.newsPostPublishedSnack,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      navigator.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getFriendlyMessage(e)),
            backgroundColor: const Color(0xFF991B1B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? l10n.newsComposerEditTitle : l10n.newsComposerNewTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            PremiumTextField(
              controller: _titleController,
              label: l10n.newsTitleFieldLabel,
              hint: l10n.newsTitleFieldHint,
              icon: Icons.title_rounded,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.newsTitleRequiredValidator
                  : null,
            ),
            const SizedBox(height: 18),
            PremiumTextField(
              controller: _bodyController,
              label: l10n.newsBodyFieldLabel,
              hint: l10n.newsBodyFieldHint,
              icon: Icons.notes_rounded,
              maxLines: 8,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.newsBodyRequiredValidator
                  : null,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.newsUploadCoverLabel,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildImagePreview(theme),
              ),
            ),
            const SizedBox(height: 32),
            PremiumSubmitButton(
              label: _isEditing ? l10n.saveButton : l10n.newsPublishButton,
              isLoading: _saving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(ThemeData theme) {
    if (_pickedImage != null) {
      return FutureBuilder<Uint8List>(
        future: _pickedImage!.readAsBytes(),
        builder: (context, snap) => snap.hasData
            ? Image.memory(snap.data!, fit: BoxFit.cover)
            : const Center(child: CircularProgressIndicator()),
      );
    }
    final existingUrl = widget.existing?.imageUrl;
    if (existingUrl != null && existingUrl.isNotEmpty) {
      return CachedNetworkImage(imageUrl: existingUrl, fit: BoxFit.cover);
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.cloud_upload_outlined,
          size: 30,
          color: theme.colorScheme.primary.withOpacity(0.5),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.uploadCoverPhotoLabel,
          style: GoogleFonts.outfit(
            color: theme.colorScheme.primary.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
