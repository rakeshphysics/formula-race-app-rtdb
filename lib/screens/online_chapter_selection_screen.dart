// ----------------------------------------------------
// OnlineChapterSelectionScreen.dart — Shows list of chapters
// - User clicks Chapter Wise in Solo Mode Selection
// - This screen opens with chapter buttons
// - Clicking a chapter navigates to SoloScreen (with selected chapter)
// ----------------------------------------------------

import 'package:flutter/material.dart';
import 'online_mode_selection_screen.dart';
import 'qr_host_screen.dart';
import 'package:formularacing/services/matchmaking_service.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Ensure FirebaseAuth is imported if not already



class OnlineChapterSelectionScreen extends StatelessWidget {
  final String userId;

  // You can customize this list with your real chapter names
  final List<String> chapters = [
    // Class 11
    'Vectors',
     'Units and Dimensions',
    'Kinematics',
    'Laws of Motion',
    'Circular Motion',
    'Work Power Energy',
    'Center of Mass',
    'Rotational Motion',
    'Gravitation',
    'Elasticity',
    'Fluids',
    'Thermodynamics',
    'Kinetic Theory',
    'SHM',
    'Waves',

    // Class 12
    'Electrostatics',
    'Capacitors',
    'Current Electricity',
    'Magnetism',
    'EMI',
    'AC',
    'EM Waves',
    'Ray Optics',
    'Wave Optics',
    'Dual Nature of Light',
    'Atoms',
    'Nuclei',
    'X Rays',
    'Semiconductors',
  ];

  OnlineChapterSelectionScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return WillPopScope(
        onWillPop: () async {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OnlineModeSelectionScreen(userId: userId)),
      );
      return false;
    },


  child: Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Select Chapter', style: TextStyle(fontSize:screenWidth*0.042,color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        children: chapters.map((chapter) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: OutlinedButton(
              // Inside your ListView children: chapters.map((chapter) { ... }
              onPressed: () async { // Make onPressed async
                // Form the gameMode string for this chapter
                final String gameMode = 'chapter_wise_$chapter'; // e.g., 'chapter_wise_Vectors'

                //print('Attempting to create match for Chapter: $chapter with userId: $userId');

                final createdMatchData = await MatchmakingService.createMatch(
                  userId, // Use userId directly from constructor
                  gameMode: gameMode, // Pass the chapter-specific gameMode
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
                        playerId: userId, // Use userId directly
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to create match for chapter. Please try again.')),
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.amberAccent.withOpacity(0.6), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                padding:  EdgeInsets.symmetric(vertical: screenWidth*0.047,  horizontal: screenWidth*0.06),
              ),
              child: Text(
                chapter,
                style:  TextStyle(
                  fontSize: screenWidth*0.041,
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ));
  }
  }
