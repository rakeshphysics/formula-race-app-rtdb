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

    // lib/services/home_message_service.dart

    // lib/services/home_message_service.dart

    String gameRecap;
    if (score == 1.0) {
      const messages = [
        // Original
        "A perfect score! Are you even human?! 🤖🏆",
        "Flawless victory! You're unstoppable! 🚀",
        "Perfection! Bow down to the master. 👑",
        // Added
        "10/10! Is your middle name 'Perfect'? ✨",
        "Wow, a flawless run! Genius at play. 🧠",
        "Perfect score! You didn't miss a beat. 🎶",
        "Nailed it! Every single one. 🎯",
        "That was legendary! A perfect round! 🌟",
        "You're in a league of your own! Perfect! 🥇",
        "Absolutely brilliant! A perfect score! 💡",
        "Clean sweep! Nothing gets past you. 🧹",
        "Incredible! You're on another level. 👽",
        "Perfection achieved! Take a bow. 🙇",
        "Stunning performance! Acing it! ✅",
        "You're a quiz ninja! Silent but deadly. 🥷",
        "That was a masterclass! Bravo! 👏",
        "Not a single mistake. Impressive! 👌",
        "You ate that quiz for breakfast. 🍽️",
        "The GOAT! Greatest of all time! 🐐",
        "Boom! Perfect score. Mic drop. 🎤",
      ];
      gameRecap = (messages..shuffle()).first;
    } else if (score >= 0.8) {
      const messages = [
        // Original
        "Awesome score! You're on fire! 🔥",
        "Nearly perfect! You've got this! 😎",
        "Fantastic work! A true pro. ✨",
        // Added
        "So close to perfection! Amazing! 🤏",
        "That was top-tier! Excellent job! 👍",
        "Incredible effort! You're a star! ⭐",
        "You've got the magic touch! 🎩",
        "Superb performance! Keep it up! ⚡",
        "That score is glowing! Great work! 🌟",
        "You're crushing it! What a result! 💪",
        "Almost perfect! The next one is yours. 😉",
        "Brilliant! Your brain is a powerhouse. 🧠",
        "That's how it's done! High-five! 🙌",
        "You're a force to be reckoned with! 🌪️",
        "Top marks! You really know your stuff. 📚",
        "Outstanding! You made that look easy. 😊",
        "You're getting hotter than a jalapeño! 🌶️",
        "That was seriously impressive! 🤩",
        "Great score! You're in the zone. 🎯",
        "Excellent! Your hard work is showing. 📈",
      ];
      gameRecap = "$correct/$total! ${(messages..shuffle()).first}";
    } else if (score >= 0.5) {
      const messages = [
        // Original
        "Solid round! Keep that brain buzzing! 🧠",
        "Nice one! Progress is looking good. 👍",
        "Great effort! Let's keep climbing. 🧗",
        // Added
        "Good stuff! You're on the right path. 🛤️",
        "That's a great score! Keep pushing! 🏃",
        "Well done! Building up that knowledge. 🧱",
        "You're doing great! Keep the rhythm. 🥁",
        "Solid! You're warming up nicely. 🔥",
        "Nice work! Every round makes you stronger. 💪",
        "Looking good! You've got a great handle on this. 👌",
        "That's the way! Consistency is key. 🔑",
        "Good job! Let's aim even higher next time. 🚀",
        "You're making real progress! 🌱",
        "A very respectable score! Pat on the back. 🤗",
        "Keep it up! You're doing awesome. 😄",
        "Solid performance! Your brain is getting a workout. 🏋️",
        "That's more than halfway to perfect! 🎉",
        "Great job! You're connecting the dots. ✨",
        "Nice! You're really getting the hang of it. 👍",
        "Strong showing! Let's go again! 🔄",
      ];
      gameRecap = "$correct/$total! ${(messages..shuffle()).first}";
    } else if (score > 0) {
      const messages = [
        // Original
        "Good start! Every point counts. 🎯",
        "On the board! Let's build on it. 🏗️",
        "That's the spirit! Onwards and upwards! 🎈",
        // Added
        "A great first step! Let's keep going. 🚶",
        "Every expert starts somewhere! Nice one. 👍",
        "You're in the game! Let's level up. 🎮",
        "That's a foundation for greatness! 🏛️",
        "Well done! The only way from here is up. 📈",
        "You've sparked the engine! Vroom! 🏎️",
        "Points on the board! That's what matters. ✅",
        "Good job grabbing those points! 👏",
        "The journey has begun! Keep at it. ✨",
        "Nice! Let's turn that spark into a fire. 🔥",
        "A solid starting block to launch from! 🚀",
        "You've got this! One step at a time. 🐾",
        "That's the beginning of a winning streak! 😉",
        "Great start! Let's add to it. ➕",
        "Every correct answer is a victory! 🏆",
        "You're officially on a roll! 🍥",
        "Keep that positive energy! It's working. 😊",
      ];
      gameRecap = "$correct/$total! ${(messages..shuffle()).first}";
    } else {
      const messages = [
        // Original
        "A tough round, huh? Let's shake it off!",
        "Okay, that was just a warm-up lap! 😉",
        "Don't sweat it. The comeback is always stronger! 💪",
        // Added
        "No worries! The next round is a fresh start. 🌅",
        "That round was just for practice, right? 😉",
        "Shake it off! Even champions have off-days. 🥊",
        "Alright, we've found the boss level! Let's try again. 👾",
        "Don't you worry! We learn the most from challenges. 🧠",
        "That was a tricky one! Let's get 'em next time. 🎯",
        "Think of it as a strategic retreat. Now, we attack! ⚔️",
        "Okay, let's pretend that didn't happen. 😂",
        "Every stumble is a chance to learn to fly. 🦅",
        "That quiz was spicy! Let's get some water. 💧",
        "Failure is just a plot twist. The story isn't over! 📖",
        "No big deal! Let's reboot and go again. 🔄",
        "Even the best miss sometimes. On to the next! 🚀",
        "That was just clearing the cobwebs out! 🕸️",
        "Don't give up! A smooth sea never made a skilled sailor. ⛵",
        "Okay, new plan: be even more awesome. Ready? ✨",
        "It's not about the fall, it's about the epic comeback! 💥",
      ];
      gameRecap = (messages..shuffle()).first;
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