import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/online_incorrect_answer_model.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:formularacing/widgets/rive_viewer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnlineResultScreen extends StatefulWidget {
  final Map<dynamic, dynamic> scores;
  final String playerId;
  final bool isPlayer1;
  final bool opponentLeftGame;
  final bool youLeftGame;
  final int totalQuestions;
  final List<OnlineIncorrectAnswer> onlineIncorrectAnswers;
  final String subject;

  const OnlineResultScreen({
    Key? key,
    required this.scores,
    required this.playerId,
    required this.isPlayer1,
    this.opponentLeftGame = false,
    this.youLeftGame = false,
    required this.totalQuestions,
    required this.onlineIncorrectAnswers,
    required this.subject,
  }) : super(key: key);

  @override
  State<OnlineResultScreen> createState() => _OnlineResultScreenState();
}

class _OnlineResultScreenState extends State<OnlineResultScreen> {
  late ConfettiController _confettiController;
  late ConfettiController _confettiDrawController;

  Color _getSubjectColor() {
    // Assuming you have 'widget.subject' available. 
    // If 'subject' is passed as a string to this screen, use that.
    if (widget.subject.contains('Chem')) {
      return Colors.green.shade700.withOpacity(0.7);
    } else if (widget.subject.contains('Math')) {
      return Colors.blue.shade700.withOpacity(0.7);
    }
    // Default to Physics (Cyan)
    return Colors.cyan.shade700.withOpacity(0.7);
  }
  
  
  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _confettiDrawController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _confettiDrawController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final themeColor = _getSubjectColor();

    int myScore;
    int opponentScore;

    if (widget.isPlayer1) {
      myScore = widget.scores['player1'] ?? 0;
      opponentScore = widget.scores['player2'] ?? 0;
    } else {
      myScore = widget.scores['player2'] ?? 0;
      opponentScore = widget.scores['player1'] ?? 0;
    }

    String resultMessage;
    Color resultMessageColor;
    
    

    if (widget.youLeftGame) { // Check this first
      resultMessage = 'You left the Game\nYou Lose \u{1F622}';
      resultMessageColor = Colors.redAccent;
    } else if (widget.opponentLeftGame) { // If opponent left the game
      resultMessage = 'Opponent left the Game\nYou Win 🥳'; // Specific message
      resultMessageColor = themeColor; // Winner color
      myScore = widget.totalQuestions; // Ensure score is displayed as totalQuestions for the win
      opponentScore = 0; // Ensure opponent's score is 0
    } else if (myScore > opponentScore) {
      resultMessage = '🥳 You Win 🥳';
      resultMessageColor = themeColor;
    } else if (myScore < opponentScore) {
      resultMessage = '🤝 Opponent Wins 🤝';
      resultMessageColor = themeColor;
    } else {
      resultMessage = '🤝  It\'s a Draw  🤝';
      resultMessageColor = themeColor;
    }


    if (resultMessage.contains('You Win')) {
      _confettiController.play();
    } else if (resultMessage.contains("Draw")) {
      _confettiDrawController.play();
    }


