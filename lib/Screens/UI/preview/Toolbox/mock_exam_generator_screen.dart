import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:neo/services/gemini_service.dart';
import 'quiz_view_screen.dart';

class MockExamGeneratorScreen extends StatefulWidget {
  const MockExamGeneratorScreen({super.key});

  @override
  State<MockExamGeneratorScreen> createState() =>
      _MockExamGeneratorScreenState();
}

class _MockExamGeneratorScreenState extends State<MockExamGeneratorScreen> {
  final TextEditingController _textController = TextEditingController();
  final GeminiService _geminiService = GeminiService();
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();

  bool _isLoading = false;

  @override
  void dispose() {
    _textRecognizer.close();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _scanNotes() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      _processImage(File(image.path));
    }
  }

  Future<void> _processImage(File imageFile) async {
    setState(() => _isLoading = true);
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      setState(() {
        _textController.text += "\n${recognizedText.text}";
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error recognizing text: $e")));
      }
    }
  }

  Future<void> _generateQuiz() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide some notes first!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _geminiService.generateQuiz(_textController.text);
      // Gemini might wrap the JSON in markdown code blocks, strip them if present
      String cleanJson = response
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final Map<String, dynamic> quizData = jsonDecode(cleanJson);

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => QuizViewScreen(quizData: quizData)),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to generate quiz. Try again! ($e)")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Mock Exam Generator",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Input Study Material",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Paste your notes below or use the camera to scan physical pages.",
                  style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: "Enter text or scan notes...",
                        border: InputBorder.none,
                      ),
                      style: GoogleFonts.outfit(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _scanNotes,
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: const Text("SCAN NOTES"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _generateQuiz,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text("GENERATE QUIZ"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text(
                      "Gemini is preparing your exam...",
                      style: GoogleFonts.outfit(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
