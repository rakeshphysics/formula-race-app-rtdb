// ----------------------------------------------------
// ChapterSelectionScreen.dart — Shows list of chapters
// - User clicks Chapter Wise in Solo Mode Selection
// - This screen opens with chapter buttons
// - Clicking a chapter navigates to SoloScreen (with selected chapter)
// ----------------------------------------------------

import 'package:flutter/material.dart';
import 'solo_screen.dart';
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
  "Vectors": "11",
};

class ChapterSelectionScreen extends StatefulWidget {
  final String userId;
  ChapterSelectionScreen({super.key, required this.userId});

  @override
  State<ChapterSelectionScreen> createState() => _ChapterSelectionScreenState();
}

class _ChapterSelectionScreenState extends State<ChapterSelectionScreen> {
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

  Map<String, double> chapterCompletion = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChapterProgress();
  }

  Future<List<String>> _getSeenQuestionIds(String chapter) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('seen_questions_$chapter') ?? [];
  }

  Future<void> _loadChapterProgress() async {
    print('🔄 _loadChapterProgress started...');
    Map<String, double> percentages = {};

    for (String chapter in chapters) {
      final chapterClass = chapterToClass[chapter] ?? '11';
      final chapterFile = chapter.toLowerCase().replaceAll(" ", "_");
      final path = 'assets/formulas/$chapterClass/$chapterFile.json';

      print('  Loading data for chapter: $chapter from path: $path');

      try {
        final String data = await rootBundle.loadString(path);
        final List<dynamic> allQuestionsInChapter = json.decode(data).cast<Map<String, dynamic>>();
        final int totalQuestionsInChapter = allQuestionsInChapter.length;

        List<String> seenIds = await _getSeenQuestionIds(chapter);
        final int completedQuestionsInChapter = seenIds.length;

        double percentage = 0.0;
        if (totalQuestionsInChapter > 0) {
          percentage = (completedQuestionsInChapter / totalQuestionsInChapter) * 100;
        }

        percentages[chapter] = percentage;
        print('    📊 Chapter: $chapter, Total Qns: $totalQuestionsInChapter, Completed Qns: $completedQuestionsInChapter, Percentage: ${percentage.toStringAsFixed(2)}%');

      } catch (e) {
        print('    ❗️ Error loading questions for $chapter in ChapterSelectionScreen: $e');
        percentages[chapter] = 0.0;
      }
    }

    setState(() {
      chapterCompletion = percentages;
      _isLoading = false;
    });
    print('✅ _loadChapterProgress completed. State updated.');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SoloModeSelectionScreen(userId: widget.userId)),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Select Chapter', style: TextStyle(fontSize: 20, color: Colors.white)),
          backgroundColor: Colors.black,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Highlighted Area = Progress.', // As requested
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  children: chapters.map((chapter) {
                    final double percentage = chapterCompletion[chapter] ?? 0.0;

                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.88,
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
                              // Remove backgroundColor from here as we'll handle it inside the child
                              // backgroundColor: Colors.transparent, // DELETE THIS LINE
                            ),
                            child: LayoutBuilder( // ADD LayoutBuilder to get the exact size
                                builder: (context, constraints) {
                                  return Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Black background (full width of the button content area)
                                      Container(
                                        width: constraints.maxWidth, // Use actual available width
                                        height: 50,
                                        decoration: const BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.all(Radius.circular(4)), // Apply radius here
                                        ),
                                      ),
                                      // CyanAccent fill, positioned correctly
                                      Align( // Use Align to position the fill
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          width: constraints.maxWidth * (percentage / 100), // Fill percentage of exact width
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Colors.cyanAccent.withOpacity(0.3),
                                            borderRadius: const BorderRadius.all(Radius.circular(4)), // Apply radius here
                                          ),
                                        ),
                                      ),
                                      // Text, layered on top
                                      Padding( // Padding for the text remains the same
                                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                                        child: Text(
                                          chapter,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.normal,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }
                            ),
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
      ),
    );
  }
}