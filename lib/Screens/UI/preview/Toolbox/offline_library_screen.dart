import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/services/storage_service.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/course_material.dart';
import 'package:go_study/services/profile.dart';
import 'package:go_study/Screens/UI/preview/detailScreens/pdf_viewer_screen.dart';
import 'package:go_study/Screens/UI/preview/Settings/subscription_plans_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_study/Screens/Shared/premium_dialog.dart';

class OfflineLibraryScreen extends StatefulWidget {
  const OfflineLibraryScreen({super.key});

  @override
  State<OfflineLibraryScreen> createState() => _OfflineLibraryScreenState();
}

class _OfflineLibraryScreenState extends State<OfflineLibraryScreen> {
  final _storageService = StorageService();
  final _dbService = DatabaseService(
    uid: Supabase.instance.client.auth.currentUser?.id,
  );

  List<CourseMaterial> _offlineMaterials = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOfflineMaterials();
  }

  Future<void> _loadOfflineMaterials() async {
    setState(() => _isLoading = true);
    try {
      final ids = await _storageService.getOfflineMaterialIds();
      if (ids.isEmpty) {
        setState(() {
          _offlineMaterials = [];
          _isLoading = false;
        });
        return;
      }

      // Fetch full material details from DB using the IDs
      // Note: In a real offline scenario, we should have cached these details too.
      // For this implementation, we'll try to fetch them if online.
      final materials = await _dbService.getMaterialsByIds(ids);

      setState(() {
        _offlineMaterials = materials;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error loading library: $e")));
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.offlineLibraryTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<UserProfile>(
        stream: _dbService.userProfile,
        builder: (context, snapshot) {
          // Always unlocked in free version

          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_offlineMaterials.isEmpty) {
            return _buildEmptyState(l10n);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _offlineMaterials.length,
            itemBuilder: (context, index) {
              final material = _offlineMaterials[index];
              return _buildMaterialCard(material, colorScheme, l10n);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 64,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.offlineLibraryEmptyTitle,
            style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.offlineLibraryEmptyBody,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialCard(
      CourseMaterial material, ColorScheme colorScheme, AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            material.fileType.toLowerCase() == 'pdf'
                ? Icons.picture_as_pdf_rounded
                : Icons.description_rounded,
            color: colorScheme.primary,
          ),
        ),
        title: Text(
          material.title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          l10n.localCopySuffix(material.materialCategory),
          style: GoogleFonts.outfit(fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
          onPressed: () => _confirmDelete(material, l10n),
        ),
        onTap: () => _openOfflineMaterial(material, l10n),
      ),
    );
  }

  Future<void> _openOfflineMaterial(CourseMaterial material, AppLocalizations l10n) async {
    try {
      final decryptedFile = await _storageService.decryptAndGetFile(
        material.id,
      );
      if (mounted) {
        if (material.fileType.toLowerCase() == 'pdf') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PDFViewerScreen(
                url: decryptedFile
                    .path, // PDFViewer will need to handle file paths
                title: material.title,
                isLocalFile: true,
              ),
            ),
          );
        } else {
          // Handle other file types...
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.offlineFormatNotSupported),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to decrypt file: $e")));
      }
    }
  }

  void _confirmDelete(CourseMaterial material, AppLocalizations l10n) {
    showPremiumGeneralDialog(
      context: context,
      barrierLabel: l10n.deleteOfflineCopyTitle,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0F172A)
            : Colors.white,
        surfaceTintColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PremiumDialogHeader(
              title: l10n.deleteOfflineCopyTitle,
              subtitle: l10n.removeFromDeviceSubtitle,
              icon: Icons.cloud_off_rounded,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  Text(
                    l10n.deleteOfflineCopyBody(material.title),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            l10n.cancel,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: PremiumSubmitButton(
                          label: l10n.deleteNowButton,
                          isLoading: false,
                          onPressed: () async {
                            await _storageService.deleteOffline(material.id);
                            if (context.mounted) {
                              Navigator.pop(context);
                              _loadOfflineMaterials();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_person_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Premium Feature",
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Offline Library is available for Silver and Gold members. Upgrade now to save materials and study anywhere!",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionPlansScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text("UPGRADE NOW"),
            ),
          ],
        ),
      ),
    );
  }
}
