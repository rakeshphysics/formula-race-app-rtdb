// lib/screens/revise_chapter_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../quiz_data_provider.dart';
import '../widgets/chapter_progress_button.dart';
import 'formula_display_screen.dart'; // <-- 1. IMPORT the new screen we will create next

class ReviseChapterSelectionScreen extends StatefulWidget {
  // 2. REMOVED userId as it's not needed for revision
  const ReviseChapterSelectionScreen({super.key});

  @override
  State<ReviseChapterSelectionScreen> createState() => _ReviseChapterSelectionScreenState();
}

class _ReviseChapterSelectionScreenState extends State<ReviseChapterSelectionScreen> {
  // This list of chapters is reused from the original screen
  final List<String> chapters = [
    'Vectors', 'Units and Dimensions', 'Kinematics', 'Laws of Motion',
    'Circular Motion', 'Work Power Energy', 'Center of Mass', 'Rotational Motion',
    'Gravitation', 'Elasticity', 'Fluids', 'Thermodynamics', 'Kinetic Theory',
    'SHM', 'Waves', 'Electrostatics', 'Capacitors', 'Current Electricity',
    'Magnetism', 'EMI', 'AC', 'EM Waves', 'Ray Optics', 'Wave Optics',
    'Dual Nature of Light', 'Atoms', 'Nuclei', 'X Rays', 'Semiconductors',
  ];

  // 3. REMOVED all state and functions related to chapter progress,
  //    as it's not needed for the revision screen.

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final quizProvider = Provider.of<QuizDataProvider>(context);

    // 4. REMOVED WillPopScope as default back behavior is fine.
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        // 5. UPDATED AppBar to be more generic and have a back button by default
        title: Text('Select Chapter to Revise', style: TextStyle(fontSize: screenWidth * 0.042, color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white), // Ensure back arrow is white
      ),
      body: SafeArea(
        child: quizProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          physics: const BouncingScrollPhysics(),
          children: chapters.map((chapter) {
            // 6. SIMPLIFIED the button. No progress percentage is needed.
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0x1A00FFFF),
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side:  BorderSide(color: const Color(0x9900FFFF), width: 1),
                    ),
                  ),
                  onPressed: () {
                    // 7. CRITICAL CHANGE: Navigate to FormulaDisplayScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FormulaDisplayScreen(
                          chapterName: chapter,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    chapter,
                    style: const TextStyle(color: Color(0xD9FFFFFF), fontSize: 16),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}