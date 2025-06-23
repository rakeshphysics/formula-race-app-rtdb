// lib/screens/solo_screen.dart
// ----------------------------------------------------
// Solo Play screen of the Formula Race App.
// 10-segment progress bar (WhatsApp style)
// Each segment → 7s → auto move if no click
// Sounds + polished buttons → unchanged
// Best practice: totalQuestions constant → easy to change
// ----------------------------------------------------

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../../models/incorrect_answer_model.dart';
import '../../screens/result_screen.dart';
import '../../widgets/formula_option_button.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../services/mistake_tracker_service.dart';
import 'solo_mode_selection_screen.dart';// ADD THIS IMPORT

// ............. Chunk 1 SOLO SCREEN WIDGET .............
const Map<String, String> chapterToClass = {
  "Units and Dimensions": "11",
  "Kinematics": "11",
  "Laws of Motion": "11",
  "Work Power Energy": "11",
  "Center of Mass": "11",
  "Rotation": "11",
  "Gravitation": "11",
  "Mechanical Properties of Solids": "11",
  "Mechanical Properties of Fluids": "11",
  "Thermodynamics": "11",
  "Kinetic Theory": "11",
  "Oscillations": "11",
  "Waves": "11",
  "Electrostatics": "12",
  "Current Electricity": "12",
  "Magnetism": "12",
  "Electromagnetic Induction": "12",
  "Alternating Current": "12",
  "Electromagnetic Waves": "12",
  "Ray Optics": "12",
  "Wave Optics": "12",
  "Dual Nature of Matter": "12",
  "Atoms": "12",
  "Nuclei": "12",
  "Semiconductors": "12",
};

class SoloScreen extends StatefulWidget {
  final String selectedChapter;
  final List<String>? selectedChapters;
  const SoloScreen({super.key, required this.selectedChapter,this.selectedChapters,});

  @override
  State<SoloScreen> createState() => _SoloScreenState();
}

class _SoloScreenState extends State<SoloScreen> with SingleTickerProviderStateMixin {

  // ............. Chunk 2 STATE VARIABLES .............
  final int totalQuestions = 10;  // ← change this to set number of questions and progress bars

