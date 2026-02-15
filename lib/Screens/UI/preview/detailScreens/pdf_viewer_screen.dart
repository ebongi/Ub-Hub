import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;
import 'package:neo/services/gemini_service.dart';

class PDFViewerScreen extends StatefulWidget {
  final String url;
  final String title;
  final bool isLocalFile;

  const PDFViewerScreen({
    super.key,
    required this.url,
    required this.title,
    this.isLocalFile = false,
  });

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  final GeminiService _geminiService = GeminiService();
  bool _isSummarizing = false;

  Future<void> _summarizeDocument() async {
    setState(() => _isSummarizing = true);

    try {
      // 1. Fetch PDF bytes
      final response = await http.get(Uri.parse(widget.url));
      if (response.statusCode == 200) {
        // 2. Generate summary
        final summary = await _geminiService.summarizePdf(response.bodyBytes);

        if (mounted) {
          _showSummarySheet(summary);
        }
      } else {
        throw Exception(
          "Failed to download PDF (Status: ${response.statusCode})",
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error summarizing document: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSummarizing = false);
      }
    }
  }

  void _showSummarySheet(String summary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Quick Review",
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: Markdown(
                  controller: controller,
                  data: summary,
                  styleSheet: MarkdownStyleSheet(
                    p: GoogleFonts.outfit(fontSize: 16, height: 1.5),
                    h1: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    h2: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.blue.shade200,
        actions: [
          IconButton(
            onPressed: _isSummarizing ? null : _summarizeDocument,
            icon: _isSummarizing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_rounded),
            tooltip: "Quick Review",
          ),
        ],
      ),
      body: widget.isLocalFile
          ? SfPdfViewer.file(
              File(widget.url),
              canShowScrollHead: true,
              canShowPaginationDialog: true,
            )
          : SfPdfViewer.network(
              widget.url,
              canShowScrollHead: true,
              canShowPaginationDialog: true,
            ),
    );
  }
}
