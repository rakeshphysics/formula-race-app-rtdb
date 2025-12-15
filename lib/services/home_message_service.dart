// lib/services/home_message_service.dart

import 'dart:math';
import 'package:collection/collection.dart';
import 'package:formularacing/models/practice_attempt.dart';
import 'package:formularacing/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:formularacing/models/game_performance.dart';

class PandaResponse {
  final String message;
  final bool showMealButtons;

  PandaResponse({required this.message, this.showMealButtons = false});
}


class HomeMessageService {
  HomeMessageService._privateConstructor() {
    _initialize();
  }
  static final HomeMessageService instance = HomeMessageService._privateConstructor();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Random _random = Random();
  String _lastMessage = '';

  late final List<Future<String> Function(String)> _messageGenerators;

  factory HomeMessageService() {
    return instance;
  }

  void _initialize() {
    _messageGenerators = [

    ];
  }



  List<String> _getGenericWelcomeMessages() {
    // 1. Define the original messages as a local, constant list.
    const messages = [
      "GENERIC WELCOME 1 👋",
      "GENERAIC WELCOME 2 😊",

    ];

    // 2. Create a new, modifiable list from the constant one.
    final modifiableList = List<String>.from(messages);

    // 3. Shuffle the new list.
    modifiableList.shuffle();

    // 4. Return the shuffled list.
    return modifiableList;
  }

  Future<PandaResponse> getGreeting(String userId) async {
    final bool alreadyAsked = await _hasAskedMealQuestionToday();

    // This is the shared logic that was previously in getHomePageMessage
    Future<String> generateRegularMessage() async {
      final possibleMessages = <String>[];
      for (var generator in _messageGenerators) {
        final message = await generator(userId);
        if (message.isNotEmpty) {
          possibleMessages.add(message);
        }
      }
      possibleMessages.addAll(_getGenericWelcomeMessages());
      final uniqueMessages = possibleMessages.where((m) => m != _lastMessage).toList();
      String newMessage;
      if (uniqueMessages.isNotEmpty) {
        newMessage = uniqueMessages[_random.nextInt(uniqueMessages.length)];
      } else if (possibleMessages.isNotEmpty) {
        newMessage = possibleMessages.first;
      } else {
        newMessage = "Ready to start?";
      }
      _lastMessage = newMessage;
      return newMessage;
    }

    if (alreadyAsked) {
      // If we already asked, fall back to the regular message logic.
      final message = await generateRegularMessage();
      return PandaResponse(message: message, showMealButtons: false);
    }

    final DateTime now = DateTime.now();
    final int hour = now.hour;

    // Check for breakfast time (7:00 AM to 9:59 AM)
    if (hour >= 7 && hour < 10) {
      await _markMealQuestionAsAsked();
      return PandaResponse(message: "Hola! Did you have a good breakfast?", showMealButtons: true);
    }
    // Check for lunch time (12:30 PM to 2:59 PM)
    else if (hour >= 12 && hour < 15) {
      await _markMealQuestionAsAsked();
      return PandaResponse(message: "Hola! Did you have a nice lunch?", showMealButtons: true);
    }
    // Check for dinner time (7:30 PM to 10:29 PM)
    else if (hour >= 19 && hour < 22) {
      await _markMealQuestionAsAsked();
      return PandaResponse(message: "Hey there! Did you have dinner?", showMealButtons: true);
    }

    // If it's outside meal times, use the regular message logic.
    final message = await generateRegularMessage();
    return PandaResponse(message: message, showMealButtons: false);
  }

  Future<bool> _hasAskedMealQuestionToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastAskedString = prefs.getString('lastMealQuestionDate');

    if (lastAskedString == null) {
      return false; // Never asked before.
    }

    final lastAskedDate = DateTime.parse(lastAskedString);
    final now = DateTime.now();

