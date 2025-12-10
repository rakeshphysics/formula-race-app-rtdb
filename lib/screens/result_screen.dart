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
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_svg/flutter_svg.dart';


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



class ResultScreen extends StatefulWidget {
  final List<IncorrectAnswer> incorrectAnswers;
  final String mode;
  final List<Map<String, dynamic>> responses;


  const ResultScreen({Key? key, required this.incorrectAnswers, required this.mode, required this.responses}) : super(key: key);
  @override
  State<ResultScreen> createState() => _ResultScreenState();
}



class _ResultScreenState extends State<ResultScreen> {


  int score = 0;
  int totalQuestions = 0;
  List<Color> _confettiColors = [];
  int _particleCount = 0;
  double _emissionFrequency = 0.05;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late ConfettiController _confetti10Controller;
  late ConfettiController _confetti8Controller;
  late ConfettiController _confetti6Controller;
  late ConfettiController _confetti4Controller;
  late ConfettiController _confetti0Controller;

  @override
  void initState() {
    super.initState();
    _confetti10Controller = ConfettiController(duration: const Duration(seconds: 2));
    _confetti8Controller = ConfettiController(duration: const Duration(seconds: 2));
    _confetti6Controller = ConfettiController(duration: const Duration(seconds: 2));
    _confetti4Controller = ConfettiController(duration: const Duration(seconds: 2));
    _confetti0Controller = ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _confetti10Controller.dispose();
    _confetti8Controller.dispose();
    _confetti6Controller.dispose();
    _confetti4Controller.dispose();
    _confetti0Controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {

    final screenWidth = MediaQuery.of(context).size.width;
    // Calculate score
    final int totalQuestions = ModalRoute.of(context)?.settings.arguments as int;
    final int score = totalQuestions - widget.incorrectAnswers.length;

    if (score == 10) _confetti10Controller.play();
    else if (score >= 8) _confetti8Controller.play();
    else if (score >= 6) _confetti6Controller.play();
    else if (score >= 4) _confetti4Controller.play();
    else if (score >= 0) _confetti0Controller.play();

    // 👇 Mistake tracker update (insert actual mode check)
    if (widget.mode == 'mistake') {
      updateMistakeTracker(widget.responses);
    }



    return WillPopScope( // ADD THIS WILLPOPSCOPE
      onWillPop: () async {
        // This will pop all routes until the first one (usually your Home Screen)
        Navigator.popUntil(context, (route) => route.isFirst);
        return false; // Prevent the default back button behavior
      },
      child: Scaffold(
        backgroundColor: Colors.black,


    body: Stack(
        alignment: Alignment.topCenter,
        children:[



        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Scorecard at the top
                Center(
                  child: Text(
                    'Your Score: $score / $totalQuestions',
                    style: GoogleFonts.hedvigLettersSerif(
                      fontSize: screenWidth*0.057, // Responsive font size
                      color: const Color(0xD900FFFF),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),

                SizedBox(height: screenWidth * 0.03),
                // If no incorrect answers
                if (widget.incorrectAnswers.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '🎉 🎉',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: screenWidth*0.06,
                              fontWeight: FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'All Correct Answers!',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: screenWidth*0.06,
                              fontWeight: FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 20),
                          Text(
                            '🎉 🎉',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: screenWidth*0.06,
                              fontWeight: FontWeight.normal,
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
                      itemCount: widget.incorrectAnswers.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final wrongAnswer = widget.incorrectAnswers[index];
                        return Container(
                          margin:  EdgeInsets.symmetric(vertical:screenWidth * 0.02),
                          padding: EdgeInsets.all(screenWidth * 0.02),
                          decoration: BoxDecoration(
                            color: Color(0xFF000000),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xD900FFFF), // Border color
                              width: 0.8,            // Border thickness
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              if (wrongAnswer.imagePath.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.symmetric(vertical: 0),
                                  child: Center(
                                    child: SizedBox(
                                      width: screenWidth * 0.6,
                                      height: (screenWidth * 0.6) / 1.5,
                                      child: Image.asset(
                                        wrongAnswer.imagePath,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Text(
                                            'Image not found',
                                            style: TextStyle(color: Colors.redAccent),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),

                              // if (wrongAnswer.imagePath.isNotEmpty)
                              //   Container(
                              //     margin: const EdgeInsets.symmetric(vertical: 0),
                              //     child: Center(
                              //       child: SizedBox(
                              //         width: screenWidth * 0.6,
                              //         height: (screenWidth * 0.6) / 1.5, // Maintain the same aspect ratio
                              //         child: SvgPicture.asset(
                              //           wrongAnswer.imagePath, // This path now points to a .svg file
                              //           fit: BoxFit.contain,
                              //         ),
                              //       ),
                              //     ),
                              //   ),


                              Html(
                                data: "<b>Q:</b> ${wrongAnswer.question}",
                                style: {
                                  "body": Style(
                                    fontSize: FontSize(screenWidth * 0.037),
                                    color: Color(0xD9FFFFFF),
                                    fontFamily: GoogleFonts.poppins().fontFamily,
                                  ),
                                },
                              ),




                              // SizedBox(height: screenWidth*0.02),
                              Text(
                                'Your Answer:',
                                style: GoogleFonts.poppins(
                                  color: Color(0xD9FFFFFF),
                                  fontSize: screenWidth*0.037,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              SizedBox(height: screenWidth*0.01), // ~1% of screen height

                              Math.tex(
                                wrongAnswer.userAnswer,
                                textStyle: TextStyle(
                                  color:Color(0xD9FF5454), // light red
                                  fontSize: screenWidth * 0.043,
                                ),
                              ),
                              SizedBox(height: screenWidth*0.03),
                              Text(
                                'Correct Answer:',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: screenWidth*0.037,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              SizedBox(height: screenWidth*0.01), // ~1% of screen height

                              Math.tex(
                                wrongAnswer.correctAnswer,
                                textStyle:  TextStyle(
                                  color: Color(0xD9A4FF9D),
                                  fontSize: screenWidth * 0.043,
                                ),
                              ),
                              //SizedBox(height: screenWidth*0.02),
                              //.......................Tip Block START................................................
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ........ Tip Block START .........
                                  if (wrongAnswer.tip.isNotEmpty) ...[
                                    SizedBox(height: screenWidth*0.05),
                                    Text(
                                      'Tip :',
                                      style: GoogleFonts.poppins(
                                        color: Color(0xFFF8A46F),
                                        fontSize:screenWidth * 0.045,
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FontStyle.italic,
                                        //decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    SizedBox(height: screenWidth*0.01),
                                    Text(
                                      wrongAnswer.tip,
                                      style: GoogleFonts.poppins(
                                        color: Color(0xFFF8A46F),
                                        fontSize: screenWidth * 0.039,
                                        fontWeight: FontWeight.normal,
                                        fontStyle: FontStyle.italic,
                                      ),
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

          ConfettiWidget(
            confettiController: _confetti10Controller,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 40,// A default value, will be overridden by the controller
            gravity: 0.3,
            emissionFrequency: 0.05,
            colors: [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple, Colors.yellow, Colors.red],
            ),

          ConfettiWidget(
              confettiController: _confetti8Controller,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 30,// A default value, will be overridden by the controller
              gravity: 0.3,
              emissionFrequency: 0.04,
              colors: [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
          ),

          ConfettiWidget(
              confettiController: _confetti6Controller,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 20,// A default value, will be overridden by the controller
              gravity: 0.3,
              emissionFrequency: 0.04,
              colors: [Colors.green, Colors.blue, Colors.pink],
          ),

          ConfettiWidget(
              confettiController: _confetti4Controller,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 10,// A default value, will be overridden by the controller
              gravity: 0.3,
              emissionFrequency: 0.04,
              colors: [Colors.green, Colors.blue],
          ),

          ConfettiWidget(
              confettiController: _confetti0Controller,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 10,// A default value, will be overridden by the controller
              gravity: 0.3,
              emissionFrequency: 0.03,
              colors: [Colors.white],
          ),



        ],),


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
            child: Text('Home', style: TextStyle(fontSize: screenWidth*0.046,color: Color(
                0xD9FFFFFF))),
          ),
        ),
      ),
    );
  }
}
