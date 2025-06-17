// ----------------------------------------------------
// ChapterSelectionScreen.dart — Shows list of chapters
// - User clicks Chapter Wise in Solo Mode Selection
// - This screen opens with chapter buttons
// - Clicking a chapter navigates to SoloScreen (with selected chapter)
// ----------------------------------------------------

import 'package:flutter/material.dart';
import 'solo_screen.dart';  // Make sure your SoloScreen accepts selectedChapter param
import 'solo_mode_selection_screen.dart';


class ChapterSelectionScreen extends StatelessWidget {
  // You can customize this list with your real chapter names
  final List<String> chapters = [
    // Class 11
    'Units and Dimensions',
    'Kinematics',
    'Laws of Motion',
    'Work Power Energy',
    'Center of Mass',
    'Rotation',
    'Gravitation',
    'Mechanical Properties of Solids',
    'Mechanical Properties of Fluids',
    'Thermodynamics',
    'Kinetic Theory',
    'Oscillations',
    'Waves',

    // Class 12
    'Electrostatics',
    'Current Electricity',
    'Magnetism',
    'Electromagnetic Induction',
    'Alternating Current',
    'Electromagnetic Waves',
    'Ray Optics',
    'Wave Optics',
    'Dual Nature of Matter',
    'Atoms',
    'Nuclei',
    'Semiconductors',
  ];

  ChapterSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SoloModeSelectionScreen()),
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
                    builder: (context) => SoloScreen(selectedChapter: chapter),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey[600]!, width: 1.2),
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