    // Compare year, month, and day to see if it's the same calendar day.
    return now.year == lastAskedDate.year &&
        now.month == lastAskedDate.month &&
        now.day == lastAskedDate.day;
  }

  Future<void> _markMealQuestionAsAsked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastMealQuestionDate', DateTime.now().toIso8601String());
  }

  Future<String> getMealResponseMessage(bool hadMeal) async {
    // This function doesn't need to be async for now, but it's good practice
    // in case we want to add complex logic or API calls later.

    if (hadMeal) {
      // User tapped "Yes"
      // You can add more variations to this list
      const positiveResponses = [
        "MEAL POSITIVE RESPONSE",
      ];
      final modifiableList = List<String>.from(positiveResponses);
      // Shuffle the new list
      modifiableList.shuffle();
      // Return an item from the shuffled list
      return modifiableList.first;
    } else {
      // User tapped "No"
      // You can add more variations to this list
      const encouragingResponses = [
        "MEAL NEGATIVE RESPONSE",
      ];
      final modifiableList = List<String>.from(encouragingResponses);
      modifiableList.shuffle();
      return modifiableList.first;
    }
  }

  Future<String> getPostGameAnalysisMessage(String userId) async {
    final dbHelper = DatabaseHelper.instance;
    final lastGame = await dbHelper.getLastGameDetails();

    if (lastGame == null) {
      return "Let's play a round to see how you're doing!";
    }

    final int correct = lastGame['correct_count'];
    final int total = lastGame['total_questions'];
    final double score = total > 0 ? correct / total : 0;

    String gameRecap;

    // This is the corrected pattern:
    // 1. Define the const messages.
    // 2. Create a new, modifiable list from the const list.
    // 3. Shuffle the new list.
    // 4. Get the first element.
    String getRandomMessage(List<String> messages) {
      final modifiableList = List<String>.from(messages);
      modifiableList.shuffle();
      return modifiableList.first;
    }

    if (score == 1.0) {
      const messages = [
        "POST GAME ANALYSIS 10/10",
        "POST GAME ANALYSIS 10/10",
      ];
      gameRecap = getRandomMessage(messages);
    } else if (score >= 0.8) {
      const messages = [
        "POST GAME ANALYSIS 8/10",
        "POST GAME ANALYSIS 8/10",
      ];
      gameRecap = "$correct/$total! ${getRandomMessage(messages)}";
    } else if (score >= 0.5) {
      const messages = [
        "POST GAME ANALYSIS 5/10",
        "POST GAME ANALYSIS 5/10",
      ];
      gameRecap = "$correct/$total! ${getRandomMessage(messages)}";
    } else if (score > 0) {
      const messages = [
        "POST GAME ANALYSIS 2/10",
        "POST GAME ANALYSIS 2/10",
      ];
      gameRecap = "$correct/$total! ${getRandomMessage(messages)}";
    } else {
      const messages = [
        "POST GAME ANALYSIS 0",
        "POST GAME ANALYSIS 0",
      ];
      gameRecap = getRandomMessage(messages);
    }

    return gameRecap;
  }

  Future<String> getMotivationalQuote() async {
    const quotes = [
      "MOTIVATION 1 🚀",
      "MOTIVATION2 ✨",
      "MOTIVATION 3 💪",
    ];
    // Return a random quote
    final modifiableQuotes = List<String>.from(quotes);
    modifiableQuotes.shuffle();
    return modifiableQuotes.first;
  }

  Future<String> getGameAdviceMessage(String userId) async {
    final dbHelper = DatabaseHelper.instance;

    // --- THIS IS THE UPDATED PART ---
    // We now call the real database function.
    final List<GamePerformance> recentPerformance = await dbHelper.getPerformanceOverLast5Games();

    if (recentPerformance.isEmpty) {
      return "Keep playing a few more games, and I'll have some specific advice for you!";
    }

    // Calculate the average score from the GamePerformance objects.
    final averageScore = recentPerformance.map((p) => p.score).average;

    if (averageScore >= 0.8) {
      return "GAME ADVICE >8";
    } else if (averageScore >= 0.5) {
      return "GAME ADVICE 5-8";
    } else {
      return "GAME ADVICE 0-5";
    }
  }

  Future<String> getGeneralAppAdvice() async {
    const adviceList = [
      "General App Advice 1",
      "General App Advice 2",
      "General App Advice 3",
      "General App Advice 4",
      "General App Advice 5"
    ];

    final modifiableList = List<String>.from(adviceList);
    modifiableList.shuffle();
    return modifiableList.first;
  }

}