import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neo/Screens/Shared/constanst.dart';
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
                    Text("Loading..."),
                    SizedBox(height: 10),
                    CircularProgressIndicator(color: Colors.blue,),
                  ],
                ),
              );
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!['results'] == null) {
              return const Center(child: Text('No questions found.'));
            }
      
            final results = snapshot.data!['results'] as List;
      
            return ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final question = results[index] as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}',style: GoogleFonts.poppins(),)),
                    title: Text(
                      _unescape.convert(question['question'] as String),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Correct Answer: ${_unescape.convert(question['correct_answer'] as String)}',
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
          label: const Text("Reload"),
          icon: Icon(Icons.refresh, color: Colors.blue.shade900),
        ),
      ),
    );
  }
}
