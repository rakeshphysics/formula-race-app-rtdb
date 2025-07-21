// ----------------------------------------------------
// ChapterSelectionScreen.dart — Shows list of chapters
// - User clicks Chapter Wise in Solo Mode Selection
// - This screen opens with chapter buttons
// - Clicking a chapter navigates to SoloScreen (with selected chapter)
// ----------------------------------------------------

import 'package:flutter/material.dart';
import 'solo_screen.dart';  // Make sure your SoloScreen accepts selectedChapter param
import 'solo_mode_selection_screen.dart';

import 'package:flutter/services.dart'; // Needed for rootBundle
import 'dart:convert'; // Needed for json.decode
import 'package:shared_preferences/shared_preferences.dart';



const Map<String, String> chapterToClass = {
  "Units and Dimensions": "11",
  "Kinematics": "11",
  "Laws of Motion": "11",
  "Work Power Energy": "11",
  "Center of Mass": "11",
  "Rotational Motion": "11",
  "Gravitation": "11",
  "Mechanical Properties of Solids": "11",
  "Fluids": "11",
  "Thermodynamics": "11",
  "Kinetic Theory": "11",
  "SHM": "11",
  "Waves": "11",
  "Electrostatics": "12",
  "Current Electricity": "12",
  "Magnetism": "12",
  "EMI": "12",
  "AC": "12",
  "EM Waves": "12",
  "Ray Optics": "12",
  "Wave Optics": "12",
  "Modern Physics": "12",
  "Semiconductors": "12",
  "Vectors": "11", // Ensure 'Vectors' is included if it's a chapter
};


class ChapterSelectionScreen extends StatefulWidget {
  final String userId;
  ChapterSelectionScreen({super.key, required this.userId});

  @override
  State<ChapterSelectionScreen> createState() => _ChapterSelectionScreenState();
}

class _ChapterSelectionScreenState extends State<ChapterSelectionScreen> {
  // This list defines the order of chapters as they appear on the screen.
  // It is now moved from the StatelessWidget to the State class.
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

  // These will be added in the next steps:
  Map<String, double> chapterCompletion = {}; // To store calculated percentages
  bool _isLoading = true; // To show loading indicator

  // This will be added in the next steps:
  @override
  void initState() {
    super.initState();
    _loadChapterProgress();
    // This is where we'll call the function to load chapter progress.
  }

  // This will be added in the next steps:
  Future<List<String>> _getSeenQuestionIds(String chapter) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('seen_questions_$chapter') ?? [];
  }

  // This will be added in the next steps:
  Future<void> _loadChapterProgress() async {
    print('🔄 _loadChapterProgress started...'); // Debug print
    Map<String, double> percentages = {
    }; // Temporary map to store calculated percentages

    // Iterate through each chapter in our predefined list
    for (String chapter in chapters) {
      final chapterClass = chapterToClass[chapter] ?? '11'; // Get class (11/12)
      final chapterFile = chapter.toLowerCase().replaceAll(
          " ", "_"); // Format chapter name to match file name
      final path = 'assets/formulas/$chapterClass/$chapterFile.json'; // Construct the full path to the JSON file

      print(
          '  Loading data for chapter: $chapter from path: $path'); // Debug print

      try {
        // Load the JSON data for the current chapter from assets
        final String data = await rootBundle.loadString(path);
        // Decode the JSON string into a list of question maps
        final List<dynamic> allQuestionsInChapter = json.decode(data).cast<
            Map<String, dynamic>>();
        final int totalQuestionsInChapter = allQuestionsInChapter
            .length; // Get total questions

        // Retrieve the list of seen questions for this chapter from SharedPreferences
        List<String> seenIds = await _getSeenQuestionIds(chapter);
        final int completedQuestionsInChapter = seenIds
            .length; // Get count of completed questions

        double percentage = 0.0;
        if (totalQuestionsInChapter > 0) {
          // Calculate percentage if there are questions in the chapter
          percentage =
              (completedQuestionsInChapter / totalQuestionsInChapter) * 100;
        }

        // Store the calculated percentage in our temporary map
        percentages[chapter] = percentage;
        print(
            '    📊 Chapter: $chapter, Total Qns: $totalQuestionsInChapter, Completed Qns: $completedQuestionsInChapter, Percentage: ${percentage
                .toStringAsFixed(2)}%'); // Debug print

      } catch (e) {
        // If there's an error loading a chapter's JSON (e.g., file not found),
        // print an error and set its percentage to 0.0
        print(
            '    ❗️ Error loading questions for $chapter in ChapterSelectionScreen: $e'); // Error print
        percentages[chapter] = 0.0;
      }
    }

    // After processing all chapters, update the state to reflect the new percentages
    // This will trigger a rebuild of the UI, showing the updated progress.
    setState(() {
      chapterCompletion = percentages;
      _isLoading = false; // Data is loaded, hide loading indicator
    });
    print('✅ _loadChapterProgress completed. State updated.'); // Debug print
  }


  @override
  Widget build(BuildContext context) {
    // Allows handling back button press to navigate back to SoloModeSelectionScreen
    return WillPopScope(
      onWillPop: () async {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) =>
              SoloModeSelectionScreen(userId: widget.userId)),
        );
        return false; // Prevent default back button behavior
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Select Chapter',
              style: TextStyle(fontSize: 20, color: Colors.white)),
          backgroundColor: Colors.black,
        ),
        // Conditional rendering: show CircularProgressIndicator if loading, otherwise show the ListView
        body: _isLoading
            ? const Center(
            child: CircularProgressIndicator()) // Display loading spinner
            : ListView(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          children: chapters.map((chapter) {
            // Get the completion percentage for the current chapter, default to 0.0 if not found
            final double percentage = chapterCompletion[chapter] ?? 0.0;
            final int displayPercentage = percentage
                .round(); // Round to nearest integer for display

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SoloScreen(selectedChapter: chapter, userId: widget.userId),
                    ),
                  ).then((_) {
                    _loadChapterProgress();
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.cyanAccent.withOpacity(0.6), width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  // REMOVE THIS LINE: padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  backgroundColor: Colors.transparent,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // This container forms the black background of the button
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // This FractionallySizedBox creates the green filled portion
                    Positioned.fill(
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: percentage / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent.withOpacity(0.4), // CHANGED: Opacity to 20%
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    // The Text widget sits on top of the black and green layers
                    Center( // Keep text centered on top
                      child: Padding( // ADD THIS: Add padding directly to the Text
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24), // Re-apply padding for the text only
                        child: Text(
                          '$chapter (${displayPercentage.toInt()}%)',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.normal,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}