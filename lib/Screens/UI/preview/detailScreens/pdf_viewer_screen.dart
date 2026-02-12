import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PDFViewerScreen extends StatelessWidget {
  final String url;
  final String title;

  const PDFViewerScreen({super.key, required this.url, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.blue.shade200,
      ),
      body: SfPdfViewer.network(
        url,
        canShowScrollHead: true,
        canShowPaginationDialog: true,
      ),
    );
  }
}