  List<Map<String, dynamic>> questions = [];
  int currentIndex = 0;
  int score = 0;
  List<String> shuffledOptions = [];
  String? selectedOption;
  bool showResult = false;
  List<IncorrectAnswer> wrongAnswers = [];
  List<Map<String, dynamic>> responses = [];
  final AudioPlayer audioPlayer = AudioPlayer();

  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1000), // 7s per segment
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(_progressController);


    loadQuestions();
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && selectedOption == null) {
        // Auto move to next if user didn't click
        checkAnswer('');
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  // ............. Chunk 3 LOAD QUESTIONS .............
  Future<void> loadQuestions() async {
    print('loadQuestions started');
    print('selectedChapter = ${widget.selectedChapter}');

    List<Map<String, dynamic>> allQuestions = [];

    if (widget.selectedChapter == 'full11' ||
        widget.selectedChapter == 'full12' ||
        widget.selectedChapter == 'fullBoth') {

      print('Handling full mode: ${widget.selectedChapter}');

      List<String> fullChapters = [];

     if (widget.selectedChapter == 'full11') {
        fullChapters = [
          'Units and Dimensions',
          'Kinematics',
          'Laws of Motion',
          'Work Power Energy',
          'Center of Mass',
          'Rotational Motion',
          'Gravitation',
          'Mechanical Properties of Solids',
          'Mechanical Properties of Fluids',
          'Thermodynamics',
          'Kinetic Theory',
          'Oscillations',
          'Waves',
        ];
      }
    else if (widget.selectedChapter == 'full12') {
        fullChapters = [
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
      } else if (widget.selectedChapter == 'fullBoth') {
        fullChapters = [
          // 11th
          'Units and Dimensions',
          'Kinematics',
          'Laws of Motion',
          'Work Power Energy',
          'Center of Mass',
          'Rotational Motion',
          'Gravitation',
          'Mechanical Properties of Solids',
          'Mechanical Properties of Fluids',
          'Thermodynamics',
          'Kinetic Theory',
          'Oscillations',
          'Waves',
          // 12th
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
      }

      for (String chapter in fullChapters) {
        final chapterClass = chapterToClass[chapter] ?? '11';
        final chapterFile = chapter.toLowerCase().replaceAll(" ", "_");
        final path = 'assets/formulas/$chapterClass/$chapterFile.json';

        print('Loading: $path');
        try {
          final String data = await rootBundle.loadString(path);
          final List<dynamic> jsonData = json.decode(data);
          allQuestions.addAll(jsonData.cast<Map<String, dynamic>>());
        } catch (e) {
          print('Error loading $path: $e');
        }
      }

    } else if (widget.selectedChapter == 'mixed' && widget.selectedChapters != null) {
      for (String chapter in widget.selectedChapters!) {
        final chapterClass = chapterToClass[chapter] ?? '11';
        final chapterFile = chapter.toLowerCase().replaceAll(" ", "_");
        final path = 'assets/formulas/$chapterClass/$chapterFile.json';

        print('Loading: $path');
        try {
          final String data = await rootBundle.loadString(path);
          final List<dynamic> jsonData = json.decode(data);
          allQuestions.addAll(jsonData.cast<Map<String, dynamic>>());
        } catch (e) {
          print('Error loading $path: $e');
        }
      }
    } else {
      final chapterClass = chapterToClass[widget.selectedChapter] ?? '11';
      final chapterFile = widget.selectedChapter.toLowerCase().replaceAll(" ", "_");
      final path = 'assets/formulas/$chapterClass/$chapterFile.json';

      print('Loading: $path');
      try {
        final String data = await rootBundle.loadString(path);
        final List<dynamic> jsonData = json.decode(data);
        allQuestions = jsonData.cast<Map<String, dynamic>>();
      } catch (e) {
        print('Error loading $path: $e');
      }
    }

    allQuestions.shuffle();
    setState(() {
      questions = allQuestions.take(totalQuestions).toList();

    });

    _progressController.reset();
    _progressController.forward();
    print('Loaded ${questions.length} questions');
  }


  // ............. Chunk 4 CHECK ANSWER .............
  Future<void> checkAnswer(String selected) async {
    final question = questions[currentIndex];
    final String correctAnswer = question['answer'];
    //print('DEBUG → MistakeTracker: question="${question['question']}", formula="${question['answer']}", chapter="${question['tags']?['chapter'] ?? ''}"');

    if (selected == correctAnswer) {
      score++;
      // TRACK CORRECT
     // MistakeTrackerService.trackCorrect(
        //userId: 'test_user',  // use real userId when ready
       // questionData: questions[currentIndex],
      //);
    } else if (selected != '') {
      // User clicked wrong answer
      wrongAnswers.add(
        IncorrectAnswer(
          question: question['question'],
          userAnswer: selected,
          correctAnswer: correctAnswer,
          tip: question['tip'] ?? '',
        ),
      );

      // TRACK MISTAKE
      await MistakeTrackerService.trackMistake(
        userId: 'test_user',
        questionData: question,


      );
      //print('Mistake saved for question: ${questions[currentIndex]['question']}');

    } else {
      // User skipped → count as wrong
      wrongAnswers.add(
        IncorrectAnswer(
          question: question['question'],
          userAnswer: '(No Answer)',
          correctAnswer: correctAnswer,
          tip: question['tip'] ?? '',
        ),
      );

      // TRACK MISTAKE
      await MistakeTrackerService.trackMistake(
        userId: 'test_user',
        questionData: {
          'question': question['question'],
          'answer': question['answer'],
          'options': question['options'],
          'chapter': question['tags']?['chapter'] ?? 'Unknown',

        },
      );
      //print('Mistake saved for question: ${questions[currentIndex]['question']}');
    }

    responses.add({
      'question': question['question'],
      'selected': selected == '' ? '(No Answer)' : selected,
      'correct': correctAnswer,
    });

    if (currentIndex < totalQuestions - 1) {
      setState(() {
        currentIndex++;
        selectedOption = null;
        shuffledOptions = [];
      });

      // Restart progress bar for next question
      _progressController.reset();
      _progressController.forward();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            incorrectAnswers: wrongAnswers,
            mode: widget.selectedChapter,
            responses: responses,
          ),
          settings: RouteSettings(arguments: totalQuestions), // pass total qns here
        ),
      );
    }
  }

  // ............. Chunk 5 OPTION COLOR LOGIC .............
  Color getOptionColor(String option) {
    if (selectedOption == null) {
      return Colors.black;
    } else {
      if (option == questions[currentIndex]['answer']) {
        return Colors.green;
      } else if (option == selectedOption) {
        return Colors.red;
      } else {
        return Colors.black;
      }
    }
  }

  // ............. Chunk 6 PROGRESS BAR BUILDER .............
  Widget buildProgressBar() {
    return Row(
      children: List.generate(totalQuestions, (index) {
        double value;
        if (index < currentIndex) {
          value = 1;
        } else if (index == currentIndex) {
          value = _progressAnimation.value;
        } else {
          value = 0;
        }
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.grey.shade800,
              color: Colors.cyanAccent,
              minHeight: 6,
            ),
          ),
        );
      }),
    );
  }

  // ............. Chunk 7 BUILD WIDGET TREE .............
  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final question = questions[currentIndex];
    final List<dynamic> options = question['options'];
    final String tip = question['tip'] ?? '';//........................TIP ADDED
    if (shuffledOptions.isEmpty) {
      shuffledOptions = List<String>.from(options);
      shuffledOptions.shuffle();
    }

    return WillPopScope(
      onWillPop: () async {
        _progressController.stop(); // pause timer

        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
            backgroundColor: Colors.grey[800],
            title: const Text(
              'Exit Solo Play?',textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),

            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancel',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
              TextButton(style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Exit',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
                ),
              ),
            ],
          ),
        );

        if (shouldExit ?? false) {
          await Future.delayed(const Duration(milliseconds: 350));
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SoloModeSelectionScreen()),
          );
          return false; // prevent default back
        }

        _progressController.forward(); // resume timer
        return false; // also handle null or cancel case
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
            backgroundColor: Colors.black,
            title: const Text('Solo Play',
                style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                return buildProgressBar();
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Q${currentIndex + 1} of $totalQuestions',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 10),
            // Keep the question text as normal Text() for proper rendering


        //................DISPLAY QN START...........................
            Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // QUESTION
                    // --- START OF CHANGE ---
                    Math.tex( // Use Math.tex here
                      question['question'],
                      textStyle: const TextStyle(
                        color: Colors.white, // Keep your desired text color
                        fontSize: 18,        // Keep your desired font size
                      ),
                    ),

                const SizedBox(height: 12), // spacing between Qn and options

                // OPTIONS
                ...shuffledOptions.map((option) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.0),
                    child: FormulaOptionButton(
                      text: option,
                      onPressed: selectedOption == null
                          ? () {
                        setState(() {
                          selectedOption = option;
                        });

                        Future.delayed(const Duration(milliseconds: 700), () {
                          checkAnswer(option);
                        });
                      }
                          : () {},
                      color: getOptionColor(option),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),

    ]
        ),
    ),
    ),
    );// WillPopScope
  }
}
///Push1