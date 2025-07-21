// -------------------------------------------------------------
// SoloModeSelectionScreen.dart → Final version
// -------------------------------------------------------------
// - Buttons centered
// - Buttons sized by screenWidth / screenHeight
// - Dark theme (black background, white text)
// -------------------------------------------------------------

// -------------------- CHUNK 1 — IMPORT -----------------------
import 'package:flutter/material.dart';
import 'solo_screen.dart'; // import your SoloScreen
import 'chapter_selection_screen.dart';
import '../widgets/glow_button_cyan.dart';
import 'home_screen.dart';


// -------------------- CHUNK 2 — CLASS HEADER -----------------
class SoloModeSelectionScreen extends StatelessWidget {
  final String userId;
  const SoloModeSelectionScreen({super.key, required this.userId});

  // -------------------- CHUNK 3 — BUILD FUNCTION -----------------
  @override
  Widget build(BuildContext context) {
    // Screen size → consistent with HomeScreen
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return WillPopScope(
        onWillPop: () async {
      await Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen(userId:userId,)),
      );
      return false;
    },

    child: Scaffold(
      backgroundColor: Colors.black, // DARK THEME

      appBar: AppBar(
        backgroundColor: Colors.black, // DARK THEME
        title: const Text(
            'Choose Solo Mode', style: TextStyle(fontSize:20,color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Center( // CENTER THE COLUMN
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // -------------------- CHUNK 4 — BUTTONS -----------------
         GlowButtonCyan(
              label: 'Chapter Wise',
              width: screenWidth * 0.8,
              height: screenHeight * 0.08,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChapterSelectionScreen(userId:userId),
                  ),
                );
              },

        ),

            SizedBox(height: screenHeight * 0.024),

            GlowButtonCyan(
              label: 'Full 11th',
              width: screenWidth * 0.8,
              height: screenHeight * 0.08,
              onPressed: () {
                _startSoloGame(context, 'full11');
              },
            ),

            SizedBox(height: screenHeight * 0.024),

            GlowButtonCyan(
              label: 'Full 12th',
              width: screenWidth * 0.8,
              height: screenHeight * 0.08,
              onPressed: () {
                _startSoloGame(context, 'full12');
              },
            ),

            SizedBox(height: screenHeight * 0.024),

            GlowButtonCyan(
              label: '11th + 12th',
              width: screenWidth * 0.8,
              height: screenHeight * 0.08,
              onPressed: () {
                _startSoloGame(context, 'fullBoth');
              },
            ),

          ],
        ),
      ),
    ));
  }

  // -------------------- CHUNK 5 — START SOLO GAME -----------------
  void _startSoloGame(BuildContext context, String mode) {
    print('✅✅✅✅✅>>> Navigating to SoloScreen for mode: $mode <<<');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SoloScreen(selectedChapter: mode, userId: userId,),
      ),
    );
  }
}