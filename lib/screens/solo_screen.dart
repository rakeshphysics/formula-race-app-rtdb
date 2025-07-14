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
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';
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
  "Fluids": "11",
  "Thermodynamics": "11",
  "Kinetic Theory": "11",
  "Oscillations": "11",
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
};

class SoloScreen extends StatefulWidget {
  final String userId;
  final String selectedChapter;
  final List<String>? selectedChapters;
  const SoloScreen({super.key, required this.selectedChapter,this.selectedChapters,required this.userId});

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
      duration: const Duration(seconds: 18), // 18s per segment
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


    List<Map<String, dynamic>> allQuestions = [];

    if (widget.selectedChapter == 'full11' ||
        widget.selectedChapter == 'full12' ||
        widget.selectedChapter == 'fullBoth') {

     // print('Handling full mode: ${widget.selectedChapter}');

      List<String> fullChapters = [];

     if (widget.selectedChapter == 'full11') {
        fullChapters = [
          'Vectors'
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
        ];
      }
    else if (widget.selectedChapter == 'full12') {
        fullChapters = [
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
      } else if (widget.selectedChapter == 'fullBoth') {
        fullChapters = [
          // 11th
          'Vectors'
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
          // 12th
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
      }

      for (String chapter in fullChapters) {
        final chapterClass = chapterToClass[chapter] ?? '11';
        final chapterFile = chapter.toLowerCase().replaceAll(" ", "_");
        final path = 'assets/formulas/$chapterClass/$chapterFile.json';

       // print('Loading: $path');
        try {
          final String data = await rootBundle.loadString(path);
          final List<dynamic> jsonData = json.decode(data);
          allQuestions.addAll(jsonData.cast<Map<String, dynamic>>());
         // print('DEBUG: Loaded ${allQuestions.length} questions');
          if (allQuestions.isNotEmpty) {
          //  print('DEBUG: First question image = ${allQuestions[0]['image']}');
          }
        } catch (e) {
         // print('Error loading $path: $e');
        }
      }

    } else if (widget.selectedChapter == 'mixed' && widget.selectedChapters != null) {
      for (String chapter in widget.selectedChapters!) {
        final chapterClass = chapterToClass[chapter] ?? '11';
        final chapterFile = chapter.toLowerCase().replaceAll(" ", "_");
        final path = 'assets/formulas/$chapterClass/$chapterFile.json';

       // print('Loading: $path');
        try {
          final String data = await rootBundle.loadString(path);
          final List<dynamic> jsonData = json.decode(data);
          allQuestions.addAll(jsonData.cast<Map<String, dynamic>>());
        } catch (e) {
        //  print('Error loading $path: $e');
        }
      }
    } else {
      final chapterClass = chapterToClass[widget.selectedChapter] ?? '11';
      final chapterFile = widget.selectedChapter.toLowerCase().replaceAll(" ", "_");
      final path = 'assets/formulas/$chapterClass/$chapterFile.json';

     // print('Loading: $path');
      try {
        final String data = await rootBundle.loadString(path);
        final List<dynamic> jsonData = json.decode(data);
        allQuestions = jsonData.cast<Map<String, dynamic>>();
      } catch (e) {
       // print('Error loading $path: $e');
      }
    }

    List easy = allQuestions.where((q) => q['tags']['difficulty'] == 'easy').toList();
    List medium = allQuestions.where((q) => q['tags']['difficulty'] == 'medium').toList();
    List god = allQuestions.where((q) => q['tags']['difficulty'] == 'god').toList();

    easy.shuffle();
    medium.shuffle();
    god.shuffle();

    final List<Map<String, dynamic>> selectedQuestions = [
      ...easy.take(4),
      ...medium.take(5),
      ...god.take(1),
    ];

    setState(() {
      questions = selectedQuestions;
      currentIndex = 0;
    });

    _progressController.reset();
    _progressController.forward();
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
        questionData: {
          ...question,
          'answer': question['answer'], //
          'image': question['image'] ?? '',
          'tags': {
            ...?question['tags'],
            'chapter': question['tags']?['chapter'] ?? 'misc',
            'difficulty': question['tags']?['difficulty'] ?? '',
            'class': question['tags']?['class'] ?? '',
          },
        },
      );



      //print('🔍 Saving mistake: ${question['question']} → image: ${question['image']}');

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
   // print('DEBUG: Building question index $currentIndex');
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
            side: BorderSide(color: Colors.cyan, width: 1.2),
          ),
            backgroundColor: Color(0x88000000),
            title: const Text(
              'Exit Solo Play?',textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
            actionsAlignment: MainAxisAlignment.center,

            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(color: Color(0xFF006C7A), width: 1.2),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancel',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(color: Color(0xFF006C7A), width: 1.2),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Exit',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.normal),
                ),
              ),
            ],
          ),
        );

        if (shouldExit ?? false) {
          await Future.delayed(const Duration(milliseconds: 350));
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SoloModeSelectionScreen(userId: widget.userId)),
          );
          return false; // prevent default back
        }

        _progressController.forward(); // resume timer
        return false; // also handle null or cancel case
      },



      child: Scaffold(
        backgroundColor: Colors.black,
        //appBar: AppBar(
        //    backgroundColor: Colors.black,
        //    title: const Text('Solo Play',
         //       style: TextStyle(color: Colors.white)),
       // iconTheme: const IconThemeData(color: Colors.white),
    //  ),


        body: SafeArea(
          top: true,
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) => buildProgressBar(),
                ),
                const SizedBox(height: 10),
                Text(
                  'Q${currentIndex + 1} of $totalQuestions',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 10),

                // --- Question Block (Fixed) ---
                Html(
                  data: question['question'],
                  style: {
                    "body": Style(
                      fontSize: FontSize(18),
                      fontWeight: FontWeight.normal,
                      color: Colors.white,
                      fontFamily: GoogleFonts.poppins().fontFamily,
                    ),
                  },
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.015, // ~1.5% of screen height
                ),

                if (question['image'] != "")
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 0),
                    child:Center(
                    child: Image.asset(
                      question['image'],
                      width: MediaQuery.of(context).size.width * 0.6,
                      fit: BoxFit.contain,
                    ),
                    ),
                  ),

                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.015, // ~1.5% of screen height
                ),


                // --- Scrollable Options ---
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: shuffledOptions.map((option) {
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: MediaQuery.of(context).size.height * 0.001,
                          ),
                          child: FormulaOptionButton(
                            text: option,
                            onPressed: selectedOption == null
                                ? () {
                              setState(() {
                                selectedOption = option;
                              });
                              if (option == question['answer']) {
                                audioPlayer.play(AssetSource('sounds/correct.mp3'));
                              } else {
                                audioPlayer.play(AssetSource('sounds/wrong.mp3'));
                              }
                              Future.delayed(const Duration(milliseconds: 700), () {
                                checkAnswer(option);
                              });
                            }
                                : () {},
                            color: getOptionColor(option),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),

      ),
    );// WillPopScope
  }
}
///Push1