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

  // A list of functions that generate messages.
  // We'll try each one until we find a message to display.
  late final List<Future<String> Function(String)> _messageGenerators;

  factory HomeMessageService() {
    return instance;
  }

  void _initialize() {
    _messageGenerators = [

    ];
  }

  // lib/services/home_message_service.dart

  List<String> _getGenericWelcomeMessages() {
    // 1. Define the original messages as a local, constant list.
    const messages = [
      "Welcome back!! 👋",
      "Good to see you! 😊",
      "Hey there! ✨",
      "Let's get started! 🚀",
      "Time for some fun! 🎉",
      "Let's do this! 💪",
      "Glad you're here. 🤗",
      "Let the games begin! 🎮",
    ];

    // 2. Create a new, modifiable list from the constant one.
    final modifiableList = List<String>.from(messages);

    // 3. Shuffle the new list.
    modifiableList.shuffle();

    // 4. Return the shuffled list.
    return modifiableList;
  }
// lib/services/home_message_service.dart

// --- New Main Method for Greetings ---
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
  }   // --- New function for meal responses ---
  Future<String> getMealResponseMessage(bool hadMeal) async {
    // This function doesn't need to be async for now, but it's good practice
    // in case we want to add complex logic or API calls later.

    if (hadMeal) {
      // User tapped "Yes"
      // You can add more variations to this list
      const positiveResponses = [
        "Great! A good meal is a great start to any challenge.",
        "Excellent! That's the fuel a champion needs.",
        "Fantastic! Keep that energy up.",
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
        "Oh, remember to eat! Your brain needs fuel to learn.",
        "Don't forget to refuel! A sharp mind needs good food.",
        "Make sure to grab a bite when you can. It's important!",
      ];
      final modifiableList = List<String>.from(encouragingResponses);
      modifiableList.shuffle();
      return modifiableList.first;
    }
  }


  // lib/services/home_message_service.dart

// lib/services/home_message_service.dart


// ... inside the HomeMessageService class

  Future<String> getPostGameAnalysisMessage(String userId) async {
    final dbHelper = DatabaseHelper.instance;
    final lastGame = await dbHelper.getLastGameDetails();

    // If there's no last game, return a generic message.
    // This is a fallback, though it's unlikely to be hit because this function
    // is only called when bamboos (i.e., correct answers) exist.
    if (lastGame == null) {
      return "Let's play a round to see how you're doing!";
    }

    // --- Part 1: Generate a comment about the last game ---
    final int correct = lastGame['correct_count'];
    final int total = lastGame['total_questions'];
    final double score = total > 0 ? correct / total : 0;

    String gameRecap;
    if (score == 1.0) {
      gameRecap = "A perfect score of $correct out of $total in the last round! Incredible work! 🏆";
    } else if (score >= 0.8) {
      gameRecap = "Great job on the last game! You got $correct out of $total correct. You're on fire! 🔥";
    } else if (score >= 0.5) {
      gameRecap = "Solid effort in the last round, scoring $correct out of $total. Keep that momentum going!";
    } else if (score > 0) {
      gameRecap = "Good start in the last game with $correct correct answers. Every correct answer is a step forward!";
    } else {
      gameRecap = "That was a tough round, but don't worry. The most important thing is to learn and try again. Let's go! 💪";
    }

    // --- Parts 2 & 3 (Placeholders for now) ---
    String advice = "\n\nHere's some advice for next time...";
    String quote = "\n\nAnd here's a little motivation for you...";

    // Combine the parts into the final message
    String finalMessage = gameRecap; // We will add advice and quote later

    return finalMessage;
  }

  // lib/services/home_message_service.dart -> inside HomeMessageService class

  // --- New method for motivational quotes ---
  Future<String> getMotivationalQuote() async {
    const quotes = [
      "The secret of getting ahead is getting started. 🚀",
      "Believe you can and you're halfway there. ✨",
      "Success is not final, failure is not fatal: it is the courage to continue that counts. 💪",
      "It does not matter how slowly you go as long as you do not stop. 🐢",
      "Everything you’ve ever wanted is on the other side of fear. 🦁",
      "The best way to predict the future is to create it. 🎨",
      "Strive for progress, not perfection. 🌱",
    ];
    // Return a random quote
    final modifiableQuotes = List<String>.from(quotes);
    modifiableQuotes.shuffle();
    return modifiableQuotes.first;
  }

  // --- New method for game advice ---
  // lib/services/home_message_service.dart

  // --- New method for game advice ---
  // lib/services/home_message_service.dart

// Add this import at the top of the file with your other imports
// ... inside the HomeMessageService class

  // --- New method for game advice ---
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
      return "Your recent performance is outstanding! 🏆 Keep focusing on those tricky questions to achieve perfection.";
    } else if (averageScore >= 0.5) {
      return "You're showing great consistency. 👍 Try to review the questions you get wrong to spot any patterns.";
    } else {
      return "You're building a good foundation. Let's focus on understanding the core concepts of the questions you miss. 🧠";
    }
  }

}