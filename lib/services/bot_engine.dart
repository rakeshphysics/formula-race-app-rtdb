import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class BotEngine {
  final int level; // 1 = easy, 2 = medium, 3 = hard
  final Random _random = Random();
  final AudioPlayer _audioPlayer = AudioPlayer();

  BotEngine(this.level);

  /// Simulates the bot's chosen answer after a delay
  /// [question] must have 'answer' and 'options'
  Future<String> getAnswer(Map<String, dynamic> question) async {
    // Determine delay range based on difficulty
    Duration delay;
    switch (level) {
      case 1:
        delay = Duration(seconds: _random.nextInt(3) + 4); // 4–6 sec
        break;
      case 2:
        delay = Duration(seconds: _random.nextInt(3) + 2); // 2–4 sec
        break;
      case 3:
      default:
        delay = Duration(seconds: _random.nextInt(2) + 1); // 1–2 sec
        break;
    }

    await Future.delayed(delay);

    String correct = question['answer'];
    List<dynamic> options = question['options'];

    // Decide accuracy probability
    double accuracy;
    switch (level) {
      case 1:
        accuracy = 0.3;
        break;
      case 2:
        accuracy = 0.6;
        break;
      case 3:
      default:
        accuracy = 0.9;
        break;
    }

    if (_random.nextDouble() <= accuracy) {
      return correct;
    } else {
      List<String> wrongOptions = List<String>.from(options)
          .where((opt) => opt != correct)
          .toList();
      return wrongOptions[_random.nextInt(wrongOptions.length)];
    }
  }

  /// Called when user selects an option in bot mode.
  /// Plays sound and returns whether answer was correct.
  Future<bool> handleUserAnswerInBotMode(
      Map<String, dynamic> question, String selectedAnswer) async {
    final correctAnswer = question['answer'];
    final isCorrect = selectedAnswer == correctAnswer;

    print("🤖 USER selected: $selectedAnswer | Correct: $correctAnswer");

    final soundPath = isCorrect ? 'sounds/correct.mp3' : 'sounds/wrong.mp3';
    await _audioPlayer.play(AssetSource(soundPath));

    await Future.delayed(const Duration(milliseconds: 700));
    return isCorrect;
  }

  Future<void> handleTurn({
    required Map<String, dynamic> question,
    required String userAnswer,
    required VoidCallback onBotWins,
    required VoidCallback onPlayerWins,
  }) async {
    final userWasCorrect = await handleUserAnswerInBotMode(question, userAnswer);

    if (userWasCorrect) {
      onPlayerWins();
    } else {
      final botAnswer = await getAnswer(question);
      final correctAnswer = question['answer'];

      print("🤖 BOT selected: $botAnswer | Correct: $correctAnswer");

      if (botAnswer == correctAnswer) {
        onBotWins();
      }
    }
  }



}
