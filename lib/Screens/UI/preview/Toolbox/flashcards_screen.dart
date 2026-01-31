import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _ResumeBuilderScreenState();
}

class _ResumeBuilderScreenState extends State<FlashcardsScreen> {
  int _currentStep = 0;
  bool _isGenerating = false;

  // Form Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _linkedinController = TextEditingController();

  final _universityController = TextEditingController();
  final _degreeController = TextEditingController();
  final _gradYearController = TextEditingController();
  final _gpaController = TextEditingController();

  final _skillsController = TextEditingController(); // Comma separated

  final List<ExperienceItem> _experience = [];

  final _roleController = TextEditingController();
  final _companyController = TextEditingController();
  final _descController = TextEditingController();

  void _addExperience() {
    if (_roleController.text.isNotEmpty && _companyController.text.isNotEmpty) {
      setState(() {
        _experience.add(
          ExperienceItem(
            role: _roleController.text,
            company: _companyController.text,
            description: _descController.text,
          ),
        );
        _roleController.clear();
        _companyController.clear();
        _descController.clear();
      });
    }
  }

  Future<void> _generatePDF() async {
    setState(() => _isGenerating = true);
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _nameController.text.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        "${_emailController.text} | ${_phoneController.text}",
                      ),
                      if (_linkedinController.text.isNotEmpty)
                        pw.Text(
                          _linkedinController.text,
                          style: const pw.TextStyle(color: PdfColors.blue),
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                _buildPdfSection("EDUCATION", [
                  pw.Text(
                    _universityController.text,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    "${_degreeController.text} (${_gradYearController.text})",
                  ),
                  if (_gpaController.text.isNotEmpty)
                    pw.Text("GPA: ${_gpaController.text}"),
                ]),
                pw.SizedBox(height: 15),
                _buildPdfSection("SKILLS", [pw.Text(_skillsController.text)]),
                pw.SizedBox(height: 15),
                if (_experience.isNotEmpty)
                  _buildPdfSection(
                    "EXPERIENCE / PROJECTS",
                    _experience
                        .map(
                          (e) => pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                "${e.role} at ${e.company}",
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Text(e.description),
                              pw.SizedBox(height: 8),
                            ],
                          ),
                        )
                        .toList(),
                  ),
              ],
            );
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File("${output.path}/resume.pdf");
      await file.writeAsBytes(await pdf.save());

      setState(() => _isGenerating = false);

      if (mounted) {
        final box = context.findRenderObject() as RenderBox?;
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Here is my resume!',
          sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
        );
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  pw.Widget _buildPdfSection(String title, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.Divider(color: PdfColors.grey400),
        ...children,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = theme.scaffoldBackgroundColor;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "Resume Builder",
          style: GoogleFonts.outfit(color: theme.textTheme.titleLarge?.color),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            primary: Colors.blue,
            secondary: Colors.blue,
            surface: theme.cardColor,
            onSurface: theme.textTheme.bodyLarge?.color,
          ),
          canvasColor: bgColor,
        ),
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 3) {
              setState(() => _currentStep += 1);
            } else {
              _generatePDF();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep -= 1);
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_currentStep == 3 ? "Generate PDF" : "Next"),
                  ),
                  const SizedBox(width: 12),
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: Text(
                        "Back",
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(
                            0.7,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
          steps: [
            Step(
              title: Text(
                "Personal Info",
                style: GoogleFonts.outfit(
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              content: Column(
                children: [
                  _buildInput(context, _nameController, "Full Name"),
                  _buildInput(context, _emailController, "Email"),
                  _buildInput(context, _phoneController, "Phone Number"),
                  _buildInput(
                    context,
                    _linkedinController,
                    "LinkedIn / Portfolio URL",
                  ),
                ],
              ),
              isActive: _currentStep >= 0,
            ),
            Step(
              title: Text(
                "Education",
                style: GoogleFonts.outfit(
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              content: Column(
                children: [
                  _buildInput(
                    context,
                    _universityController,
                    "University / College",
                  ),
                  _buildInput(context, _degreeController, "Degree / Major"),
                  _buildInput(context, _gradYearController, "Graduation Year"),
                  _buildInput(context, _gpaController, "GPA (Optional)"),
                ],
              ),
              isActive: _currentStep >= 1,
            ),
            Step(
              title: Text(
                "Skills",
                style: GoogleFonts.outfit(
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              content: Column(
                children: [
                  _buildInput(
                    context,
                    _skillsController,
                    "Skills (Comma separated)",
                    maxLines: 3,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "e.g. Flutter, Dart, Python, Team Leadership",
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              isActive: _currentStep >= 2,
            ),
            Step(
              title: Text(
                "Experience",
                style: GoogleFonts.outfit(
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              content: Column(
                children: [
                  if (_experience.isNotEmpty)
                    ..._experience.map(
                      (e) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.black12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          title: Text(
                            e.role,
                            style: TextStyle(
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          subtitle: Text(
                            e.company,
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.7),
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            onPressed: () =>
                                setState(() => _experience.remove(e)),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    "Add Experience / Project",
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(
                        0.7,
                      ),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildInput(context, _roleController, "Role / Title"),
                  _buildInput(
                    context,
                    _companyController,
                    "Company / Project Name",
                  ),
                  _buildInput(
                    context,
                    _descController,
                    "Description",
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _addExperience,
                    icon: const Icon(Icons.add),
                    label: const Text("Add Entry"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                ],
              ),
              isActive: _currentStep >= 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(
    BuildContext context,
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue),
          ),
          filled: true,
          fillColor: isDark ? Colors.white10 : Colors.black12.withOpacity(0.05),
        ),
      ),
    );
  }
}

class ExperienceItem {
  final String role;
  final String company;
  final String description;

  ExperienceItem({
    required this.role,
    required this.company,
    required this.description,
  });
}
