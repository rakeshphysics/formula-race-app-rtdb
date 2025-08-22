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
import '../widgets/chapter_progress_button.dart';
import 'package:provider/provider.dart';
import '../quiz_data_provider.dart';

const Map<String, String> chapterToClass = {
  "Units and Dimensions": "11",
  "Kinematics": "11",
  "Laws of Motion": "11",
  "Circular Motion": "11",
  "Work Power Energy": "11",
  "Center of Mass": "11",
  "Rotational Motion": "11",
  "Gravitation": "11",
  "Elasticity": "11",
  "Fluids": "11",
  "Thermodynamics": "11",
  "Kinetic Theory": "11",
  "SHM": "11",
  "Waves": "11",
  "Electrostatics": "12",
  "Capacitors": "12",
  "Current Electricity": "12",
  "Magnetism": "12",
  "EMI": "12",
  "AC": "12",
  "EM Waves": "12",
  "Ray Optics": "12",
  "Wave Optics": "12",
  "Dual Nature of Light": "12",
  "Atoms": "12",
  "Nuclei": "12",
  "X Rays": "12",
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

  Map<String, double> chapterCompletion = {};
  // _isLoading = true;

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
   // print('🔄 _loadChapterProgress started...');
    Map<String, double> percentages = {};

    final quizProvider = Provider.of<QuizDataProvider>(context, listen: false);

    for (String chapter in chapters) {
      final chapterFile = chapter.toLowerCase().replaceAll(" ", "_");

      if (quizProvider.allQuizData.containsKey(chapterFile)) {
        final List<dynamic> allQuestionsInChapter = quizProvider.allQuizData[chapterFile];
        final int totalQuestionsInChapter = allQuestionsInChapter.length;

        List<String> seenIds = await _getSeenQuestionIds(chapter);
        final int completedQuestionsInChapter = seenIds.length;

        double percentage = 0.0;
        if (totalQuestionsInChapter > 0) {
          percentage = (completedQuestionsInChapter / totalQuestionsInChapter) * 100;
        }

        percentages[chapter] = percentage;
      } else {
        percentages[chapter] = 0.0;
      }
    }

    setState(() {
       chapterCompletion = percentages;
    //   _isLoading = false;
     });
    //print('✅ _loadChapterProgress completed. State updated.');
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = Provider.of<QuizDataProvider>(context);
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
                  'Highlighted Area = Chapter Completion %', // As requested
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),


              Expanded(
                child: quizProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  children: chapters.map((chapter) {
                    final double percentage = chapterCompletion[chapter] ?? 0.0;

                    return Center( // Re-introduce Center to horizontally align the button
                      child: Padding( // Keep the padding for vertical spacing between buttons
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ChapterProgressButton( // It defines its own size now
                          chapterName: chapter,
                          percentage: percentage,
                          highlightColor: Colors.greenAccent,
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