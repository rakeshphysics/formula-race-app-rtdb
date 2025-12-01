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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../quiz_data_provider.dart';
import 'package:confetti/confetti.dart';

// ............. Chunk 1 SOLO SCREEN WIDGET .............
const Map<String, String> chapterToClass = {
  "Units and Dimensions": "11",
  "Kinematics": "11",
  "Laws of Motion": "11",
  "Circular Motion": "11",
  "Work Power Energy": "11",
  "Center of Mass": "11",
  "Rotation": "11",
  "Gravitation": "11",
  "Elasticity": "11",
  "Fluids": "11",
  "Thermodynamics": "11",
  "Kinetic Theory": "11",
  "Oscillations": "11",
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
  bool showCorrectAnswerOnTimeout = false;
  int _consecutiveCorrectAnswers = 0;

  Future<List<String>> _getSeenQuestionIds(String chapter) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('seen_questions_$chapter') ?? [];
  }

  Future<void> _addSeenQuestionId(String chapter, String questionId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> seenIds = prefs.getStringList('seen_questions_$chapter') ?? [];
    if (!seenIds.contains(questionId)) {
      seenIds.add(questionId);
      await prefs.setStringList('seen_questions_$chapter', seenIds);
    }
  }

  Future<void> _resetSeenQuestions(String chapter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('seen_questions_$chapter');
  }

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
   // print('🤢🤢*** SoloScreen initState called for chapter: ${widget.selectedChapter} ***'); // ADD THIS LINE

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30), // 18s per segment
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
    _confettiController.dispose();
    super.dispose();
  }

  // ............. Chunk 3 LOAD QUESTIONS .............
  Future<void> loadQuestions() async {
    List<Map<String, dynamic>> finalQuestions = [];

    if (widget.selectedChapter == 'full11' ||
        widget.selectedChapter == 'full12' ||
        widget.selectedChapter == 'fullBoth') {
      List<Map<String, dynamic>> allQuestions = [];
      List<String> fullChapters = [];

      if (widget.selectedChapter == 'full11') {
        fullChapters = [
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
        ];

      } else if (widget.selectedChapter == 'full12') {
        fullChapters = [
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

      } else if (widget.selectedChapter == 'fullBoth') {
        fullChapters = [
          // 11th
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
          // 12th
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
          'X Rays'
          'Semiconductors',
        ];

      }

      final quizProvider = Provider.of<QuizDataProvider>(context, listen: false);

      for (String chapter in fullChapters) {
        final chapterFile = chapter.toLowerCase().replaceAll(" ", "_");
        if (quizProvider.allQuizData.containsKey(chapterFile)) {
          allQuestions.addAll(quizProvider.allQuizData[chapterFile].cast<Map<String, dynamic>>());
        }
      }

      // Logic for unique chapters in 'full' modes
      final Set<String> selectedChapters = {};

      Map<String, List<Map<String, dynamic>>> questionsByDifficulty = {
        'easy': allQuestions.where((q) => q['tags']['difficulty'] == 'easy').toList(),
        'medium': allQuestions.where((q) => q['tags']['difficulty'] == 'medium').toList(),
        'god': allQuestions.where((q) => q['tags']['difficulty'] == 'god').toList(),
      };

      void addUniqueQuestion(String difficulty, int count) {
        int addedCount = 0;
        List<Map<String, dynamic>> currentDifficultyQuestions = questionsByDifficulty[difficulty]!;
        currentDifficultyQuestions.shuffle();

        for (int i = 0; i < currentDifficultyQuestions.length && addedCount < count; i++) {
          final question = currentDifficultyQuestions[i];
          final String chapter = question['tags']['chapter'];

          if (!selectedChapters.contains(chapter)) {
            finalQuestions.add(question); // Add to finalQuestions
            selectedChapters.add(chapter);
            addedCount++;
          }
        }
      }

      addUniqueQuestion('easy', 4);
      addUniqueQuestion('medium', 5);
      addUniqueQuestion('god', 1);

      //print('Final Selected Chapters: $selectedChapters');

    } else {
      // If not 'full' mode, call the new function for chapter-wise selection
      finalQuestions = await _loadChapterWiseQuestions();
    }

    //Consolidated Print Statements (ONLY ONE LOCATION)
   // print('--- Selected Questions Chapters (Final List) ---');
    for (var i = 0; i < finalQuestions.length; i++) {
      final question = finalQuestions[i];
      final chapter = question['tags']['chapter'] ?? 'Unknown Chapter';
      final difficulty = question['tags']['difficulty'] ?? 'Unknown Difficulty';
      final questionId = question['id'] ?? 'Unknown ID'; // Correctly accessing the 'id' at the top level
     // print('😄😄Question ${i + 1}: ID - $questionId, Chapter - $chapter, Difficulty - $difficulty');
    }
    //print('------------------------------------------------');
    setState(() {
      questions = finalQuestions;
      currentIndex = 0;
    });

    _progressController.reset();
    _progressController.forward();
  }

// Inside the _SoloScreenState class, replace the previous _loadChapterAndMixedQuestions
  // Inside _SoloScreenState class

// ............. Chunk 3 LOAD QUESTIONS .............
// ... (existing loadQuestions function remains the same, no changes needed there) ...

// Inside the _SoloScreenState class, replace the previous _loadChapterWiseQuestions with this:
  Future<List<Map<String, dynamic>>> _loadChapterWiseQuestions() async {
    List<Map<String, dynamic>> chapterSpecificQuestions = [];

    final quizProvider = Provider.of<QuizDataProvider>(context, listen: false);
    final chapterFile = widget.selectedChapter.toLowerCase().replaceAll(" ", "_");

    if (quizProvider.allQuizData.containsKey(chapterFile)) {
      chapterSpecificQuestions = quizProvider.allQuizData[chapterFile].cast<Map<String, dynamic>>();
    }

    List<String> seenIds = await _getSeenQuestionIds(widget.selectedChapter);
    List<Map<String, dynamic>> unseenQuestions = chapterSpecificQuestions
        .where((q) => !seenIds.contains(q['id']))
        .toList();

    // If all questions have been seen, reset the seen list and use all questions
    if (unseenQuestions.length < totalQuestions) { // totalQuestions is 10
      await _resetSeenQuestions(widget.selectedChapter);
      seenIds = []; // Clear the in-memory seenIds as well
      unseenQuestions = chapterSpecificQuestions; // Use all questions again
    }

    // Now, apply the selection logic for these questions (4 easy, 5 medium, 1 god) from unseenQuestions
    final List<Map<String, dynamic>> selectedQuestionsForMode = [];

    List easy = unseenQuestions.where((q) => q['tags']['difficulty'] == 'easy').toList()..shuffle();
    List medium = unseenQuestions.where((q) => q['tags']['difficulty'] == 'medium').toList()..shuffle();
    List god = unseenQuestions.where((q) => q['tags']['difficulty'] == 'god').toList()..shuffle();

    selectedQuestionsForMode.addAll([
      ...easy.take(4),
      ...medium.take(5),
      ...god.take(1),
    ]);

    // Ensure we don't try to add more questions than available
    while (selectedQuestionsForMode.length < totalQuestions && unseenQuestions.isNotEmpty) {
      // Fallback: If we don't have enough specific difficulty questions,
      // add more from any remaining unseen questions.
      // This is a simple fallback, you might want a more sophisticated strategy.
      List<Map<String, dynamic>> remainingUnseen = unseenQuestions
          .where((q) => !selectedQuestionsForMode.contains(q))
          .toList()
        ..shuffle();
      if (remainingUnseen.isNotEmpty) {
        selectedQuestionsForMode.add(remainingUnseen.removeAt(0));
      } else {
        break; // No more unseen questions to add
      }
    }


    // Add the IDs of the selected questions to the seen list
    for (var q in selectedQuestionsForMode) {
      await _addSeenQuestionId(widget.selectedChapter, q['id']);
    }

    return selectedQuestionsForMode;
  }


  // Inside _SoloScreenState class

// ... existing code ...



// ... rest of _SoloScreenState class ...




  // ............. Chunk 4 CHECK ANSWER .............
  Future<void> checkAnswer(String selected) async {
    final question = questions[currentIndex];
    final String correctAnswer = question['answer'];
    //print('DEBUG → MistakeTracker: question="${question['question']}", formula="${question['answer']}", chapter="${question['tags']?['chapter'] ?? ''}"');

    if (selected == correctAnswer) {
      score++;
      _consecutiveCorrectAnswers++; // Increment counter
      // TRACK CORRECT
     // MistakeTrackerService.trackCorrect(
        //userId: 'test_user',  // use real userId when ready
       // questionData: questions[currentIndex],
      //);
    } else if (selected != '') {
      _consecutiveCorrectAnswers = 0;
      // User clicked wrong answer
      wrongAnswers.add(
        IncorrectAnswer(
          question: question['question'],
          userAnswer: selected,
          correctAnswer: correctAnswer,
          tip: question['tip'] ?? '',
          imagePath: question['image'] ?? '',
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
      _consecutiveCorrectAnswers = 0;
      // User skipped → count as wrong
      wrongAnswers.add(
        IncorrectAnswer(
          question: question['question'],
          userAnswer: '(No Answer)',
          correctAnswer: correctAnswer,
          tip: question['tip'] ?? '',
          imagePath: question['image'] ?? '',
        ),
      );

      setState(() {
        showCorrectAnswerOnTimeout = true;
      });

      await Future.delayed(const Duration(milliseconds: 700));

      setState(() {
        showCorrectAnswerOnTimeout = false;
      });

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

    setState(() {
      selectedOption = selected;
    });

// Check for confetti condition and apply delay
    if (_consecutiveCorrectAnswers >= 6) {
      _confettiController.play();
      await Future.delayed(const Duration(seconds: 1)); // Wait 2 seconds for confetti
      _confettiController.stop();
      _consecutiveCorrectAnswers = 0;
    } else {
      // Standard delay to show the answer before moving on
      await Future.delayed(const Duration(milliseconds: 400));
    }

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
      if (showCorrectAnswerOnTimeout && option == questions[currentIndex]['answer']) {
        return Colors.green; // Highlight correct answer on timeout
      }
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
    //print('😇😇--- SoloScreen build called for chapter: ${widget.selectedChapter}, currentIndex: $currentIndex ---'); // ADD THIS LINE
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
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
            backgroundColor: Color(0xFF000000),
            title: Text(
              'Exit Solo Play?',textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white,fontSize: screenWidth * 0.042),
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
                  padding:  EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.013),
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child:  Text(
                  'Cancel',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth*0.04,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.025),
              TextButton(style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(color: Color(0xFF006C7A), width: 1.2),
                ),
                padding:  EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.013),
              ),
                onPressed: () => Navigator.of(context).pop(true),
                child:  Text(
                  'Exit',
                  textAlign: TextAlign.center,
                  style: TextStyle( fontSize: screenWidth*0.04, fontWeight: FontWeight.normal),
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



    child: Stack(
    alignment: Alignment.topCenter,
      children:[
       Scaffold(
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
            padding: EdgeInsets.all(screenWidth*0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                SizedBox(height: screenWidth * 0.04),
                AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) => buildProgressBar(),
                ),
                SizedBox(height: screenWidth * 0.025),
                Text(
                  'Q${currentIndex + 1} of $totalQuestions',
                  style:  TextStyle(color: Colors.white, fontSize: screenWidth * 0.044),
                ),
               // SizedBox(height: screenWidth * 0.02),

                // --- Question Block (Fixed) ---
                Html(
                  data: question['question'],
                  style: {
                    "body": Style(
                      //fontSize: FontSize(16),
                      fontSize: FontSize(screenWidth * 0.04),
                      fontWeight: FontWeight.normal,
                      color: Colors.white,
                      fontFamily: GoogleFonts.poppins().fontFamily,
                    ),
                  },
                ),
                SizedBox(height: screenWidth * 0.03),

                if (question['image'] != null && question['image'] != "")
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 0),
                    child: Center(
                      child: SizedBox(
                        width: screenWidth * 0.6,
                        height: (screenWidth * 0.6) / 1.5, // Calculated height to maintain aspect ratio
                        child: Image.asset(
                          question['image'],
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  )
                else
                // ✨ CHANGE THIS LINE: If no image, use SizedBox.shrink() to take no space ✨
                  const SizedBox.shrink(), // No image, no gap!

                SizedBox(height: screenWidth * 0.03),


                // --- Scrollable Options ---
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: shuffledOptions.map((option) {
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            vertical:  screenHeight * 0.001,
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
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: 20,
          emissionFrequency: 0.02,
          gravity: 0.3,
          shouldLoop: false,
          colors: const [
            Colors.cyanAccent
          ],
        ),],),
    );// WillPopScope
  }
}
///Push1