    return PopScope(
        canPop: false, // ⛔️ Prevents default back action
        onPopInvoked: (didPop) async {
      if (didPop) return;

      // --- A. Calculate Result Status for the Panda ---
      String resultStatus = 'loss';
      if (widget.youLeftGame) {
        resultStatus = 'loss';
      } else if (widget.opponentLeftGame) {
        resultStatus = 'win';
      } else {
        if (myScore > opponentScore) {
          resultStatus = 'win';
        } else if (myScore < opponentScore) {
          resultStatus = 'loss';
        } else {
          resultStatus = 'draw';
        }
      }

      // --- B. Save to SharedPreferences (CRITICAL for Panda) ---
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_battle_result', resultStatus);

      // --- C. Force Navigate to Home ---
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    },
    child: Scaffold(
      backgroundColor: Colors.black,
          appBar: AppBar(
          backgroundColor: Colors.black,
          toolbarHeight: 10,
          title: Text('', style: GoogleFonts.poppins(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          automaticallyImplyLeading: false, // Hide back button
           ),

      body: Stack(
        alignment: Alignment.topCenter,
      children:[
      Padding(
        padding: EdgeInsets.all(screenWidth * 0.04), // Responsive padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            //Spacer(), // Pushes content to center/bottom
            SizedBox(height: screenHeight * 0.002),
            // Game Result Message (You Win/Lose/Draw)
            Text(
              resultMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.05, // Responsive font size
                fontWeight: FontWeight.w500,
                color: resultMessageColor,
                letterSpacing: 2.0,
              ),
            ),
            SizedBox(height: screenHeight * 0.02), // Responsive spacing

            // Score Display Container
            Container(
              width: screenWidth *1, // Responsive width
              padding: EdgeInsets.symmetric(
                vertical: screenHeight * 0.01,
                horizontal: screenWidth * 0.08,
              ),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: themeColor, width: 1.8),// Responsive border radius
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Your Score
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'MY SCORE :',
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.045, // Responsive font size
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        '$myScore',
                        style: GoogleFonts.hedvigLettersSerif(
                          fontSize: screenWidth * 0.06, // Responsive font size
                          fontWeight: FontWeight.bold,
                          color: Colors.greenAccent,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.001), // Responsive spacing
                  // Opponent Score
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'OPPONENT SCORE :',
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.045, // Responsive font size
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        '$opponentScore',
                        style: GoogleFonts.hedvigLettersSerif(
                          fontSize: screenWidth * 0.06, // Responsive font size
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.02), // Responsive spacing before detailed results

            // Detailed Question Results (Mistakes and Opponent Wins)
            if (widget.onlineIncorrectAnswers.isNotEmpty) // Only show if there are questions to display
              Expanded(
                child: ListView.builder(
                  itemCount: widget.onlineIncorrectAnswers.length,
                  itemBuilder: (context, index) {
                    final qa = widget.onlineIncorrectAnswers[index]; // qa for question/answer
                    String userStatus = '';
                    Color userStatusColor = Colors.white;

                    // Determine user's status message and color
                    switch (qa.scenario) {
                      case 'you_answered_first_correctly':
                        userStatus = 'You answered First !';
                        userStatusColor = Colors.greenAccent;
                        break;
                      case 'opponent_answered_first_correctly':
                        userStatus = 'Opponent answered First';
                        userStatusColor = Colors.redAccent;
                        break;
                      case 'both_wrong_or_skipped':
                        userStatus = 'Both were incorrect or skipped.';
                        userStatusColor = themeColor;
                        break;
                    // No specific case for 'user_wrong_opponent_wrong' or 'user_wrong_no_answer' here
                    // as 'both_wrong_or_skipped' covers the outcome display effectively.
                      default:
                        userStatus = 'Outcome pending or unknown.'; // Should not typically be seen
                        userStatusColor = Colors.white;
                    }


                    return Container(
                      margin: EdgeInsets.symmetric(vertical:screenWidth * 0.02),
                      padding: EdgeInsets.all(screenWidth * 0.02),
                      decoration: BoxDecoration(
                        color: const Color(0xFF000000), // Black background, from ResultScreen
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: themeColor, // Amber border as requested
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Question outcome header
                          Center(
                            child: Text(
                              userStatus,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: screenWidth*0.04,
                                fontWeight: FontWeight.normal,
                                color: userStatusColor,
                              ),
                            ),
                          ),
                           SizedBox(height: screenWidth * 0.02),

                          // if (qa.imagePath != null && qa.imagePath!.isNotEmpty)
                          //   Container(
                          //     margin: const EdgeInsets.symmetric(vertical: 0),
                          //     child: Center(
                          //       child: SizedBox(
                          //         width: screenWidth * 0.6,
                          //         height: (screenWidth * 0.6) / 1.5,
                          //         child: Image.asset(
                          //           qa.imagePath!,
                          //           fit: BoxFit.contain,
                          //           errorBuilder: (context, error, stackTrace) {
                          //             return const Text(
                          //               'Image not found',
                          //               style: TextStyle(color: Colors.redAccent),
                          //             );
                          //           },
                          //         ),
                          //       ),
                          //     ),
                          //   ),

                          // ... inside the ListView.builder's itemBuilder

                          // if (qa.imagePath != null && qa.imagePath!.isNotEmpty)
                          //   Container(
                          //     margin: const EdgeInsets.symmetric(vertical: 0),
                          //     child: Center(
                          //       child: SizedBox(
                          //         width: screenWidth * 0.6,
                          //         height: (screenWidth * 0.6) / 1.5,
                          //         child: qa.imagePath!.endsWith('.svg')
                          //             ? SvgPicture.asset(
                          //           qa.imagePath!,
                          //           fit: BoxFit.contain,
                          //           placeholderBuilder: (context) => const SizedBox.shrink(),
                          //         )
                          //             : Image.asset(
                          //           qa.imagePath!,
                          //           fit: BoxFit.contain,
                          //           errorBuilder: (context, error, stackTrace) {
                          //             return const Text(
                          //               'Image not found',
                          //               style: TextStyle(color: Colors.redAccent),
                          //             );
                          //           },
                          //         ),
                          //       ),
                          //     ),
                          //   ),

// ... rest of the code

                          if (qa.imagePath != null && qa.imagePath!.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 0),
                              child: Center(
                                child: SizedBox(
                                  // WIDTH LOGIC
                                  width: qa.imagePath!.endsWith('.glb')
                                      ? screenWidth * 0.6
                                      : qa.imagePath!.endsWith('.riv')
                                      ? screenWidth * 0.65
                                      : screenWidth * 0.62,

                                  // HEIGHT LOGIC
                                  height: qa.imagePath!.endsWith('.glb')
                                      ? screenWidth * 0.6
                                      : qa.imagePath!.endsWith('.riv')
                                      ? (screenWidth * 0.65) / 1.5
                                      : (screenWidth * 0.62) / 1.5,

                                  child: Builder(
                                    builder: (context) {
                                      String path = qa.imagePath!;

                                      // 1. Handle SVG
                                      if (path.endsWith('.svg')) {
                                        return Opacity(
                                          opacity: 0.85,
                                          child: SvgPicture.asset(
                                            path,
                                            fit: BoxFit.contain,
                                            placeholderBuilder: (context) =>
                                            const SizedBox.shrink(),
                                          ),
                                        );
                                      }
                                      // 2. Handle Rive Animation (.riv)
                                      else if (path.endsWith('.riv')) {
                                        return Opacity(
                                          opacity: 0.8,
                                          child: FormulaRiveViewer(
                                            src:path,
                                            //fit: BoxFit.contain,
                                          ),
                                        );
                                      }
                                      // 3. Handle 3D Model (.glb)
                                      else if (path.endsWith('.glb')) {
                                        return ModelViewer(
                                          src: path,
                                          alt: "3D Model",
                                          ar: false,
                                          autoRotate: true,
                                          disableZoom: false,
                                          disablePan: true,
                                          cameraControls: true,
                                          interactionPrompt: InteractionPrompt.none,
                                          shadowIntensity: 0,
                                          autoPlay: true,
                                        );
                                      }
                                      // 4. Handle Standard Images
                                      else {
                                        return Image.asset(
                                          path,
                                          fit: BoxFit.contain,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Text(
                                              'Image not found',
                                              style: TextStyle(
                                                  color: Colors.redAccent),
                                            );
                                          },
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),


                          Html(
                            data: "<b>Q:</b> ${qa.question}",
                            style: {
                              "body": Style(
                                fontSize: FontSize(screenWidth * 0.037),
                                color: Color(0xD9FFFFFF),
                                fontFamily: GoogleFonts.poppins().fontFamily,
                              ),
                            },
                          ),
                          // SizedBox(height: screenWidth * 0.01),

                          // Your Answer
                          // Display Your Answer and Correct Answer in a Row
                          // Your Answer
                          Text(
                            'Your Answer:',
                            style: GoogleFonts.poppins(
                              color: Color(0xD9FFFFFF),
                              fontSize: screenWidth*0.037,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          SizedBox(height: screenWidth*0.01),


                          SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child:Math.tex(
                            qa.userAnswer,
                            textStyle: TextStyle(
                              color: (qa.userAnswer == qa.correctAnswer) ? Color(
                                  0xD9A4FF9D) : Color(0xD9FF5454), // Colors from ResultScreen
                              fontSize: screenWidth * 0.043,
                            ),
                          ),
                          ),
                          SizedBox(height: screenWidth*0.03), // Standard spacing after user answer

                          // Correct Answer
                          Text(
                            'Correct Answer:',
                            style: GoogleFonts.poppins(
                              color: Color(0xD9FFFFFF),
                              fontSize: screenWidth*0.037,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          SizedBox(height: screenWidth*0.01),


                          SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Math.tex(
                            qa.correctAnswer,
                            textStyle:  TextStyle(
                              color: Color(0xD9A4FF9D), // Green for correct, from ResultScreen
                              fontSize: screenWidth * 0.043,
                            ),
                          ),
                          ),
                          //const SizedBox(height: 8), // Standard spacing after correct answer (before tip)

                          // Tip Block remains as is after this
                          if (qa.tip != null && qa.tip!.isNotEmpty) ...[
                            SizedBox(height: screenWidth*0.04), // Space above the tip text itself
                             Text(
                              'Tip :',
                              style: GoogleFonts.poppins(
                                color: Color(0xFFF8A46F),
                                fontSize: screenWidth*0.045,
                                fontWeight: FontWeight.w600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            SizedBox(height: screenWidth*0.01),
                            Text(
                              qa.tip!,
                              style: GoogleFonts.poppins(
                                color: Color(0xFFF8A46F),
                                fontSize: screenWidth * 0.039,
                                fontWeight: FontWeight.normal,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              )
            else
            // Fallback if the list is empty (should not happen if game works correctly)
              const Expanded(
                child: Center(
                  child: Text(
                    'No Questions attempted',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
              ),
            // End of Detailed Question Results

            //Spacer(), // This spacer will push the Home button to the bottom // Pushes content to center/bottom

    Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.00, vertical: screenHeight * 0.017),
            child:SizedBox(
              width: double.infinity, // Responsive width
              height: screenHeight * 0.07, // Responsive height
              child: ElevatedButton(
                // onPressed: () {
                //   Navigator.of(context).popUntil((route) => route.isFirst); // Go back to Home Screen
                // },

                onPressed: () async {
                  await Future.delayed(const Duration(milliseconds: 200));
                  // 1. Determine Result Status
                  String resultStatus = 'loss'; // Default fallback

                  if (widget.youLeftGame) {
                    // Case A: You left the game
                    resultStatus = 'loss';
                  } else if (widget.opponentLeftGame) {
                    // Case B: Opponent left (You win automatically)
                    resultStatus = 'win';
                  } else {
                    // Case C: Game finished normally - Compare Scores
                    if (myScore > opponentScore) {
                      resultStatus = 'win';
                    } else if (myScore < opponentScore) {
                      resultStatus = 'loss';
                    } else {
                      // Case D: Scores are equal
                      resultStatus = 'draw';
                    }
                  }

                  // 2. Save Result to SharedPreferences
                  final prefs = await SharedPreferences.getInstance();
                  // Saves: 'win', 'loss', or 'draw'
                  await prefs.setString('last_battle_result', resultStatus);

                  // 3. Navigate Home
                  if (context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor.withOpacity(0.2), // More vibrant color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),side: BorderSide(color: themeColor, width: 0.8),

                  ),
                  elevation: 8,
                ),
                child:  Text('Home', style: TextStyle(fontSize: screenWidth*0.046,color: Color(0xD9FFFFFF), fontWeight: FontWeight.normal)),
              ),
            ),
    ),


            //SizedBox(height: screenHeight * 0.02), // Bottom padding
          ],
        ),
      ),

        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          numberOfParticles: 40,// A default value, will be overridden by the controller
          gravity: 0.3,
          emissionFrequency: 0.05,
          colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple, Colors.yellow, Colors.red],
        ),

        ConfettiWidget(
          confettiController: _confettiDrawController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          numberOfParticles: 20,// A default value, will be overridden by the controller
          gravity: 0.3,
          emissionFrequency: 0.05,
          colors: const [Colors.white,Colors.orange],
        ),


      ],
      ),
    ),
    );
  }
}