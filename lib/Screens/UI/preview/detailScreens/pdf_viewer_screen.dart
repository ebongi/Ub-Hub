import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:go_study/services/gemini_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:go_study/Screens/Shared/premium_dialog.dart';

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
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final TextEditingController _searchController = TextEditingController();
  PdfTextSearchResult _searchResult = PdfTextSearchResult();

  bool _isSummarizing = false;
  bool _isSearchOpened = false;
  int _currentPage = 1;
  int _totalPages = 0;
  List<PdfBookmark> _bookmarks = [];

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
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (_, controller) => Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                const PremiumDialogHeader(
                  title: "Quick Review",
                  subtitle: "AI-generated document summary",
                  icon: Icons.auto_awesome_rounded,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: controller,
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: double.infinity,
                      child: MarkdownWidget(
                        data: summary,
                        shrinkWrap: true,
                        config: MarkdownConfig.defaultConfig.copy(
                          configs: [
                            PConfig(
                              textStyle: GoogleFonts.outfit(
                                fontSize: 16,
                                height: 1.6,
                                color:
                                    isDark ? Colors.white70 : Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        markdownGenerator: MarkdownGenerator(
                          generators: [latexGenerator],
                          inlineSyntaxList: [LatexSyntax()],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: PremiumSubmitButton(
                    label: "Got it",
                    isLoading: false,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleSearch() {
    setState(() {
      _isSearchOpened = !_isSearchOpened;
      if (!_isSearchOpened) {
        _searchResult.clear();
        _searchController.clear();
      }
    });
  }

  Future<void> _downloadDocument() async {
    final uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch download URL")),
        );
      }
    }
  }

  void _showChatSheet() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PDFChatScreen(pdfUrl: widget.url, geminiService: _geminiService),
      ),
    );
  }

  void _showBookmarksSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const PremiumDialogHeader(
                title: "Table of Contents",
                subtitle: "Navigate through the document",
                icon: Icons.bookmarks_rounded,
              ),
              if (_bookmarks.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(48),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.bookmark_outline_rounded,
                          size: 48,
                          color: isDark ? Colors.white24 : Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No bookmarks found in this document",
                          style: GoogleFonts.outfit(
                            color: isDark ? Colors.white38 : Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    itemCount: _bookmarks.length,
                    itemBuilder: (context, index) {
                      final bookmark = _bookmarks[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.03)
                              : Colors.grey.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          title: Text(
                            bookmark.title,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _pdfViewerController.jumpToBookmark(bookmark);
                          },
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: _isSearchOpened
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: GoogleFonts.outfit(fontSize: 16),
                decoration: InputDecoration(
                  hintText: "Search in document...",
                  hintStyle: GoogleFonts.outfit(color: theme.hintColor),
                  border: InputBorder.none,
                ),
                onSubmitted: (value) async {
                  _searchResult = _pdfViewerController.searchText(value);
                  setState(() {});
                },
              )
            : Text(
                widget.title,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isSearchOpened && _searchResult.hasResult) ...[
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up_rounded),
              onPressed: () => _searchResult.previousInstance(),
            ),
            Center(
              child: Text(
                '${_searchResult.currentInstanceIndex}/${_searchResult.totalInstanceCount}',
                style: GoogleFonts.outfit(fontSize: 12),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              onPressed: () => _searchResult.nextInstance(),
            ),
          ],
          IconButton(
            onPressed: _handleSearch,
            icon: Icon(
              _isSearchOpened ? Icons.close_rounded : Icons.search_rounded,
            ),
            tooltip: "Search",
          ),
          IconButton(
            onPressed: _isSummarizing ? null : _summarizeDocument,
            icon: _isSummarizing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_rounded, color: Colors.blue),
            tooltip: "Quick Review",
          ),
          IconButton(
            onPressed: _showBookmarksSheet,
            icon: const Icon(Icons.bookmarks_rounded),
            tooltip: "Table of Contents",
          ),
          IconButton(
            onPressed: _showChatSheet,
            icon: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.blueAccent,
            ),
            tooltip: "Chat with PDF",
          ),
          IconButton(
            onPressed: _downloadDocument,
            icon: const Icon(Icons.download_rounded),
            tooltip: "Download",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          widget.isLocalFile
              ? SfPdfViewer.file(
                  File(widget.url),
                  controller: _pdfViewerController,
                  canShowScrollHead: true,
                  canShowPaginationDialog: true,
                  onDocumentLoaded: (details) {
                    setState(() {
                      _totalPages = details.document.pages.count;
                      _bookmarks = [];
                      for (
                        int i = 0;
                        i < details.document.bookmarks.count;
                        i++
                      ) {
                        _bookmarks.add(details.document.bookmarks[i]);
                      }
                    });
                  },
                  onPageChanged: (details) {
                    setState(() {
                      _currentPage = details.newPageNumber;
                    });
                  },
                )
              : SfPdfViewer.network(
                  widget.url,
                  controller: _pdfViewerController,
                  canShowScrollHead: true,
                  canShowPaginationDialog: true,
                  onDocumentLoaded: (details) {
                    setState(() {
                      _totalPages = details.document.pages.count;
                      _bookmarks = [];
                      for (
                        int i = 0;
                        i < details.document.bookmarks.count;
                        i++
                      ) {
                        _bookmarks.add(details.document.bookmarks[i]);
                      }
                    });
                  },
                  onPageChanged: (details) {
                    setState(() {
                      _currentPage = details.newPageNumber;
                    });
                  },
                ),

          // Floating Status Bar
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.colorScheme.surfaceContainerHigh
                        : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: _currentPage > 1
                            ? () => _pdfViewerController.previousPage()
                            : null,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "$_currentPage / $_totalPages",
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        onPressed: _currentPage < _totalPages
                            ? () => _pdfViewerController.nextPage()
                            : null,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PDFChatScreen extends StatefulWidget {
  final String pdfUrl;
  final GeminiService geminiService;

  const PDFChatScreen({
    super.key,
    required this.pdfUrl,
    required this.geminiService,
  });

  @override
  State<PDFChatScreen> createState() => _PDFChatScreenState();
}

class _PDFChatScreenState extends State<PDFChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isSending = false;
  Uint8List? _pdfBytes;

  @override
  void initState() {
    super.initState();
    _loadPdfBytes();
  }

  Future<void> _loadPdfBytes() async {
    try {
      final response = await http.get(Uri.parse(widget.pdfUrl));
      if (response.statusCode == 200) {
        _pdfBytes = response.bodyBytes;
      }
    } catch (e) {
      debugPrint("Error loading PDF for chat: $e");
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending || _pdfBytes == null) return;

    setState(() {
      _messages.add({"role": "user", "content": text});
      _isSending = true;
    });
    _messageController.clear();

    try {
      final response = await widget.geminiService.sendMessage(
        "Context: The user is asking about the attached PDF document. \n\nUser Question: $text",
        attachments: [DataPart('application/pdf', _pdfBytes!)],
      );

      if (mounted) {
        setState(() {
          _messages.add({"role": "ai", "content": response});
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            "role": "ai",
            "content": "Error: I couldn't process that question. ($e)",
          });
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Chat with PDF",
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["role"] == "user";
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment:
                          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isUser
                                ? theme.colorScheme.primary
                                : (isDark ? Colors.white10 : Colors.grey[100]),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: Radius.circular(isUser ? 20 : 0),
                              bottomRight: Radius.circular(isUser ? 0 : 20),
                            ),
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          child: MarkdownWidget(
                            data: msg["content"]!,
                            shrinkWrap: true,
                            config: MarkdownConfig.defaultConfig.copy(
                              configs: [
                                PConfig(
                                  textStyle: GoogleFonts.outfit(
                                    color: isUser
                                        ? Colors.white
                                        : theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ],
                            ),
                            markdownGenerator: MarkdownGenerator(
                              generators: [latexGenerator],
                              inlineSyntaxList: [LatexSyntax()],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            DateFormat('HH:mm').format(DateTime.now()), // Assuming current time if not in model
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: isDark ? Colors.white30 : Colors.grey[400],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isSending)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: LinearProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: GoogleFonts.outfit(),
                    decoration: InputDecoration(
                      hintText: "Ask anything about this document...",
                      hintStyle: GoogleFonts.outfit(fontSize: 14),
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A LaTeX generator for [MarkdownWidget]
final latexGenerator = SpanNodeGeneratorWithTag(
  tag: 'latex',
  generator: (e, config, visitor) =>
      LatexNode(e.attributes['content'] ?? '', config),
);

class LatexNode extends SpanNode {
  final String content;
  final MarkdownConfig config;

  LatexNode(this.content, this.config);

  @override
  InlineSpan build() {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Material(
        color: Colors.transparent,
        child: Math.tex(
          content,
          mathStyle: MathStyle.text,
          textStyle: config.p.textStyle,
          onErrorFallback: (err) => Text(
            content,
            style: config.p.textStyle.copyWith(color: Colors.red),
          ),
        ),
      ),
    );
  }
}

class LatexSyntax extends md.InlineSyntax {
  LatexSyntax() : super(r'(\$\$?)([\s\S]+?)\1');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final content = match.group(2) ?? '';
    parser.addNode(
      md.Element.withTag('latex')..attributes['content'] = content,
    );
    return true;
  }
}
