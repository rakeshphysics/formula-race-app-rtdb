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
  String determinedMatchId = 'your_match_id_here'; // Replace with actual value
  int determinedSeed = 12345; // Replace with actual value
  bool determinedIsPlayer1 = true; // Replace with actual value based on role
  String currentUserId = '123';
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
        title: const Text(
            'Choose Game portion', style: TextStyle(fontSize:20,color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Center( // CENTER THE COLUMN
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // -------------------- CHUNK 4 — BUTTONS -----------------
         GlowButtonamber(
              label: 'Chapter Wise',
              width: screenWidth * 0.8,
              height: screenHeight * 0.08,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OnlineChapterSelectionScreen(userId: userId),
                  ),
                );
              },

        ),

            SizedBox(height: screenHeight * 0.024),

            GlowButtonamber(
              label: 'Full 11th',
              width: screenWidth * 0.8,
              height: screenHeight * 0.08,
              onPressed: () {
                // Navigate to SoloScreen with selected chapter
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QRHostScreen( matchId: determinedMatchId,
                      playerId: currentUserId,
                      seed: determinedSeed,
                      isPlayer1: determinedIsPlayer1,),
                  ),
                );
              },
            ),

            SizedBox(height: screenHeight * 0.024),

            GlowButtonamber(
              label: 'Full 12th',
              width: screenWidth * 0.8,
              height: screenHeight * 0.08,
              onPressed: () {
                // Navigate to SoloScreen with selected chapter
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QRHostScreen( matchId: determinedMatchId,
                      playerId: currentUserId,
                      seed: determinedSeed,
                      isPlayer1: determinedIsPlayer1,),
                  ),
                );
              },
            ),

            SizedBox(height: screenHeight * 0.024),

            GlowButtonamber(
              label: '11th + 12th',
              width: screenWidth * 0.8,
              height: screenHeight * 0.08,
                    onPressed: () async {
                      final User? currentUser = FirebaseAuth.instance
                          .currentUser;
                      if (currentUser != null && currentUser.uid.isNotEmpty) {
                        final createdMatchData = await MatchmakingService
                            .createMatch(userId);
                        if (createdMatchData != null) {
                          final matchId = createdMatchData['matchId'];
                          final seed = createdMatchData['seed'];

                          Navigator.push(
                            context, MaterialPageRoute(builder: (context) =>
                              QRHostScreen(matchId: matchId,
                                  seed: seed,
                                  isPlayer1: true,
                                  playerId: userId),),
                          );
                        }
                      }
                    },
            ),

          ],
        ),
      ),
    ));
  }

  // -------------------- CHUNK 5 — START Online GAME -----------------
  void _startOnlineGame(BuildContext context, String mode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OnlineGameScreen( matchId: determinedMatchId,
    playerId: currentUserId,
    seed: determinedSeed,
    isPlayer1: determinedIsPlayer1),
      ),
    );
  }
}