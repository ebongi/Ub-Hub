import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class Portalscreen extends StatefulWidget {
  const Portalscreen({super.key});

  @override
  State<Portalscreen> createState() => _PortalscreenState();
}

class _PortalscreenState extends State<Portalscreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0;
  String _currentTitle = "Student Portal";

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _progress = progress / 100;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) async {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            final title = await _controller.getTitle();
            if (mounted && title != null && title.isNotEmpty) {
              setState(() {
                _currentTitle = title;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Web resource error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url.toLowerCase();
            
            // Robust check for downloadable files and special protocols
            final isDownloadable = url.contains('.pdf') ||
                url.contains('.doc') ||
                url.contains('.docx') ||
                url.contains('.xls') ||
                url.contains('.xlsx') ||
                url.contains('.ppt') ||
                url.contains('.pptx') ||
                url.contains('.zip') ||
                url.contains('.rar') ||
                url.contains('.7z') ||
                url.contains('download') ||
                url.contains('attachment') ||
                url.contains('export') ||
                url.contains('getfile') ||
                url.contains('blob:');

            if (url.startsWith('mailto:') ||
                url.startsWith('tel:') ||
                url.startsWith('whatsapp:') ||
                url.startsWith('intent:') ||
                isDownloadable) {
              _launchExternalUrl(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://ubstudent.online/'));

    // Note: In some versions of webview_flutter_android, setDownloadListener might not be available
    // or requires a different platform initialization. We rely on onNavigationRequest
    // for catching download URLs, which covers most portal scenarios.

    // To handle downloads in the modern webview_flutter, we utilize the NavigationDelegate.
    // However, if the portal triggers a download that doesn't trigger onNavigationRequest,
    // we can use the specific Android/iOS platform controllers if necessary.
  }

  Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () async {
            if (await _controller.canGoBack()) {
              await _controller.goBack();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentTitle,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (_isLoading)
              Text(
                "Syncing Academic Data...",
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh, size: 20),
            onPressed: () => _controller.reload(),
          ),
          IconButton(
            icon: const Icon(Iconsax.more, size: 20),
            onPressed: () => _showMenu(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: _isLoading
              ? LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.transparent,
                  color: theme.colorScheme.primary,
                  minHeight: 2,
                )
              : const SizedBox(height: 2),
        ),
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          if (await _controller.canGoBack()) {
            await _controller.goBack();
          } else {
            if (mounted) Navigator.pop(context);
          }
        },
        child: WebViewWidget(controller: _controller),
      ),
      floatingActionButton: !_isLoading
          ? FloatingActionButton(
              mini: true,
              backgroundColor: theme.colorScheme.primary,
              elevation: 4,
              onPressed: () async {
                final url = await _controller.currentUrl();
                if (url != null) {
                  _launchExternalUrl(url);
                }
              },
              child: const Icon(Iconsax.global, size: 18, color: Colors.white),
            )
          : null,
    );
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _buildMenuItem(
                icon: Iconsax.refresh,
                label: "Reload Page",
                onTap: () => _controller.reload(),
              ),
              _buildMenuItem(
                icon: Iconsax.copy,
                label: "Copy Portal Link",
                onTap: () async {
                  final url = await _controller.currentUrl();
                  if (url != null) {
                    await Clipboard.setData(ClipboardData(text: url));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Link copied to clipboard")),
                      );
                    }
                  }
                },
              ),
              _buildMenuItem(
                icon: Iconsax.global,
                label: "Open in External Browser",
                onTap: () async {
                  final url = await _controller.currentUrl();
                  if (url != null) _launchExternalUrl(url);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(
        label,
        style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
