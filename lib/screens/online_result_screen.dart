import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Ensure this is imported

class OnlineResultScreen extends StatelessWidget {
  final Map<dynamic, dynamic> scores;
  final String playerId;
  final bool isPlayer1;
  final bool opponentLeftGame;
  final int totalQuestions;

  const OnlineResultScreen({
    Key? key,
    required this.scores,
    required this.playerId,
    required this.isPlayer1,
    this.opponentLeftGame = false,
    required this.totalQuestions,
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

    if (opponentLeftGame) { // If opponent left the game
      resultMessage = 'Opponent left the Game\nYou Win!'; // Specific message
      resultMessageColor = Colors.greenAccent; // Winner color
      myScore = totalQuestions; // Ensure score is displayed as totalQuestions for the win
      opponentScore = 0; // Ensure opponent's score is 0
    } else if (myScore > opponentScore) {
      resultMessage = 'You Win!';
      resultMessageColor = Colors.greenAccent;
    } else if (myScore < opponentScore) {
      resultMessage = 'You Lose!';
      resultMessageColor = Colors.redAccent;
    } else {
      resultMessage = 'It\'s a Draw!';
      resultMessageColor = Colors.amber;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Game Over', style: GoogleFonts.poppins(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false, // Hide back button
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04), // Responsive padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Spacer(), // Pushes content to center/bottom

            // Game Result Message (You Win/Lose/Draw)
            Text(
              resultMessage,
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.08, // Responsive font size
                fontWeight: FontWeight.bold,
                color: resultMessageColor,
                letterSpacing: 2.0,
              ),
            ),
            SizedBox(height: screenHeight * 0.04), // Responsive spacing

            // Score Display Container
            Container(
              width: screenWidth * 0.85, // Responsive width
              padding: EdgeInsets.symmetric(
                vertical: screenHeight * 0.03,
                horizontal: screenWidth * 0.05,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(screenWidth * 0.03), // Responsive border radius
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
                        'YOUR SCORE:',
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.045, // Responsive font size
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$myScore',
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.06, // Responsive font size
                          fontWeight: FontWeight.bold,
                          color: Colors.greenAccent,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.02), // Responsive spacing
                  // Opponent Score
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'OPPONENT SCORE:',
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.045, // Responsive font size
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$opponentScore',
                        style: GoogleFonts.poppins(
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
            Spacer(), // Pushes content to center/bottom

            // Play Again Button
            SizedBox(
              width: screenWidth * 0.7, // Responsive width
              height: screenHeight * 0.08, // Responsive height
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst); // Go back to Home Screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // More vibrant color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),side: BorderSide(color: Colors.blue, width: 1.2),

                  ),
                  elevation: 8,
                ),
                child: const Text('Home', style: TextStyle(fontSize: 18,color: Colors.white)),
              ),
            ),
            SizedBox(height: screenHeight * 0.04), // Bottom padding
          ],
        ),
      ),
    );
  }
}