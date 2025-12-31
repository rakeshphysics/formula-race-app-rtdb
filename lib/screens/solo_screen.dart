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
import '../../services/database_helper.dart';
import '../../models/practice_attempt.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:formularacing/widgets/rive_viewer.dart';

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
  final String game_session_id;
  final String subject;
  const SoloScreen({super.key, required this.selectedChapter,this.selectedChapters,required this.userId,required this.game_session_id,this.subject = 'Physics',});

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
    //_confettiController = ConfettiController(duration: const Duration(seconds: 2));
   // print('🤢🤢*** SoloScreen initState called for chapter: ${widget.selectedChapter} ***'); // ADD THIS LINE

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60), // 18s per segment
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
    //_confettiController.dispose();
    super.dispose();
  }

  // ............. Chunk 3 LOAD QUESTIONS .............
  // Future<void> loadQuestions() async {
  //   List<Map<String, dynamic>> finalQuestions = [];
  //
  //   if (widget.selectedChapter == 'full11' ||
  //       widget.selectedChapter == 'full12' ||
  //       widget.selectedChapter == 'fullBoth') {
  //     List<Map<String, dynamic>> allQuestions = [];
  //     List<String> fullChapters = [];
  //
  //     if (widget.selectedChapter == 'full11') {
  //       fullChapters = [
  //         'Vectors',
  //         'Units and Dimensions',
  //         'Kinematics',
  //         'Laws of Motion',
  //         'Circular Motion',
  //         'Work Power Energy',
  //         'Center of Mass',
  //         'Rotational Motion',
  //         'Gravitation',
  //         'Elasticity',
  //         'Fluids',
  //         'Thermodynamics',
  //         'Kinetic Theory',
  //         'SHM',
  //         'Waves',
  //       ];
  //
  //     } else if (widget.selectedChapter == 'full12') {
  //       fullChapters = [
  //         'Electrostatics',
  //         'Capacitors',
  //         'Current Electricity',
  //         'Magnetism',
  //         'EMI',
  //         'AC',
  //         'EM Waves',
  //         'Ray Optics',
  //         'Wave Optics',
  //         'Dual Nature of Light',
  //         'Atoms',
  //         'Nuclei',
  //         'X Rays',
  //         'Semiconductors',
  //       ];
  //
  //     } else if (widget.selectedChapter == 'fullBoth') {
  //       fullChapters = [
  //         // 11th
  //         'Vectors',
  //         'Units and Dimensions',
  //         'Kinematics',
  //         'Laws of Motion',
  //         'Circular Motion',
  //         'Work Power Energy',
  //         'Center of Mass',
  //         'Rotational Motion',
  //         'Gravitation',
  //         'Elasticity',
  //         'Fluids',
  //         'Thermodynamics',
  //         'Kinetic Theory',
  //         'SHM',
  //         'Waves',
  //         // 12th
  //         'Electrostatics',
  //         'Capacitors',
  //         'Current Electricity',
  //         'Magnetism',
  //         'EMI',
  //         'AC',
  //         'EM Waves',
  //         'Ray Optics',
  //         'Wave Optics',
  //         'Dual Nature of Light',
  //         'Atoms',
  //         'Nuclei',
  //         'X Rays'
  //         'Semiconductors',
  //       ];
  //
  //     }
  //
  //     final quizProvider = Provider.of<QuizDataProvider>(context, listen: false);
  //
  //     for (String chapter in fullChapters) {
  //       final chapterFile = chapter.toLowerCase().replaceAll(" ", "_");
  //       if (quizProvider.allQuizData.containsKey(chapterFile)) {
  //         allQuestions.addAll(quizProvider.allQuizData[chapterFile].cast<Map<String, dynamic>>());
  //       }
  //     }
  //
  //     // Logic for unique chapters in 'full' modes
  //     final Set<String> selectedChapters = {};
  //
  //     Map<String, List<Map<String, dynamic>>> questionsByDifficulty = {
  //       'easy': allQuestions.where((q) => q['tags']['difficulty'] == 'easy').toList(),
  //       'medium': allQuestions.where((q) => q['tags']['difficulty'] == 'medium').toList(),
  //       'god': allQuestions.where((q) => q['tags']['difficulty'] == 'god').toList(),
  //     };
  //
  //     void addUniqueQuestion(String difficulty, int count) {
  //       int addedCount = 0;
  //       List<Map<String, dynamic>> currentDifficultyQuestions = questionsByDifficulty[difficulty]!;
  //       currentDifficultyQuestions.shuffle();
  //
  //       for (int i = 0; i < currentDifficultyQuestions.length && addedCount < count; i++) {
  //         final question = currentDifficultyQuestions[i];
  //         final String chapter = question['tags']['chapter'];
  //
  //         if (!selectedChapters.contains(chapter)) {
  //           finalQuestions.add(question); // Add to finalQuestions
  //           selectedChapters.add(chapter);
  //           addedCount++;
  //         }
  //       }
  //     }
  //
  //     addUniqueQuestion('easy', 4);
  //     addUniqueQuestion('medium', 5);
  //     addUniqueQuestion('god', 1);
  //
  //     //print('Final Selected Chapters: $selectedChapters');
  //
  //   } else {
  //     // If not 'full' mode, call the new function for chapter-wise selection
  //     finalQuestions = await _loadChapterWiseQuestions();
  //   }
  //
  //   //Consolidated Print Statements (ONLY ONE LOCATION)
  //  // print('--- Selected Questions Chapters (Final List) ---');
  //   for (var i = 0; i < finalQuestions.length; i++) {
  //     final question = finalQuestions[i];
  //     final chapter = question['tags']['chapter'] ?? 'Unknown Chapter';
  //     final difficulty = question['tags']['difficulty'] ?? 'Unknown Difficulty';
  //     final questionId = question['id'] ?? 'Unknown ID'; // Correctly accessing the 'id' at the top level
  //    // print('😄😄Question ${i + 1}: ID - $questionId, Chapter - $chapter, Difficulty - $difficulty');
  //   }
  //   //print('------------------------------------------------');
  //   setState(() {
  //     questions = finalQuestions;
  //     currentIndex = 0;
  //   });
  //
  //   _progressController.reset();
  //   _progressController.forward();
  // }

  // ............. Chunk 3 LOAD QUESTIONS .............
  // ............. Chunk 3 LOAD QUESTIONS .............
  Future<void> loadQuestions() async {
    List<Map<String, dynamic>> finalQuestions = [];

    // 1. Define the Syllabus for all subjects
    final Map<String, Map<String, List<String>>> subjectSyllabus = {
      'Physics': {
        '11': [
          'Vectors', 'Units and Dimensions', 'Kinematics', 'Laws of Motion',
          'Circular Motion', 'Work Power Energy', 'Center of Mass', 'Rotational Motion',
          'Gravitation', 'Elasticity', 'Fluids', 'Thermodynamics', 'Kinetic Theory',
          'SHM', 'Waves'
        ],
        '12': [
          'Electrostatics', 'Capacitors', 'Current Electricity', 'Magnetism',
          'EMI', 'AC', 'EM Waves', 'Ray Optics', 'Wave Optics',
          'Dual Nature of Light', 'Atoms', 'Nuclei', 'X Rays', 'Semiconductors'
        ],
      },
      'Chemistry': {
        '11': ['Chemical Equilibrium'], // Add more chapters here
        '12': ['Solid State'],          // Add more chapters here
      },
      'Maths': {
        '11': ['Ellipse'],              // Add more chapters here
        '12': ['3D Geometry'],          // Add more chapters here
      },
    };

    if (widget.selectedChapter == 'full11' ||
        widget.selectedChapter == 'full12' ||
        widget.selectedChapter == 'fullBoth') {

      List<Map<String, dynamic>> allQuestions = [];
      List<String> fullChapters = [];

      // 2. Get the syllabus for the selected subject
      final currentSyllabus = subjectSyllabus[widget.subject] ?? subjectSyllabus['Physics']!;

      // 3. Select chapters based on mode
      if (widget.selectedChapter == 'full11') {
        fullChapters.addAll(currentSyllabus['11'] ?? []);
      } else if (widget.selectedChapter == 'full12') {
        fullChapters.addAll(currentSyllabus['12'] ?? []);
      } else if (widget.selectedChapter == 'fullBoth') {
        fullChapters.addAll(currentSyllabus['11'] ?? []);
        fullChapters.addAll(currentSyllabus['12'] ?? []);
      }

      final quizProvider = Provider.of<QuizDataProvider>(context, listen: false);

      for (String chapter in fullChapters) {
        final chapterFile = chapter.toLowerCase().replaceAll(" ", "_");
        if (quizProvider.allQuizData.containsKey(chapterFile)) {
          allQuestions.addAll(quizProvider.allQuizData[chapterFile].cast<Map<String, dynamic>>());
        }
      }

      // 4. Categorize by difficulty
      Map<String, List<Map<String, dynamic>>> questionsByDifficulty = {
        'easy': allQuestions.where((q) => q['tags']['difficulty'] == 'easy').toList(),
        'medium': allQuestions.where((q) => q['tags']['difficulty'] == 'medium').toList(),
        'god': allQuestions.where((q) => q['tags']['difficulty'] == 'god').toList(),
      };

      // Shuffle everything initially
      questionsByDifficulty['easy']!.shuffle();
      questionsByDifficulty['medium']!.shuffle();
      questionsByDifficulty['god']!.shuffle();

      final Set<String> usedQuestionIds = {};
      final Set<String> usedChapters = {};

      // Helper to add questions safely
      void fillQuestions(String difficulty, int targetCount) {
        List<Map<String, dynamic>> pool = questionsByDifficulty[difficulty] ?? [];

        // Phase 1: Try to find questions from UNIQUE chapters
        for (var question in pool) {
          if (finalQuestions.length >= (finalQuestions.length + targetCount)) break; // Safety break

          String qId = question['id'];
          String chapter = question['tags']['chapter'];

          if (!usedQuestionIds.contains(qId) && !usedChapters.contains(chapter)) {
            finalQuestions.add(question);
            usedQuestionIds.add(qId);
            usedChapters.add(chapter);
          }

          // Stop if we reached the target for this difficulty block
          int currentCountForDiff = finalQuestions.where((q) => q['tags']['difficulty'] == difficulty).length;
          if (currentCountForDiff >= targetCount) return;
        }

        // Phase 2: If we still need questions, RELAX the chapter constraint
        // (This fixes the issue for Chemistry/Maths where chapters are few)
        for (var question in pool) {
          String qId = question['id'];

          // Only check if ID is unique, ignore chapter uniqueness now
          if (!usedQuestionIds.contains(qId)) {
            finalQuestions.add(question);
            usedQuestionIds.add(qId);
          }

          int currentCountForDiff = finalQuestions.where((q) => q['tags']['difficulty'] == difficulty).length;
          if (currentCountForDiff >= targetCount) return;
        }
      }

      // Try to fill 4 Easy, 5 Medium, 1 God
      fillQuestions('easy', 4);
      fillQuestions('medium', 5);
      fillQuestions('god', 1);

      // Phase 3: Emergency Fill
      // If we still don't have 10 questions (e.g., no God questions existed),
      // fill the remaining slots with ANY available question from the pool.
      if (finalQuestions.length < totalQuestions) {
        List<Map<String, dynamic>> remainingPool = allQuestions
            .where((q) => !usedQuestionIds.contains(q['id']))
            .toList();
        remainingPool.shuffle();

        while (finalQuestions.length < totalQuestions && remainingPool.isNotEmpty) {
          finalQuestions.add(remainingPool.removeAt(0));
        }
      }

    } else {
      // If not 'full' mode, call the new function for chapter-wise selection
      finalQuestions = await _loadChapterWiseQuestions();
    }

    // If we STILL have 0 questions (e.g., empty database for subject), handle gracefully
    if (finalQuestions.isEmpty) {
      // You might want to show an alert dialog here or pop back
      // For now, we just avoid the crash
      print("⚠️ No questions found for this selection!");
    }

    setState(() {
      questions = finalQuestions;
      currentIndex = 0;
    });

    if (questions.isNotEmpty) {
      _progressController.reset();
      _progressController.forward();
    }
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
//   Future<void> checkAnswer(String selected) async {
//     final question = questions[currentIndex];
//     final String correctAnswer = question['answer'];
//     //print('DEBUG → MistakeTracker: question="${question['question']}", formula="${question['answer']}", chapter="${question['tags']?['chapter'] ?? ''}"');
//
//     final bool wasCorrect = selected == correctAnswer;
//
//     final attempt = PracticeAttempt(
//       userId: widget.userId,
//       questionId: question['id'],
//       wasCorrect: wasCorrect, // This is the key part
//       topic: question['tags']['chapter'] ?? 'Unknown',
//       timestamp: DateTime.now(),
//     );
//     await DatabaseHelper.instance.addAttempt(attempt);
//     //await DatabaseHelper.instance.printAllAttempts();
//
//     if (selected == correctAnswer) {
//       score++;
//       _consecutiveCorrectAnswers++; // Increment counter
//       // TRACK CORRECT
//      // MistakeTrackerService.trackCorrect(
//         //userId: 'test_user',  // use real userId when ready
//        // questionData: questions[currentIndex],
//       //);
//     } else if (selected != '') {
//       _consecutiveCorrectAnswers = 0;
//       // User clicked wrong answer
//       wrongAnswers.add(
//         IncorrectAnswer(
//           question: question['question'],
//           userAnswer: selected,
//           correctAnswer: correctAnswer,
//           tip: question['tip'] ?? '',
//           imagePath: question['image'] ?? '',
//         ),
//       );
//
//       // TRACK MISTAKE
//       await MistakeTrackerService.trackMistake(
//         userId: 'test_user',
//         questionData: {
//           ...question,
//           'answer': question['answer'], //
//           'image': question['image'] ?? '',
//           'tags': {
//             ...?question['tags'],
//             'chapter': question['tags']?['chapter'] ?? 'misc',
//             'difficulty': question['tags']?['difficulty'] ?? '',
//             'class': question['tags']?['class'] ?? '',
//           },
//         },
//       );
//
//
//
//       //print('🔍 Saving mistake: ${question['question']} → image: ${question['image']}');
//
//       //print('Mistake saved for question: ${questions[currentIndex]['question']}');
//
//     } else {
//       _consecutiveCorrectAnswers = 0;
//       // User skipped → count as wrong
//       wrongAnswers.add(
//         IncorrectAnswer(
//           question: question['question'],
//           userAnswer: '(No Answer)',
//           correctAnswer: correctAnswer,
//           tip: question['tip'] ?? '',
//           imagePath: question['image'] ?? '',
//         ),
//       );
//
//       setState(() {
//         showCorrectAnswerOnTimeout = true;
//       });
//
//       await Future.delayed(const Duration(milliseconds: 700));
//
//       setState(() {
//         showCorrectAnswerOnTimeout = false;
//       });
//
//       // TRACK MISTAKE
//       await MistakeTrackerService.trackMistake(
//         userId: 'test_user',
//         questionData: {
//           'question': question['question'],
//           'answer': question['answer'],
//           'options': question['options'],
//           'chapter': question['tags']?['chapter'] ?? 'Unknown',
//
//         },
//       );
//       //print('Mistake saved for question: ${questions[currentIndex]['question']}');
//     }
//
//     responses.add({
//       'question': question['question'],
//       'selected': selected == '' ? '(No Answer)' : selected,
//       'correct': correctAnswer,
//     });
//
//     setState(() {
//       selectedOption = selected;
//     });
//
// // Check for confetti condition and apply delay
//     if (_consecutiveCorrectAnswers >= 6) {
//      // _confettiController.play();
//       await Future.delayed(const Duration(seconds: 1)); // Wait 2 seconds for confetti
//       //_confettiController.stop();
//       _consecutiveCorrectAnswers = 0;
//     } else {
//       // Standard delay to show the answer before moving on
//       await Future.delayed(const Duration(milliseconds: 400));
//     }
//
//     if (currentIndex < totalQuestions - 1) {
//       setState(() {
//         currentIndex++;
//         selectedOption = null;
//         shuffledOptions = [];
//       });
//
//       // Restart progress bar for next question
//       _progressController.reset();
//       _progressController.forward();
//     } else {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => ResultScreen(
//             incorrectAnswers: wrongAnswers,
//             mode: widget.selectedChapter,
//             responses: responses,
//           ),
//           settings: RouteSettings(arguments: totalQuestions), // pass total qns here
//         ),
//       );
//     }
//   }


  // ............. Chunk 4 CHECK ANSWER .............
  Future<void> checkAnswer(String selected) async {
    // Stop the timer as soon as an answer is processed (either by tap or timeout)
    _progressController.stop();

    final question = questions[currentIndex];
    final String correctAnswer = question['answer'];
    final bool wasCorrect = selected == correctAnswer;
    final bool timedOut = selected.isEmpty;

    // --- State Update for UI ---
    // This single setState call now handles all UI changes for showing the result.
    setState(() {
      // If timed out, we need to pretend the correct answer was selected for UI purposes.
      // Otherwise, use the actual selection. This fixes the border color issue.
      selectedOption = timedOut ? correctAnswer : selected;

      // This flag is now redundant because we handle the timeout case by setting selectedOption,
      // but we will keep the logic clean.
      if (timedOut) {
        showCorrectAnswerOnTimeout = true;
      }
    });

    // --- Sound and Database Logic ---
    final attempt = PracticeAttempt(
      userId: widget.userId,
      questionId: question['id'],
      wasCorrect: wasCorrect,
      topic: question['tags']['chapter'] ?? 'Unknown',
      timestamp: DateTime.now(),
      gameSessionId: widget.game_session_id,
    );
    await DatabaseHelper.instance.addAttempt(attempt);

    if (wasCorrect) {
      score++;
      _consecutiveCorrectAnswers++;
    } else {
      _consecutiveCorrectAnswers = 0;
      wrongAnswers.add(
        IncorrectAnswer(
          question: question['question'],
          userAnswer: timedOut ? '(No Answer)' : selected,
          correctAnswer: correctAnswer,
          tip: question['tip'] ?? '',
          imagePath: question['image'] ?? '',
        ),
      );

      // TRACK MISTAKE (for both wrong answers and timeouts)
      await MistakeTrackerService.trackMistake(
        userId: 'test_user',
        questionData: {
          ...question,
          'answer': question['answer'],
          'image': question['image'] ?? '',
          'tags': {
            ...?question['tags'],
            'chapter': question['tags']?['chapter'] ?? 'misc',
            'difficulty': question['tags']?['difficulty'] ?? '',
            'class': question['tags']?['class'] ?? '',
          },
        },
      );
    }

    responses.add({
      'question': question['question'],
      'selected': timedOut ? '(No Answer)' : selected,
      'correct': correctAnswer,
    });

    // --- Controlled Delay and Transition ---
    // A single, clear delay to show the result before moving on.
    // Increased slightly to make the answer review clear.
    await Future.delayed(const Duration(milliseconds: 900));

    // --- Move to Next Question or Results ---
    if (currentIndex < totalQuestions - 1) {
      setState(() {
        currentIndex++;
        selectedOption = null; // Reset for the new question
        shuffledOptions = [];
        showCorrectAnswerOnTimeout = false; // Reset the timeout flag
      });
      _progressController.reset();
      _progressController.forward();
    } else {
      // Use pushReplacement to prevent user from going back to the quiz
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            incorrectAnswers: wrongAnswers,
            mode: widget.selectedChapter,
            responses: responses,
          ),
          settings: RouteSettings(arguments: totalQuestions),
        ),
      );
    }
  }
  // ............. Chunk 5 OPTION COLOR LOGIC .............
  Color getOptionColor(String option) {
    if (selectedOption == null) {
      if (showCorrectAnswerOnTimeout && option == questions[currentIndex]['answer']) {
        return const Color(0xCC4CAF50); // Highlight correct answer on timeout
      }
      return Colors.grey[900]!;
    } else {
      if (option == questions[currentIndex]['answer']) {
        return const Color(0x994CAF50);
      } else if (option == selectedOption) {
        //return Colors.red;
        return const Color(0x99F44336);
      } else {
        return Colors.grey[900]!; ;
      }
    }
  }

  // Add this function right after getOptionColor
  Color getBorderColor(String option) {
    if (selectedOption == null) {
      // Default border color
      return Colors.grey.shade700;
    }
    if (option == questions[currentIndex]['answer']) {
      // Correct answer border color - More vibrant green
      return Colors.greenAccent[400]!;
    }
    if (option == selectedOption) {
      // Selected incorrect answer border color - More vibrant red
      return Colors.redAccent;
    }
    // Border color for other non-selected options
    return Colors.grey.shade700;
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
              color: const Color(0xD918FFFF),
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
              style: TextStyle(color: const Color(0xD9FFFFFF),fontSize: screenWidth * 0.042),
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
                  style: TextStyle(color: const Color(0xD9FFFFFF),
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
                  style: TextStyle( color: const Color(0xD9FFFFFF),fontSize: screenWidth*0.04, fontWeight: FontWeight.normal),
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
                  style:  TextStyle(color: const Color(0xD9FFFFFF), fontSize: screenWidth * 0.044),
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
                      color: const Color(0xD9FFFFFF),
                      fontFamily: GoogleFonts.poppins().fontFamily,
                    ),
                  },
                ),
                SizedBox(height: screenWidth * 0.03),

                // if (question['image'] != null && question['image'] != "")
                //   Container(
                //     margin: const EdgeInsets.symmetric(vertical: 0),
                //     child: Center(
                //       child: SizedBox(
                //         width: screenWidth * 0.6,
                //         height: (screenWidth * 0.6) / 1.5, // Calculated height to maintain aspect ratio
                //         child: Image.asset(
                //           question['image'],
                //           fit: BoxFit.contain,
                //         ),
                //       ),
                //     ),
                //   )
