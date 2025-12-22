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
  final Map<String, List<String>> allChaptersBySubject = {
    'Physics': [
      'Vectors', 'Units and Dimensions', 'Kinematics', 'Laws of Motion',
      'Circular Motion', 'Work Power Energy', 'Center of Mass', 'Rotational Motion',
      'Gravitation', 'Elasticity', 'Fluids', 'Thermodynamics', 'Kinetic Theory',
      'SHM', 'Waves', 'Electrostatics', 'Capacitors', 'Current Electricity',
      'Magnetism', 'EMI', 'AC', 'EM Waves', 'Ray Optics', 'Wave Optics',
      'Dual Nature of Light', 'Atoms', 'Nuclei', 'X Rays', 'Semiconductors',
    ],
    'Chemistry': [
      'Solid State','Some Basic Concepts of Chemistry', 'Structure of Atom', 'Classification of Elements'
    ],
    'Maths': [
      'Sets', 'Relations and Functions', 'Trigonometric Functions'
    ],
  };

  String _selectedSubject = 'Physics';

  Widget _buildSubjectButton(String subjectName, Map<String, Color> subjectColors) {

    final bool isSelected = _selectedSubject == subjectName;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedSubject = subjectName;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? subjectColors[subjectName] : subjectColors[subjectName]!.withOpacity(0.2),foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(
            color: subjectColors[subjectName]!,
            width: isSelected ? 2.0 : 2.0,
          ),
        ),
      ),
      child: Text(
        subjectName,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final quizProvider = Provider.of<QuizDataProvider>(context);
    final List<String> currentChapters = allChaptersBySubject[_selectedSubject] ?? [];
    final Map<String, Color> subjectColors = {
      'Physics': Colors.cyan.shade700.withOpacity(0.7),
      'Chemistry': Colors.green.shade700.withOpacity(0.7),
      'Maths': Colors.blue.shade700.withOpacity(0.7),
    };
    final Color currentSubjectColor = subjectColors[_selectedSubject] ?? Colors.cyan.shade700;
    // 4. REMOVED WillPopScope as default back behavior is fine.
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        // 5. UPDATED AppBar to be more generic and have a back button by default
        title: Text('Select Chapter to Revise', style: TextStyle(fontSize: screenWidth * 0.042, color: Color(0xD9FFFFFF))),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Color(0xD9FFFFFF)), // Ensure back arrow is white
      ),
      body: SafeArea(
        child: quizProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSubjectButton('Physics', subjectColors),
                  _buildSubjectButton('Chemistry', subjectColors),
                  _buildSubjectButton('Maths', subjectColors),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: currentChapters.map((chapter) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: currentSubjectColor.withOpacity(0.1),
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                            side: BorderSide(color: currentSubjectColor.withOpacity(0.6), width: 1.2), ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FormulaDisplayScreen(
                                chapterName: chapter,
                                subject: _selectedSubject,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          chapter,
                          style: const TextStyle(color: Color(0xD9FFFFFF), fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}