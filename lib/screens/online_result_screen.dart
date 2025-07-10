// lib/screens/online_result_screen.dart
// Simple result screen for Online Play.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Ensure this is imported

class OnlineResultScreen extends StatelessWidget {
  final Map<dynamic, dynamic> scores;
  final String playerId;
  final bool isPlayer1; // This must be here

  // Constructor with all required parameters
  const OnlineResultScreen({
    Key? key,
    required this.scores,
    required this.playerId,
    required this.isPlayer1, // This must be here
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine myScore and opponentScore based on isPlayer1 flag
    // Access properties directly (isPlayer1, scores, playerId) since this is a StatelessWidget
    int myScore;
    int opponentScore;

    if (isPlayer1) { // Corrected: access directly, NOT widget.isPlayer1
      myScore = scores['player1'] ?? 0;
      opponentScore = scores['player2'] ?? 0;
    } else {
      myScore = scores['player2'] ?? 0;
      opponentScore = scores['player1'] ?? 0;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Game Over', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Final Scores',
                style: GoogleFonts.poppins( // Using GoogleFonts
                  color: Colors.amber,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Display 'Your Score' and 'Opponent Score' explicitly
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Your Score: $myScore points', // Use myScore here
                style: GoogleFonts.poppins( // Using GoogleFonts
                  color: Colors.greenAccent,
                  fontSize: 20,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Opponent Score: $opponentScore points', // Use opponentScore here
                style: GoogleFonts.poppins( // Using GoogleFonts
                  color: Colors.redAccent,
                  fontSize: 20,
                ),
              ),
            ),
            const Spacer(),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                ),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Home', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}