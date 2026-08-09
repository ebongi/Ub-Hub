import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_study/core/error_handler.dart';
import 'package:go_study/l10n/generated/app_localizations.dart';
import 'package:go_study/Screens/Shared/constanst.dart';

import 'package:html_unescape/html_unescape.dart';

class Questions extends StatefulWidget {
  const Questions({super.key});

  @override
  State<Questions> createState() => _QuestionsState();
}

class _QuestionsState extends State<Questions> {
  Future<Map<String, dynamic>>? _questionsFuture;
  final HtmlUnescape _unescape = HtmlUnescape();

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  void _loadQuestions() {
    setState(() {
      _questionsFuture = getquestions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Scaffold(
        body: FutureBuilder<Map<String, dynamic>>(
          future: _questionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(l10n.loadingLabel),
                    SizedBox(height: 10),
                    CircularProgressIndicator(color: Colors.blue),
                  ],
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Colors.redAccent, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        ErrorHandler.getFriendlyMessage(snapshot.error),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadQuestions,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(l10n.tryAgainButton),
                      ),
                    ],
                  ),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!['results'] == null) {

              return Center(child: Text(l10n.noQuestionsFound));
            }

            final results = snapshot.data!['results'] as List;

            return ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final question = results[index] as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text('${index + 1}', style: GoogleFonts.poppins()),
                    ),
                    title: Text(
                      _unescape.convert(question['question'] as String),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      l10n.correctAnswerLabel(_unescape.convert(question['correct_answer'] as String)),
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: theme.primaryColor,
          onPressed: _loadQuestions,
          label: Text(l10n.reloadButton),
          icon: Icon(Icons.refresh, color: Colors.blue.shade900),
        ),
      ),
    );
  }
}
