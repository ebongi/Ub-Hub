import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/services/database.dart';
import 'package:go_study/services/bot_knowledge.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_study/Screens/Shared/premium_dialog.dart';
import 'package:go_study/core/error_handler.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:io';

class KnowledgeManagerScreen extends StatefulWidget {
  const KnowledgeManagerScreen({super.key});

  @override
  State<KnowledgeManagerScreen> createState() => _KnowledgeManagerScreenState();
}

class _KnowledgeManagerScreenState extends State<KnowledgeManagerScreen> {
  late final DatabaseService _dbService;
  final _currentUser = Supabase.instance.client.auth.currentUser;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _dbService = DatabaseService(uid: _currentUser?.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.ubKnowledgeBaseTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<BotKnowledge>>(
        stream: _dbService.getBotKnowledge(_currentUser!.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final knowledge = snapshot.data ?? [];
          if (knowledge.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_rounded,
                    size: 64,
                    color: colorScheme.primary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noUbKnowledgeYet,
                    style: GoogleFonts.outfit(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.addUniversityFactsSubtitle,
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: knowledge.length,
            itemBuilder: (context, index) {
              final k = knowledge[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  title: Text(
                    k.title,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    k.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                    ),
                    onPressed: () => _deleteKnowledge(k.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: "pdf_upload",
            onPressed: _isUploading ? null : _pickAndProcessPdf,
            icon: _isUploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf_rounded),
            label: Text(_isUploading ? l10n.processingLabel : l10n.uploadUbPdfButton),
            backgroundColor: Colors.orange,
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: "manual_add",
            onPressed: _showAddKnowledgeDialog,
            icon: const Icon(Icons.add_business_rounded),
            label: Text(l10n.addUbInfoButton),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndProcessPdf() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) return;

    setState(() => _isUploading = true);

    try {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();

      // Extract text using Syncfusion
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final String text = PdfTextExtractor(document).extractText();
      document.dispose();

      if (text.trim().isEmpty) {
        throw "Could not extract text from PDF. It might be an image-only PDF.";
      }

      // Ask if it should be global
      final bool? isGlobal = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.knowledgeScopeTitle),
          content: Text(
            l10n.knowledgeScopeBody,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.personalOption),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.globalOption),
            ),
          ],
        ),
      );

      if (isGlobal == null) {
        setState(() => _isUploading = false);
        return;
      }

      // Create a knowledge snippet
      final k = BotKnowledge(
        userId: _currentUser!.id,
        title: l10n.pdfTitlePrefix(result.files.single.name),
        content: text,
        isGlobal: isGlobal,
        createdAt: DateTime.now(),
      );

      await _dbService.addBotKnowledge(k);
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(
          context,
          l10n.pdfProcessedMessage,
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, "Error processing PDF: $e");
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showAddKnowledgeDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    bool isGlobal = false;
    final l10n = AppLocalizations.of(context)!;

    showPremiumGeneralDialog(
      context: context,
      barrierLabel: l10n.addUbKnowledgeBarrierLabel,
      child: StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.newUniversityInfoTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PremiumTextField(
                controller: titleController,
                label: l10n.topicLabel,
                hint: l10n.topicHintExample,
                icon: Icons.school_rounded,
              ),
              const SizedBox(height: 12),
              PremiumTextField(
                controller: contentController,
                label: l10n.detailsLabel,
                hint: l10n.provideUniversityInfoHint,
                icon: Icons.info_outline_rounded,
                maxLines: 5,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: Text(
                  l10n.makeGlobalLabel,
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  l10n.visibleToAllUsersSubtitle,
                  style: const TextStyle(fontSize: 10),
                ),
                value: isGlobal,
                onChanged: (val) => setDialogState(() => isGlobal = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            PremiumSubmitButton(
              label: l10n.saveButton,
              isLoading: false,
              onPressed: () async {
                if (titleController.text.isEmpty ||
                    contentController.text.isEmpty) {
                  return;
                }
                final k = BotKnowledge(
                  userId: _currentUser!.id,
                  title: titleController.text,
                  content: contentController.text,
                  isGlobal: isGlobal,
                  createdAt: DateTime.now(),
                );
                await _dbService.addBotKnowledge(k);
                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _deleteKnowledge(String id) async {
    await _dbService.deleteBotKnowledge(id);
  }
}
