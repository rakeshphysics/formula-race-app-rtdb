// ----------------------------------------------------
// OnlineChapterSelectionScreen.dart — Shows list of chapters
// - User clicks Chapter Wise in Solo Mode Selection
// - This screen opens with chapter buttons
// - Clicking a chapter navigates to SoloScreen (with selected chapter)
// ----------------------------------------------------

import 'package:flutter/material.dart';
import 'online_mode_selection_screen.dart';
import 'qr_host_screen.dart';



class OnlineChapterSelectionScreen extends StatelessWidget {
  final String userId;
  String determinedMatchId = 'your_match_id_here'; // Replace with actual value
  int determinedSeed = 12345; // Replace with actual value
  bool determinedIsPlayer1 = true; // Replace with actual value based on role
  String currentUserId = '123';
  // You can customize this list with your real chapter names
  final List<String> chapters = [
    // Class 11
    'Vectors',
     'Units and Dimensions',
    'Kinematics',
    'Laws of Motion',
    'Work Power Energy',
    'Center of Mass',
    'Rotational Motion',
    'Gravitation',
    'Mechanical Properties of Solids',
    'Fluids',
    'Thermodynamics',
    'Kinetic Theory',
    'SHM',
    'Waves',

    // Class 12
    'Electrostatics',
    'Current Electricity',
    'Magnetism',
    'EMI',
    'AC',
    'EM Waves',
    'Ray Optics',
    'Wave Optics',
    'Modern Physics',
    'Semiconductors',
  ];

  OnlineChapterSelectionScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Select Chapter', style: TextStyle(fontSize:20,color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        children: chapters.map((chapter) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: OutlinedButton(
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
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.amberAccent.withOpacity(0.6), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              ),
              child: Text(
                chapter,
                style: const TextStyle(
                  fontSize: 20,
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
