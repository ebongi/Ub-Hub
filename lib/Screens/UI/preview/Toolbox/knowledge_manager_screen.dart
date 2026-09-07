import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:io';

import 'package:go_study/Screens/Shared/constanst.dart';
import 'package:go_study/services/profile.dart' show UserRole;
import 'package:go_study/services/database.dart';
import 'package:go_study/services/knowledge_bot_service.dart';
import 'package:go_study/core/error_handler.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';

/// Admin-only editor for the single shared knowledge document every user's
/// Support Bot chat reads from (see DatabaseService.getSharedBotKnowledge/
/// updateSharedBotKnowledge). Reachable only via the settings-gear icon on
/// KnowledgeBotChatScreen, which is itself admin-gated — but this screen
/// still checks the role itself and falls back to read-only, since RLS on
/// the storage bucket is the real backstop and a stray future nav path
/// shouldn't show an editable text box that silently fails to save.
class KnowledgeManagerScreen extends StatefulWidget {
  const KnowledgeManagerScreen({super.key});

  @override
  State<KnowledgeManagerScreen> createState() => _KnowledgeManagerScreenState();
}

class _KnowledgeManagerScreenState extends State<KnowledgeManagerScreen> {
  late final DatabaseService _dbService;
  final _currentUser = Supabase.instance.client.auth.currentUser;
  final _contentController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isExtracting = false;

  @override
  void initState() {
    super.initState();
    _dbService = DatabaseService(uid: _currentUser?.id);
    _loadKnowledge();
    // Rebuilds just to refresh the character-count/truncation warning below
    // the field as the admin types or pastes in new content.
    _contentController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _contentController.removeListener(_onContentChanged);
    _contentController.dispose();
    super.dispose();
  }

  void _onContentChanged() => setState(() {});

  Future<void> _loadKnowledge() async {
    try {
      final text = await _dbService.getSharedBotKnowledge();
      if (mounted) {
        setState(() {
          _contentController.text = text;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorHandler.showErrorSnackBar(context, "Couldn't load the knowledge base: $e");
      }
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await _dbService.updateSharedBotKnowledge(_contentController.text);
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(context, "Knowledge base updated for everyone.");
      }
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, "Couldn't save: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _extractFromPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null) return;

    setState(() => _isExtracting = true);
    try {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();

      final document = PdfDocument(inputBytes: bytes);
      final String text;
      try {
        text = PdfTextExtractor(document).extractText();
      } finally {
        document.dispose();
      }

      if (text.trim().isEmpty) {
        throw "Could not extract text from PDF. It might be an image-only PDF.";
      }
      setState(() => _contentController.text = text);
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(context, "Extracted — review below, then Save.");
      }
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, "Error processing PDF: $e");
    } finally {
      if (mounted) setState(() => _isExtracting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isAdmin = context.watch<UserModel>().role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ubKnowledgeBaseTitle, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          if (isAdmin)
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              onPressed: _isSaving || _isLoading ? null : _save,
              tooltip: 'Save',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAdmin
                        ? "This is the one shared knowledge base every student's Support Bot chat reads from. Edit it directly, or extract it from a PDF."
                        : "Only administrators can edit the shared knowledge base.",
                    style: GoogleFonts.outfit(fontSize: 13, color: theme.hintColor),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isExtracting ? null : _extractFromPdf,
                      icon: _isExtracting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.picture_as_pdf_rounded),
                      label: Text(_isExtracting ? 'Extracting...' : 'Extract from PDF (replaces text below)'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      readOnly: !isAdmin,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: GoogleFonts.outfit(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Paste or type the knowledge base content here...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final length = _contentController.text.length;
                        final overLimit = length > KnowledgeBotService.maxKnowledgeChars;
                        return Text(
                          overLimit
                              ? '$length characters — only the first ${KnowledgeBotService.maxKnowledgeChars} will be used per question; trim it so nothing important gets cut off.'
                              : '$length / ${KnowledgeBotService.maxKnowledgeChars} characters used per question.',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: overLimit ? theme.colorScheme.error : theme.hintColor,
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
