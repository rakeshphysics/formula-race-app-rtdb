import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/online_incorrect_answer_model.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class OnlineResultScreen extends StatelessWidget {
  final Map<dynamic, dynamic> scores;
  final String playerId;
  final bool isPlayer1;
  final bool opponentLeftGame;
  final bool youLeftGame;
  final int totalQuestions;
  final List<OnlineIncorrectAnswer> onlineIncorrectAnswers;

  const OnlineResultScreen({
    Key? key,
    required this.scores,
    required this.playerId,
    required this.isPlayer1,
    this.opponentLeftGame = false,
    this.youLeftGame = false,
    required this.totalQuestions,
    required this.onlineIncorrectAnswers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    int myScore;
    int opponentScore;

    if (isPlayer1) {
      myScore = scores['player1'] ?? 0;
      opponentScore = scores['player2'] ?? 0;
    } else {
      myScore = scores['player2'] ?? 0;
      opponentScore = scores['player1'] ?? 0;
    }

    String resultMessage;
    Color resultMessageColor;

    if (youLeftGame) { // Check this first
      resultMessage = 'You left the Game\nYou Lose \u{1F622}';
      resultMessageColor = Colors.redAccent;
    } else if (opponentLeftGame) { // If opponent left the game
      resultMessage = 'Opponent left the Game\nYou Win 🥳'; // Specific message
      resultMessageColor = Colors.amberAccent; // Winner color
      myScore = totalQuestions; // Ensure score is displayed as totalQuestions for the win
      opponentScore = 0; // Ensure opponent's score is 0
    } else if (myScore > opponentScore) {
      resultMessage = '🥳 You Win 🥳';
      resultMessageColor = Colors.amberAccent;
    } else if (myScore < opponentScore) {
      resultMessage = '🤝 Opponent Wins 🤝';
      resultMessageColor = Colors.amberAccent;
    } else {
      resultMessage = '🤝  It\'s a Draw  🤝';
      resultMessageColor = Colors.amberAccent;
    }

    return Scaffold(
      backgroundColor: Colors.black,
          appBar: AppBar(
          backgroundColor: Colors.black,
          toolbarHeight: 10,
          title: Text('', style: GoogleFonts.poppins(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          automaticallyImplyLeading: false, // Hide back button
           ),
      body: Padding(
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
                color: Color(0xFFFC107),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.amber, width: 1.8),// Responsive border radius
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
                          fontSize: screenWidth * 0.05, // Responsive font size
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        '$myScore',
                        style: GoogleFonts.hedvigLettersSerif(
                          fontSize: screenWidth * 0.07, // Responsive font size
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
                          fontSize: screenWidth * 0.05, // Responsive font size
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        '$opponentScore',
                        style: GoogleFonts.hedvigLettersSerif(
                          fontSize: screenWidth * 0.07, // Responsive font size
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
            if (onlineIncorrectAnswers.isNotEmpty) // Only show if there are questions to display
              Expanded(
                child: ListView.builder(
                  itemCount: onlineIncorrectAnswers.length,
                  itemBuilder: (context, index) {
                    final qa = onlineIncorrectAnswers[index]; // qa for question/answer
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
                        userStatusColor = Colors.amberAccent;
                        break;
                    // No specific case for 'user_wrong_opponent_wrong' or 'user_wrong_no_answer' here
                    // as 'both_wrong_or_skipped' covers the outcome display effectively.
                      default:
                        userStatus = 'Outcome pending or unknown.'; // Should not typically be seen
                        userStatusColor = Colors.white;
                    }


                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF000000), // Black background, from ResultScreen
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber, // Amber border as requested
                          width: 0.8,
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
                                fontSize: screenWidth*0.038,
                                fontWeight: FontWeight.normal,
                                color: userStatusColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (qa.imagePath != null && qa.imagePath!.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(bottom: 0),
                              child: Center(
                                child: Image.asset(
                                  qa.imagePath!,
                                  height: MediaQuery.of(context).size.height * 0.22,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),

                          Html(
                            data: "<b>Q:</b> ${qa.question}",
                            style: {
                              "body": Style(
                                fontSize: FontSize(screenWidth * 0.033),
                                color: Color(0xFFDCDCDC),
                                fontFamily: GoogleFonts.poppins().fontFamily,
                              ),
                            },
                          ),
                          const SizedBox(height: 8),

                          // Your Answer
                          // Display Your Answer and Correct Answer in a Row
                          // Your Answer
                          Text(
                            'Your Answer:',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: screenWidth*0.033,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.007),
                          Math.tex(
                            qa.userAnswer,
                            textStyle: TextStyle(
                              color: (qa.userAnswer == qa.correctAnswer) ? Color(0xFFA4FF9D) : Color(0xFFFF5454), // Colors from ResultScreen
                              fontSize: screenWidth * 0.042,
                            ),
                          ),
                          const SizedBox(height: 8), // Standard spacing after user answer

                          // Correct Answer
                          Text(
                            'Correct Answer:',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: screenWidth*0.033,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.007),
                          Math.tex(
                            qa.correctAnswer,
                            textStyle:  TextStyle(
                              color: Color(0xFFA4FF9D), // Green for correct, from ResultScreen
                              fontSize: screenWidth * 0.042,
                            ),
                          ),
                          const SizedBox(height: 8), // Standard spacing after correct answer (before tip)

                          // Tip Block remains as is after this
                          if (qa.tip != null && qa.tip!.isNotEmpty) ...[
                            const SizedBox(height: 8), // Space above the tip text itself
                             Text(
                              'Tip:',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: screenWidth*0.033,
                                fontWeight: FontWeight.w600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            Text(
                              qa.tip!,
                              style: GoogleFonts.poppins(
                                color: Color(0xFFFFC107),
                                fontSize: screenWidth*0.033,
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
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst); // Go back to Home Screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0x2DFFC107), // More vibrant color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),side: BorderSide(color: Colors.amber, width: 0.8),

                  ),
                  elevation: 8,
                ),
                child:  Text('Home', style: TextStyle(fontSize: screenWidth*0.046,color: Colors.white, fontWeight: FontWeight.normal)),
              ),
            ),
    ),


            //SizedBox(height: screenHeight * 0.02), // Bottom padding
          ],
        ),
      ),
    );
  }
}