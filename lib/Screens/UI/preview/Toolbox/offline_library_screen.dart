import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neo/services/storage_service.dart';
import 'package:neo/services/database.dart';
import 'package:neo/services/course_material.dart';
import 'package:neo/Screens/UI/preview/detailScreens/pdf_viewer_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Offline Library",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _offlineMaterials.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _offlineMaterials.length,
              itemBuilder: (context, index) {
                final material = _offlineMaterials[index];
                return _buildMaterialCard(material, colorScheme);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
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
            "Your offline library is empty.",
            style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            "Download materials to access them without data.",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialCard(CourseMaterial material, ColorScheme colorScheme) {
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
          "${material.materialCategory} • Local Copy",
          style: GoogleFonts.outfit(fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
          onPressed: () => _confirmDelete(material),
        ),
        onTap: () => _openOfflineMaterial(material),
      ),
    );
  }

  Future<void> _openOfflineMaterial(CourseMaterial material) async {
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
            const SnackBar(
              content: Text("Format not supported for offline viewing yet"),
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

  void _confirmDelete(CourseMaterial material) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Offline Copy?"),
        content: Text(
          "This will remove the secured copy of '${material.title}' from your device. You can re-download it later.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await _storageService.deleteOffline(material.id);
              Navigator.pop(context);
              _loadOfflineMaterials();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
