// -------------------------------------------------------------
// OnlineModeSelectionScreen.dart → Final version
// -------------------------------------------------------------
// - Buttons centered
// - Buttons sized by screenWidth / screenHeight
// - Dark theme (black background, white text)
// -------------------------------------------------------------

// -------------------- CHUNK 1 — IMPORT -----------------------
import 'package:flutter/material.dart';
import 'online_game_screen.dart'; // import your OnlineScreen
import 'chapter_selection_screen.dart';
import '../widgets/glow_button_amber.dart';
import 'multiplayer_selection_screen.dart';
import 'online_chapter_selection_screen.dart';
import 'qr_host_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:formularacing/services/matchmaking_service.dart';


// -------------------- CHUNK 2 — CLASS HEADER -----------------
class OnlineModeSelectionScreen extends StatelessWidget {
  final String userId;
  //String determinedMatchId = 'your_match_id_here'; // Replace with actual value
  //int determinedSeed = 12345; // Replace with actual value
  //bool determinedIsPlayer1 = true; // Replace with actual value based on role
  //String currentUserId = '123';
   OnlineModeSelectionScreen({super.key, required this.userId});

  // -------------------- CHUNK 3 — BUILD FUNCTION -----------------
  @override
  Widget build(BuildContext context) {
    // Screen size → consistent with HomeScreen
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return WillPopScope(
        onWillPop: () async {
      await Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MultiplayerSelectionScreen(userId:userId,)),
      );
      return false;
    },

    child: Scaffold(
      backgroundColor: Colors.black, // DARK THEME

      appBar: AppBar(
        backgroundColor: Colors.black, // DARK THEME
        title:  Text(
            'Choose Game portion', style: TextStyle(fontSize:screenWidth*0.042,color: Color(
            0xD9FFFFFF))),
        iconTheme: const IconThemeData(color: Color(
            0xD9FFFFFF)),
      ),

      body: Center( // CENTER THE COLUMN
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // -------------------- CHUNK 4 — BUTTONS -----------------
            // Inside OnlineModeSelectionScreen build method

        GlowButtonamber(
        label: 'Chapter Wise',
          width: screenWidth * 0.8,
          height: screenHeight * 0.08,
          onPressed: () { // No need for async if not calling createMatch here
            // Removed the FirebaseAuth.instance.currentUser check and related if statement
            //print('Navigating to OnlineChapterSelectionScreen with userId: $userId'); // Using userId directly

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OnlineChapterSelectionScreen(userId: userId),
              ),
            );
          },
        ),

            SizedBox(height: screenHeight * 0.024),

            // Inside OnlineModeSelectionScreen build method
            // --- Full 11th Button ---
            GlowButtonamber(
              label: 'Full 11th',
              width: screenWidth * 0.8,
              height: screenHeight * 0.08,
              onPressed: () async { // Make onPressed async
                // Removed the FirebaseAuth.instance.currentUser check and related if statement
                //print('Navigating to QRHostScreen for Full 11th with userId: $userId'); // Using userId directly

                final createdMatchData = await MatchmakingService.createMatch(
                  userId, // Directly use the userId from the widget's constructor
                  gameMode: 'full_11th', // Pass the correct mode here
                );

                if (createdMatchData != null) {
                  final matchId = createdMatchData['matchId'];
                  final seed = createdMatchData['seed'];

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QRHostScreen(
                        matchId: matchId,
                        seed: seed,
                        isPlayer1: true, // Host is always Player 1
                        playerId: userId, // Directly use the userId
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to create match for Full 11th. Please try again.')),
                  );
                }
              },
            ),

            SizedBox(height: screenHeight * 0.024), // Keep this SizedBox between buttons

// --- Full 12th Button ---
            GlowButtonamber(
              label: 'Full 12th',
              width: screenWidth * 0.8,
              height: screenHeight * 0.08,
              onPressed: () async { // Make onPressed async
                // Removed the FirebaseAuth.instance.currentUser check and related if statement
                //print('Navigating to QRHostScreen for Full 12th with userId: $userId'); // Using userId directly

                final createdMatchData = await MatchmakingService.createMatch(
                  userId, // Directly use the userId from the widget's constructor
                  gameMode: 'full_12th', // Pass the correct mode here
                );

                if (createdMatchData != null) {
                  final matchId = createdMatchData['matchId'];
                  final seed = createdMatchData['seed'];

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QRHostScreen(
                        matchId: matchId,
                        seed: seed,
                        isPlayer1: true, // Host is always Player 1
                        playerId: userId, // Directly use the userId
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to create match for Full 12th. Please try again.')),
                  );
                }
              },
            ),

            SizedBox(height: screenHeight * 0.024),

            // Inside OnlineModeSelectionScreen build method
            GlowButtonamber(
              label: '11th + 12th',
              width: screenWidth * 0.8,
              height: screenHeight * 0.08,
              onPressed: () async { // Keep async because of MatchmakingService.createMatch
                // Removed the FirebaseAuth.instance.currentUser check and related if statement
               // print('Navigating to QRHostScreen for 11th + 12th with userId: $userId'); // Using userId directly

                final createdMatchData = await MatchmakingService.createMatch(
                  userId, // Directly use the userId from the widget's constructor
                  gameMode: 'combined_11_12', // Assuming this is the correct mode string
                );

                if (createdMatchData != null) {
                  final matchId = createdMatchData['matchId'];
                  final seed = createdMatchData['seed'];

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QRHostScreen(
                        matchId: matchId,
                        seed: seed,
                        isPlayer1: true,
                        playerId: userId, // Directly use the userId
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to create match. Please try again.')),
                  );
                }
              },
            ),

          ],
        ),
      ),
    ));
  }
}