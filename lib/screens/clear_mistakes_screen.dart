// clear_mistakes_screen.dart
// ------------------------------------------------------
// Solo mode but simplified — only for clearing mistakes
// Loads 5 questions from local mistake tracker JSON
// Tracks resolvedCount and returns it to AITrackerScreen
// ------------------------------------------------------

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import '../../services/mistake_tracker_service.dart';
import '../../models/incorrect_answer_model.dart';

class ClearMistakesScreen extends StatefulWidget {
  const ClearMistakesScreen({super.key});

  @override
  State<ClearMistakesScreen> createState() => _ClearMistakesScreenState();
}

class _ClearMistakesScreenState extends State<ClearMistakesScreen> with SingleTickerProviderStateMixin {
  //final int totalQuestions = 5;

  List<Map<String, dynamic>> questions = [];
  int currentIndex = 0;
  int resolvedCount = 0;
  List<String> shuffledOptions = [];
  String? selectedOption;
  List<IncorrectAnswer> wrongAnswers = [];
  final AudioPlayer audioPlayer = AudioPlayer();

  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
                                     MistakeTrackerService.printAllMistakes();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(_progressController);

    loadMistakes();

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && selectedOption == null) {
        checkAnswer('');
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> loadMistakes() async {
    List<Map<String, dynamic>> all = await MistakeTrackerService.loadMistakesFromLocal();
    print('Loaded ${all.length} mistakes');
   for (var q in all) {
      print('Question: ${q['question']}');
    }
    all.shuffle();
    setState(() {
      questions = all;
      Future<void> loadMistakes() async {
        List<Map<String, dynamic>> all = await MistakeTrackerService.loadMistakesFromLocal();
        print('Loaded ${all.length} mistakes');
        for (var q in all) {
          print('Question: ${q['question']}');
        }
        all.shuffle();
        setState(() {
          questions = all;
          currentIndex = 0;       // add this
          selectedOption = null;  // add this
          shuffledOptions = [];   // add this
        });

        _progressController.reset();
        _progressController.forward();
      }
      ;

    });
    _progressController.reset();
    _progressController.forward();
  }

  Future<void> checkAnswer(String selected) async {
    final question = questions[currentIndex];
    final correct = question['answer'];

    if (selected == correct) {
      resolvedCount++;
      await MistakeTrackerService.removeMistake(question['question']);
      //await MistakeTrackerService.trackCorrect(
       // userId: 'test_user',
        //questionData: question,
      //);
    } else if (selected != '') {
      wrongAnswers.add(IncorrectAnswer(
        question: question['question'],
        userAnswer: selected,
        correctAnswer: correct,
      ));
    } else {
      wrongAnswers.add(IncorrectAnswer(
        question: question['question'],
        userAnswer: '(No Answer)',
        correctAnswer: correct,
      ));
    }

    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        selectedOption = null;
        shuffledOptions = [];
      });
      _progressController.reset();
      _progressController.forward();
    } else {
      Navigator.pop(context, resolvedCount);
    }
  }

  Color getOptionColor(String option) {
    if (selectedOption == null) return Colors.grey.shade800;
    if (option == questions[currentIndex]['answer']) return Colors.green;
    if (option == selectedOption) return Colors.red;
    return Colors.grey.shade800;
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final question = questions[currentIndex];
    final List<dynamic> options = question['options'];
    if (shuffledOptions.isEmpty) {
      shuffledOptions = List<String>.from(options);
      shuffledOptions.shuffle();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Clear Mistakes', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(questions.length, (index) {
                double value;
                if (index < currentIndex) value = 1;
                else if (index == currentIndex) value = _progressAnimation.value;
                else value = 0;
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
            ),
            const SizedBox(height: 8),
            Text(
              'Question ${currentIndex + 1} of ${questions.length}',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text(
              question['question'],
              style: const TextStyle(color: Colors.white, fontSize: 22),
            ),
            const SizedBox(height: 24),
            ...shuffledOptions.map((option) {
              return GestureDetector(
                onTap: selectedOption == null ? () {
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
                } : null,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: getOptionColor(option),
                  ),
                  child: Math.tex(
                    option,
                    textStyle: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              );
            })
          ],
        ),
      ),
    );
  }
}