///////  SVG NEW CODE START....................................
//                   Container(
//                     margin: const EdgeInsets.symmetric(vertical: 0),
//                     child: Center(
//                       child: SizedBox(
//                         width: screenWidth * 0.6,
//                         height: (screenWidth * 0.6) / 1.5, // Maintain the same aspect ratio
//                         child: Opacity(
//                           opacity: 0.85, // Apply 85% opacity
//                           child: SvgPicture.asset(
//                             question['image'], // Directly use the .svg path from your JSON
//                             fit: BoxFit.contain,
//                             // This makes the SVG's vector shapes white.
//                             // Crucial for visibility on a dark theme.
//                             //colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
//                           ),
//                         ),
//                       ),
//                     ),
//                   )

                // if (question['image'] != null && question['image'] != "")
                //   Container(
                //     margin: const EdgeInsets.symmetric(vertical: 0),
                //     child: Center(
                //       child: SizedBox(
                //         width: screenWidth * 0.6,
                //         height: (screenWidth * 0.6) /
                //             1.5, // Calculated height to maintain aspect ratio
                //         child: question['image'].endsWith('.svg')
                //             ? Opacity(
                //           opacity: 0.85, // Apply 85% opacity
                //           child: SvgPicture.asset(
                //             question['image'], // Directly use the .svg path
                //             fit: BoxFit.contain,
                //             // The colorFilter below is useful for making SVGs visible on dark themes
                //             // by coloring their vector shapes. Uncomment if your SVGs are not visible.
                //             // colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                //           ),
                //         )
                //             : Image.asset(
                //           question['image'], // Use for .png, .jpg, etc.
                //           fit: BoxFit.contain,
                //         ),
                //       ),
                //     ),
                //   )
                if (question['image'] != null && question['image'] != "")
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 0),
                    child: Center(
                      child: SizedBox(
                        // WIDTH LOGIC
                        width: question['image'].endsWith('.glb')
                            ? screenWidth * 0.65 // 3D models often need more width
                            : question['image'].endsWith('.riv')
                            ? screenWidth * 0.65
                            : screenWidth * 0.62,

                        // HEIGHT LOGIC
                        height: question['image'].endsWith('.glb')
                            ? screenWidth * 0.65 // Square aspect for 3D usually works best
                            : question['image'].endsWith('.riv')
                            ? (screenWidth * 0.65) / 1.5
                            : (screenWidth * 0.62) / 1.5,

                        child: question['image'].endsWith('.svg')
                            ? Opacity(
                          opacity: 0.85,
                          child: SvgPicture.asset(
                            question['image'],
                            fit: BoxFit.contain,
                          ),
                        )
                            : question['image'].endsWith('.glb')
                            ? ModelViewer(
                          key: ValueKey(question['image']),
                          // If your JSON has "assets/..." use question['image']
                          // If your JSON has just "file.glb", use 'assets/${question['image']}'
                          src: question['image'],
                          backgroundColor: Colors.transparent,
                          alt: "A 3D model",
                          ar: false,
                          autoRotate: true,
                          disableZoom: false,
                          disablePan: true,
                          cameraControls: true,
                          interactionPrompt: InteractionPrompt.none,
                          shadowIntensity: 0,
                          autoPlay: true,
                        )
                            : question['image'].endsWith('.riv')
                            ? Opacity(
                          opacity: 0.8,
                          child: FormulaRiveViewer(
                            key: ValueKey(question['image']),
                            src: question['image'],
                          ),
                        )
                            : Image.asset(
                          question['image'],
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  )

///////  SVG NEW CODE END....................................
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
                        final questionId = questions[currentIndex]['id'] ?? currentIndex;
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            vertical:  screenHeight * 0.001,
                          ),
                          child: FormulaOptionButton(
                            key: ValueKey('$questionId-$option'),
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
                            borderColor: getBorderColor(option),
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
        // ConfettiWidget(
        //   confettiController: _confettiController,
        //   blastDirectionality: BlastDirectionality.explosive,
        //   numberOfParticles: 20,
        //   emissionFrequency: 0.02,
        //   gravity: 0.3,
        //   shouldLoop: false,
        //   colors: const [
        //     Colors.cyanAccent
        //   ],
        // ),
       ],),
    );// WillPopScope
  }
}
///Push1