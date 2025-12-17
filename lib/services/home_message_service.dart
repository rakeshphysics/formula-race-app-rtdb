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
        "Nice! Fuel for the brain to get more right answers. 😉",
        "Good, good. An empty stomach can't solve tough questions. 🧠",
        "Awesome! Now you're ready to smash some quizzes. 💪",
        "Great! A well-fed mind is a smart mind. 🤓",
        "Perfect! Now let's turn that food into fuel for a high score. 🔥",
        "Excellent! Ready to conquer the leaderboard now? 🏆",
        "Sweet! A happy tummy leads to happy learning. 😊",
        "That's the spirit! Now let's get this bread (and the right answers). 🍞",
        "Brilliant! You're all set for a winning streak. 🚀",
        "Good stuff! Now your brain has the energy to be a genius. ✨",
        "Nice one! Let's see if that meal powered up your brain cells. ⚡",
        "Great to hear! Now you're officially ready to roll. 🚗",
        "Perfecto! A full stomach is the secret weapon of a topper. 😉",
        "Awesome! Now let's put that energy to the test. 🎯",
        "That's what I like to hear! Ready for a challenge? 😎",
        "Fantastic! A fed panda is a happy panda. And a smart one too! 🐼",
        "Good! Now your brain won't make 'hangry' mistakes. 😂",
        "Superb! Let's channel that energy into some epic wins. 🎉",
        "Right on! Now you're in the perfect state to learn something new. 🌟",
        "Cool! Let's see if that meal was a 'power-up'. 🍄",
        "Love it! A happy meal for a happy student. 😄",
        "Perfect! Now you're unstoppable. Let's go! 💨",
        "Great! You've completed the first mission of the day. ✅",
        "Excellent choice! Now let's make some excellent choices in the quiz. 🤔",
        "Nice! You're all charged up and ready to go. 🔋",
        "Good job! Taking care of yourself is the first step to success. 🥇",
        "Sweet! Now let's get some sweet, sweet victory. 🍬",
        "Perfect! Now your brain is running on premium fuel. ⛽",
        "Awesome! You're ready to be the Virat Kohli of quizzes. 🏏",
        "Great! Now let's make your brain do a happy dance. 🕺"
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
        "Arre! Go grab a bite. Your brain needs fuel! 🍎",
        "Dude, food first! Quizzes can wait a minute. 🥪",
        "Nooo! An empty stomach is the enemy of a high score. Go eat! 😠",
        "Bro, don't skip meals! Your brain will thank you. 🙏",
        "Go eat something! I'll wait. I'm a patient panda. 🐼",
        "Hey! Even superheros need to eat. Go get your power-up. ⚡",
        "Don't be a hero, go eat! A 'hangry' brain makes silly mistakes. 😂",
        "Chal, chal, pehle khaana! Your health is more important. ❤️",
        "Seriously? Go grab a snack at least. Your brain is begging you. 🧠",
        "Food is not a bug, it's a feature! Go install it. 😉",
        "Remember: A happy tummy = a happy mind. Go make it happy! 😊",
        "Go on, take a break. Even I'm feeling hungry just thinking about it. 🍕",
        "Don't run on empty! A quick snack can make all the difference. 🍌",
        "Your brain just sent me a low battery notification. Please recharge! 🔋",
        "How can you focus on acing quizzes with a rumbling tummy? Go eat! 🤔",
        "Stop everything! This is a food emergency. 🚨",
        "Go grab something quick! We need you at 100%. 💪",
        "You wouldn't drive a car with no fuel, right? Same for your brain! 🚗",
        "Abe, jaa ke kha le! Sharmaji ka beta already kha chuka hai. 😉",
        "Your quest for knowledge can pause for a quick meal break. ⏸️",
        "Don't ignore the rumble! Your stomach is trying to tell you something. 🗣️",
        "Go eat! You can't download new information on an empty drive. 💾",
        "A snack break is a smart break! Go take one. 🍪",
        "Come on! You need energy to beat your high score. Go get it! 🏆",
        "Even I need my bamboo shoots! Go get your version of it. 🎋",
        "Don't let hunger be the reason for a wrong answer! Go eat. ❌",
        "Your brain cells are on strike until you feed them. Go negotiate! 😂",
        "Quick, find food! It's the ultimate cheat code for focus. 🎮",
        "Health is wealth! Go invest in a good meal. 💰",
        "Go eat! I'll save your spot on the leaderboard. 😉"
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
        "10/10! Are you even real? What a legend! 👑",
        "Perfect score! Someone call the fire brigade, you're on fire! 🔥",
        "Sharmaji ka beta is shaking right now. 10/10! 😉",
        "Absolute genius mode: ON. Perfect score! 🧠",
        "10/10! You didn't just pass, you topped the class. 🏆",
        "Macha, you aced it! Full marks! 🎉",
        "No mistakes! Are you a human or a supercomputer? 🤖",
        "Oho, look at the Topper! 10 on 10! 🤓",
        "Flawless victory! You absolutely smashed it. 💥",
        "10/10! Your brain is working faster than Mumbai local trains. 🚄",
        "Full marks! Did you even study or were you just born this smart? 🤔",
        "Bhai, that was brilliant! Not a single mistake. 🙌",
        "Perfect score! You've got the Midas touch. ✨",
        "10/10! You didn't leave any crumbs. Clean sweep! 🧹",
        "Arre waah! Full marks. Time for a party? 🥳",
        "Nailed it! Every single answer was spot on. 🎯",
        "10/10. Your brain just went Super Saiyan. 💪",
        "Not just good, but 10/10 good. Sabash! 👏",
        "Perfect score! You're the Virat Kohli of quizzes. 🏏",
        "Kya baat hai! You made it look too easy. 😎",
        "10/10! Your neurons are firing on all cylinders. ⚡",
        "Full marks! Is your middle name 'Perfection'? 💯",
        "You didn't just understand the assignment, you *are* the assignment. 10/10! ✨",
        "Jugaad not needed when you have this much skill. Perfect score! 🛠️",
        "10/10! That was a mic-drop performance. 🎤",
        "No errors found. You're officially a bug-free genius. 🐞",
        "Ek number! Literally, not one mistake. 🥇",
        "Perfect score! You're on a whole other level. 🚀",
        "10/10! You've got more right answers than a politician has promises. 😉",
        "Mast kaam! You aced it completely. Keep it up! 👍"
      ];
      gameRecap = getRandomMessage(messages);
    } else if (score >= 0.8) {
      const messages = [
        "8 ya 9, score hai fine! Agli baar 10 ki line. ✨",
        "Almost there, don't have a care! Perfect score is in the air. 🌬️",
        "Great score, can't ignore! Full marks milenge for sure. 😎",
        "That was great, what a fate! 10/10 is your next date. 😉",
        "Not bad, dost, you're the host! A perfect score is what you want most. 🚀",
        "On a roll, it's in your soul! Making 10/10 your only goal. 🥅",
        "That was slick, what a trick! Ek aur sahi answer and you'll click. 🧠",
        "Nearly there, with style and flair! A perfect score is your next affair. 💘",
        "Top of the class, you're moving fast! Make that perfect score last. 🏆",
        "Kya show, what a flow! Bas ek aur sahi answer to go. ☝️",
        "You're a star, mere yaar! A perfect 10 is not that far. ⭐",
        "So close you came, to winning the game! A perfect score will be your fame. 🏅",
        "That was ace, you set the pace! The top spot is your rightful place. 👑",
        "Bohot hard, you played your card! A perfect score is your real reward. 🃏",
        "You're a pro, watch how you go! Next time it's a 10, not a 'no'. ✅",
        "Ek number kaam, full on araam! Next time, poora exam tere naam. 💪",
        "On the brink, faster than you think! A perfect score is the final link. 🔗",
        "That was bright, a shining light! The final answer is in your sight. 👀",
        "You're a boss, with no loss! Just one more answer to get across. 🌉",
        "Super scene, you're very keen! A 10/10 is the next routine. 🕺",
        "You've got the knack, you're on the right track! Ab koi turning back nahi. 🛤️",
        "That was fire, taking you higher! A perfect score is your true desire. 🔥",
        "You're a hit, just admit! Ek aur sahi and the lamp is lit. 💡",
        "Great play, kya kehna, bhai? A perfect 10 is on its way. 🚚",
        "You're a gem, no mayhem! The next 10/10 is your new anthem. 🎶",
        "That was neat, can't be beat! A perfect score will be so sweet. 🍬",
        "You're a champ, lighting the lamp! The final step is just a small ramp. 램프",
        "You're a wizard, through the blizzard! A perfect score is the final... lizard? 🦎",
        "You're a master, faster and faster! A 10/10 is what you're really after. 🎯",
        "That was cool, you totally rule! A perfect score is the final tool. 🛠️"
      ];
      gameRecap = "$correct/$total! ${getRandomMessage(messages)}";
    } else if (score >= 0.5) {
      const messages = [
        "Not bad, not bad! Thoda aur focus and you'll be a star. ⭐",
        "A decent start! Abhi toh party shuru hui hai. 🎉",
        "You're on the right track! Keep pushing, you'll get there. 🛤️",
        "Good effort! Thoda aur practice and you'll be unstoppable. 💪",
        "50-50 chance, not bad! Agli baar full power! ⚡",
        "You've got the basics down! Ab time hai master banne ka. 🥋",
        "Solid attempt! Keep your eyes on the prize. 🎯",
        "A good foundation! Let's build an empire on it. 🏰",
        "You're halfway there! The other half is just waiting for you. 😉",
        "Keep going! Har expert ek time pe beginner tha. 🤓",
        "That's the spirit! Mistakes are proof that you are trying. 👍",
        "Okay, okay, I see you! Potential toh hai. 🔥",
        "Good job! Now let's turn that 'good' into 'great'. 🚀",
        "You're getting warmer! The top is closer than you think. 🧗",
        "A for effort! Now let's aim for A+ in score. 💯",
        "This is a good start! Picture abhi baaki hai mere dost. 🎬",
        "You're learning and growing! That's what matters most. 🌱",
        "Don't worry, even Sachin started with zero. You're already ahead! 🏏",
        "Nice try! Ab thoda sa aur 'josh' dikhao! 💪",
        "You've got the skill! Now let's add some more 'will'. ✨",
        "Not bad at all! You're a work in progress, and it's looking good. 🚧",
        "Keep at it! Practice makes perfect, and you're on your way. 🚶",
        "A solid score! Let's aim for the boundary next time. 🏏",
        "You're climbing the ladder! Don't look down. 🪜",
        "Good innings! Let's turn this 50 into a century. 💯",
        "You have the power! Thoda sa concentration is all you need. 🧠",
        "This is where the comeback story begins. Let's write it! ✍️",
        "A decent score! But 'decent' is not what legends are made of. 😉",
        "You're in the game! Now let's play to win. 🏆",
        "Mast try! Keep practicing, and you'll be a pro in no time. 😎"
      ];
      gameRecap = "$correct/$total! ${getRandomMessage(messages)}";
    } else if (score > 0) {
      const messages = [
        "Every expert was once a beginner. This is your first step! 👍",
        "Koi baat nahi! The first try is always the hardest. Keep going! 💪",
        "You've started the engine! Ab bas race jeetna baaki hai. 🏎️",
        "The journey of a thousand miles begins with a single step. You took it! 🚶",
        "Don't worry about the score, focus on the learning. You've got this! 🧠",
        "A few right answers is a great start! Let's build on it. 🧱",
        "Practice makes a man perfect! Keep trying. 🏏",
        "It's okay! Even the best fall down sometimes. What matters is getting up. 🌅",
        "You're in the game! That's what counts. Let's try again. 🎮",
        "Har din ek jaisa nahi hota. Tomorrow is a new day! ☀️",
        "The seed is planted! Now let's help it grow. 🌱",
        "Don't give up! The comeback is always stronger than the setback. 💥",
        "This is just the warm-up! The real match is yet to come. 🔥",
        "You've got the 'josh'! Keep that fire burning. 🔥",
        "Failure is not the opposite of success, it's part of it. Keep learning! 📚",
        "Thoda aur practice, and you'll see a huge difference. Believe it! ✨",
        "It's not about being the best. It's about being better than you were yesterday. 📈",
        "You answered some correctly! That's a win. Let's get more next time. 🎯",
        "Don't stress! Learning is a marathon, not a sprint. 🏃",
        "The first attempt is for courage. The next is for winning. Let's go! 🏆",
        "You've taken the first step on a great journey. Keep walking! 🚶‍♂️",
        "It's okay to not know, but it's not okay to not try. And you tried! 👏",
        "Rome wasn't built in a day. Keep building your knowledge. 🏛️",
        "Chin up! You're learning, and that's a victory in itself. 🏅",
        "Every mistake is a lesson. You just got a few free lessons! 😉",
        "Don't let this score define you. Your effort does. Keep it up! 🙌",
        "This is just level 1. The boss level is waiting! 👾",
        "Focus on what you got right and build from there. You can do it! 🛠️",
        "Himmat mat haro! You are capable of amazing things. 🌟",
        "Okay, a few bumps in the road. Let's try a smoother ride next time! 🛣️"
      ];

      gameRecap = "$correct/$total! ${getRandomMessage(messages)}";
    } else {
      const messages = [
        "Zero pe out? Even Sachin started there. Let's go again! 🏏",
        "Koi baat nahi! This was just a trial ball. The real game starts now. 😉",
        "Okay, so this round was just for practice. The next one is for the score! 💪",
        "The only way from here is up! Let's climb. 🚀",
        "Don't worry! This round was just to wake up your brain. 🧠",
        "A zero? That's just the universe telling you to start fresh. ✨",
        "No problem! The first pancake is always a bit messy. 🥞",
        "You've officially hit rock bottom. Now we can only go up! 📈",
        "Think of this as the 'before' picture. The 'after' will be amazing. 😎",
        "Everyone starts somewhere. You started! That's a win. 🏆",
        "This round didn't count, okay? Let's start for real now. 😉",
        "So, we found all the wrong answers. Now let's find the right ones! 🗺️",
        "Chin up, champ! This is just loading time... the game is about to begin. ⏳",
        "The hero's journey always starts with a challenge. This was yours! 🦸",
        "Okay, that was the free hit. Now let's score a sixer! 🏏",
        "No score? No tension! Let's try one more time. 👍",
        "This was just a net practice session. Time for the real match! 🔥",
        "Don't let a zero stop you. It's just a number! Let's change it. 🔄",
        "You missed a few, so what? Abhi picture baaki hai mere dost! 🎬",
        "Consider this a strategic retreat. The next attack will be legendary! 🤺",
        "It's okay! Sometimes you have to lose a battle to win the war. ⚔️",
        "This was just a system reboot. Let's start again, fresh and fast! 💻",
        "A 'duck' in cricket is not the end. Let's hit a boundary now! 🏏",
        "You didn't lose, you just learned what doesn't work. That's a win! 💡",
        "Okay, that was a tough one! Let's try an easier level. 😉",
        "No worries at all! The first step is always the hardest. You took it. 👏",
        "This round was on me. Let's play again! 🤝",
        "Even a broken clock is right twice a day. We'll get there! 🕰️",
        "So we're starting from scratch. The best stories start that way! 📖",
        "Forget the score. You showed up. That's what matters. Let's go again! 🙌"
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

  // Future<String> getGameAdviceMessage(String userId) async {
  //   final dbHelper = DatabaseHelper.instance;
  //
  //   // --- THIS IS THE UPDATED PART ---
  //   // We now call the real database function.
  //   final List<GamePerformance> recentPerformance = await dbHelper.getPerformanceOverLast5Games();
  //
  //   if (recentPerformance.isEmpty) {
  //     return "Keep playing a few more games, and I'll have some specific advice for you!";
  //   }
  //
  //   // Calculate the average score from the GamePerformance objects.
  //   final averageScore = recentPerformance.map((p) => p.score).average;
  //
  //   if (averageScore >= 0.8) {
  //     return "GAME ADVICE >8";
  //   } else if (averageScore >= 0.5) {
  //     return "GAME ADVICE 5-8";
  //   } else {
  //     return "GAME ADVICE 0-5";
  //   }
  // }

  Future<String> getGameAdviceMessage(String userId) async {
    final dbHelper = DatabaseHelper.instance;
    // Note: The _random variable is already part of your class, so we use it.

    // 1. Define the master list of all chapters.
    const allChapters = [
      "Units and Dimensions", "Kinematics", "Laws of Motion", "Circular Motion",
      "Work Power Energy", "Center of Mass", "Rotational Motion", "Gravitation",
      "Elasticity", "Fluids", "Thermodynamics", "Kinetic Theory", "SHM", "Waves",
      "Electrostatics", "Capacitors", "Current Electricity", "Magnetism", "EMI",
      "AC", "EM Waves", "Ray Optics", "Wave Optics", "Dual Nature of Light",
      "Atoms", "Nuclei", "X Rays", "Semiconductors", "Vectors"
    ];

    // 2. Call the database function to get performance per chapter.
    final List<ChapterPerformance> performanceByChapter = await dbHelper.getPerformanceOverLast5Games();

    final List<String> possibleInsights = [];

    if (performanceByChapter.isEmpty) {
      return "Attempt some questions, and I'll give you personalized advice on which chapters to focus on!";
    }

    // 3. Logic for Unattempted Chapters
    final attemptedChapters = performanceByChapter.map((p) => p.chapterName).toSet();
    final unattemptedChapters = allChapters.where((chapter) => !attemptedChapters.contains(chapter)).toList();

    if (unattemptedChapters.isNotEmpty) {
      final chapterToSuggest = unattemptedChapters[_random.nextInt(unattemptedChapters.length)];
      possibleInsights.add("You haven't tried any questions from '$chapterToSuggest' yet. Why not start with this chapter?");
    }

    // 4. Logic for Attempted Chapters
    for (final performance in performanceByChapter) {
      if (performance.totalAttempts < 3) continue; // Ignore chapters with too few attempts

      final accuracyPercent = (performance.accuracy * 100).round();
      final chapterName = performance.chapterName;

      if (accuracyPercent >= 90) {
        possibleInsights.add("You're a master of '$chapterName' with $accuracyPercent% accuracy. Keep up the brilliant work! ✨");
      } else if (accuracyPercent >= 50) {
        possibleInsights.add("Your accuracy in '$chapterName' is $accuracyPercent%. A little more revision and you'll master it. 💪");
      } else {
        possibleInsights.add("You seem to be finding '$chapterName' tricky, with $accuracyPercent% accuracy. It might be a good idea to review the concepts. 📚");
      }
    }

    // 5. Select and Return an Insight
    if (possibleInsights.isEmpty) {
      final averageScore = performanceByChapter.map((p) => p.accuracy).average;
      if (averageScore >= 0.7) {
        return "You're doing great overall! Keep practicing to get more specific advice on different chapters.";
      } else {
        return "Keep up the practice! The more questions you do, the better your understanding will become.";
      }
    }

    return possibleInsights[_random.nextInt(possibleInsights.length)];
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