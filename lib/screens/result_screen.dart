// lib/screens/result_screen.dart
// ------------------------------------------
// Result screen with scorecard above errors.

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../models/incorrect_answer_model.dart';
import '../widgets/glow_button_cyan.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';


Future<void> updateMistakeTracker(List<Map<String, dynamic>> responses) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/mistake_tracker.json');
    List<Map<String, dynamic>> tracker = [];

    if (await file.exists()) {
      final content = await file.readAsString();
      tracker = List<Map<String, dynamic>>.from(jsonDecode(content));
    }

    for (final response in responses) {
      final question = response['question'];
      final isCorrect = response['isCorrect'] ?? false;

      final index = tracker.indexWhere((f) => f['question'] == question);
      if (index != -1) {
        if (isCorrect) {
          tracker[index]['correctCount'] = (tracker[index]['correctCount'] ?? 0) + 1;
        } else {
          tracker[index]['mistakeCount'] = (tracker[index]['mistakeCount'] ?? 0) + 1;
        }

        final m = tracker[index];
        if ((m['correctCount'] ?? 0) >= 2 * (m['mistakeCount'] ?? 1)) {
          tracker.removeAt(index); // Clear if mastered
        }
      }
    }

    await file.writeAsString(jsonEncode(tracker));
  } catch (e) {
   // print('Error updating mistake tracker: \$e');
  }
}



class ResultScreen extends StatelessWidget {
  final List<IncorrectAnswer> incorrectAnswers;
  final String mode;
  final List<Map<String, dynamic>> responses;

  const ResultScreen({Key? key, required this.incorrectAnswers, required this.mode, required this.responses}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate score
    final int totalQuestions = ModalRoute.of(context)?.settings.arguments as int;
    final int score = totalQuestions - incorrectAnswers.length;

    // 👇 Mistake tracker update (insert actual mode check)
    if (mode == 'mistake') {
      updateMistakeTracker(responses);
    } totalQuestions - incorrectAnswers.length;




    return Scaffold(
      backgroundColor: Colors.black,

      body:SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scorecard at the top
            Center(
                child: Text(
                  'Your Score: $score / $totalQuestions',
                  style: const TextStyle(
                    color: Colors.cyan,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const SizedBox(height: 20),
            // If no incorrect answers
            if (incorrectAnswers.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '🎉🎉',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'All correct answers!',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      Text(
                        '🎉🎉',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )


            else
            // List of incorrect answers
              Expanded(
                child: ListView.builder(
                  itemCount: incorrectAnswers.length,
                  itemBuilder: (context, index) {
                    final wrongAnswer = incorrectAnswers[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Color(0xFF1C1C1C),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.cyan, // Border color
                          width: 0.8,            // Border thickness
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Html(
                            data: "<b>Q:</b> ${wrongAnswer.question}",
                            style: {
                              "body": Style(
                                fontSize: FontSize(16),
                                color: Colors.white,
                                fontFamily: GoogleFonts.poppins().fontFamily,
                              ),
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your Answer:',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.007), // ~1% of screen height

                          Math.tex(
                            wrongAnswer.userAnswer,
                            textStyle: const TextStyle(
                              color:Color(0xFFFF5454), // light red
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Correct Answer:',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.007), // ~1% of screen height

                          Math.tex(
                            wrongAnswer.correctAnswer,
                            textStyle: const TextStyle(
                              color: Color(0xFFA4FF9D),
                              fontSize: 18,
                            ),
                          ),
                          //.......................Tip Block START................................................
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ........ Tip Block START .........
                              if (wrongAnswer.tip.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                const Text(
                                  'Tip:',
                                  style: TextStyle(color: Colors.white),
                                ),
                                Text(
                                  wrongAnswer.tip,
                                  style: const TextStyle(color: Colors.amber, fontSize: 16),
                                ),
                              ],
                              // ........ Tip Block END ...............................
                            ],
                          ),



                          //.......................Tip Block END............................................
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0x3500BCD4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),side: BorderSide(color: Colors.cyan, width: 1.2),

            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
          child: const Text('Home', style: TextStyle(fontSize: 20,color: Colors.white)),
        ),
      ),
    );
  }
}
