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
  int _lastAdviceCategoryIndex = -1;
  String _lastMessage = '';

  late final List<Future<String> Function(String)> _messageGenerators;

  factory HomeMessageService() {
    return instance;
  }

  void _initialize() {
    _messageGenerators = [

    ];
  }



  Future<List<String>> _getGenericWelcomeMessages() async {
    final prefs = await SharedPreferences.getInstance();
    // Get the current session count, defaulting to 0 if it's the first time.
    int sessionCount = prefs.getInt('sessionCount') ?? 0;

    List<String> messages;

    if (sessionCount < 3) {
      // --- Tier 1: First 3 sessions ---
      // For the first few times, give a simple, warm welcome.
      const welcomeMessages = [
        "Hey there! Ready to get started? 👋",
        "Welcome back! Let's make today productive. 😊",
        "Hola! Ready to challenge your brain? 🧠",
        "Hey! Good to see you again. Let's do this! 💪",
        "Welcome! What are we learning today? 🤔",
        "Arre, finally you're here! The formulas were missing you. 🥺",
        "Chai pi li? Now let's get the brain brewing too! ☕",
        "Ready to be smarter than your relatives think you are? 🤫",
        "Phone silent, Brain violent (mode on)! 🧠",
        "Sharmaji ka beta is already studying. You coming? 🏃‍♂️",
        "Physics, Chemistry, Maths... who are we crushing today? 🎸",
        "Oye Hero! Time to level up your brain. 🎮",
        "Welcome! Let's get this bread (and the right answers). 🍞",
        "Abhi maza aayega na bhidu! Let's solve some Qs. 🔥",
        "Focus mode: ON. Instagram: OFF. Let's go! 🎯",
        "Ready to confuse the exam paper with your intelligence? 🤯",
        "Macha, let's crush some questions today! 👊",
        "Exam sar pe hai! (Just kidding, but let's study anyway). 📅",
        "No 'jugaad' today, only pure logic! 🛠️",
        "Welcome! Your brain called, it wants a workout. 📞",
        "Let's make your future bright (like a tubelight, but faster). 💡",
        "Kya bolti public? Padhai karein? 📢",
        "Back again? You must be serious about that 100/100. 💯",
        "Time to show the syllabus who's boss. 💪",
        "Don't worry, I won't tell anyone you're actually studying. 🤫",
        "Let's turn that 'Zero' into 'Hero'. 🦸‍♂️",
        "Padhai time! Future you will thank you. 🙏",
      ];
      messages = welcomeMessages;
    } else {
      // --- Tier 2: After the first 3 sessions ---
      // Now, start nudging the user towards actions.
      const nudgeMessages = [
        // Nudge to revise formulas
        "Feeling a bit rusty? A quick look at the formulas might help! 📜",
        "Pro-tip: Revising formulas before a game can give you an edge. 😉",
        "Why not start with a quick formula revision? It's in the menu! ☰",
        "A quick formula check can warm up your brain. Give it a shot! 🔥",
        "Ready for a quiz? Maybe a quick glance at the formulas first? 🤓",

        // Nudge to play a game
        "Ready to test your knowledge? Let's play a round! 🚀",
        "Feeling confident? Jump into a 'Play Solo' game! 🎯",
        "How about a quick game to get the brain cells firing? ⚡",
        "The leaderboard is waiting. Let's play a game and climb up! 🏆",
        "Challenge yourself! A quick game is just a tap away. 😎",

        // Humorous / Engaging Nudges
        "Your brain called, it wants a workout. Let's play! 📞",
        "Welcome back to your personal brain gym! 💪",
        "Let's get this bread! (and the right answers) 🍞",
        "Time to be awesome. Let's start with a quiz! 💥",
        "Ready to be the 'Sharmaji ka beta' of quizzes today? 😉",
      ];
      messages = nudgeMessages;
    }

    // Increment the session count for the next time.
    await prefs.setInt('sessionCount', sessionCount + 1);

    // Shuffle the chosen list of messages to provide variety within the tier.
    final modifiableList = List<String>.from(messages);
    modifiableList.shuffle();
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
      possibleMessages.addAll(await _getGenericWelcomeMessages());
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
      // Top Tier - Indian Icons
      "Arise, awake, and stop not till the goal is reached. - Swami Vivekananda",
      "You have to dream before your dreams can come true. - A.P.J. Abdul Kalam",
      "If you want to shine like a sun, first burn like a sun. - A.P.J. Abdul Kalam",
      "Live as if you were to die tomorrow. Learn as if you were to live forever. - Mahatma Gandhi",
      "A man is but a product of his thoughts. What he thinks, he becomes. - Mahatma Gandhi",
      "You can't cross the sea merely by standing and staring at the water. - Rabindranath Tagore",
      "It is very important to be a master of your own mind rather than letting your mind master you. - Kapil Dev",
      "The harder the battle, the sweeter the victory. - Les Brown",
      "Don't be afraid of moving slowly. Be afraid of standing still. - Chinese Proverb",
      "We are what we repeatedly do. Excellence, then, is not an act, but a habit. - Aristotle",

      // Global Thinkers & Innovators
      "The only way to do great work is to love what you do. - Steve Jobs",
      "Your time is limited, so don't waste it living someone else's life. - Steve Jobs",
      "Stay hungry, stay foolish. - Steve Jobs",
      "An investment in knowledge pays the best interest. - Benjamin Franklin",
      "The best way to predict the future is to create it. - Abraham Lincoln",
      "I find that the harder I work, the more luck I seem to have. - Thomas Jefferson",
      "Our greatest weakness lies in giving up. The most certain way to succeed is always to try just one more time. - Thomas Edison",
      "Genius is one percent inspiration and ninety-nine percent perspiration. - Thomas Edison",
      "The secret of getting ahead is getting started. - Mark Twain",
      "Believe you can and you're halfway there. - Theodore Roosevelt",
      "A person who never made a mistake never tried anything new. - Albert Einstein",
      "Try not to become a man of success, but rather try to become a man of value. - Albert Einstein",
      "In the middle of difficulty lies opportunity. - Albert Einstein",
      "Logic will get you from A to B. Imagination will take you everywhere. - Albert Einstein",
      "The journey of a thousand miles begins with a single step. - Lao Tzu",

      // Perseverance & Hard Work
      "It does not matter how slowly you go as long as you do not stop. - Confucius",
      "Hard work beats talent when talent doesn't work hard. - Tim Notke",
      "The difference between ordinary and extraordinary is that little extra. - Jimmy Johnson",
      "Success is the sum of small efforts, repeated day in and day out. - Robert Collier",
      "There are no shortcuts to any place worth going. - Beverly Sills",
      "Push yourself, because no one else is going to do it for you. - Unknown",
      "The pain you feel today will be the strength you feel tomorrow. - Unknown",
      "It's not whether you get knocked down, it's whether you get up. - Vince Lombardi",
      "I have not failed. I've just found 10,000 ways that won't work. - Thomas Edison",
      "Amateurs practice until they get it right. Professionals practice until they can't get it wrong. - Unknown",
      "The only place where success comes before work is in the dictionary. - Vidal Sassoon",
      "I’m a greater believer in luck, and I find the harder I work the more I have of it. - Thomas Jefferson",
      "Discipline is the bridge between goals and accomplishment. - Jim Rohn",
      "Without hard work, nothing grows but weeds. - Gordon B. Hinckley",
      "If people knew how hard I worked to get my mastery, it wouldn't seem so wonderful at all. - Michelangelo",
      "Perseverance is not a long race; it is many short races one after the other. - Walter Elliot",
      "Success is no accident. It is hard work, perseverance, learning, studying, sacrifice and most of all, love of what you are doing. - Pelé",
      "You can't have a million-dollar dream with a minimum-wage work ethic. - Stephen C. Hogan",
      "The road to success is dotted with many tempting parking spaces. - Will Rogers",

      // Mindset & Belief
      "Whether you think you can, or you think you can't – you're right. - Henry Ford",
      "The expert in anything was once a beginner. - Helen Hayes",
      "Strive for progress, not perfection. - Unknown",
      "Don't be pushed around by the fears in your mind. Be led by the dreams in your heart. - Roy T. Bennett",
      "I am not a product of my circumstances. I am a product of my decisions. - Stephen Covey",
      "What you get by achieving your goals is not as important as what you become by achieving your goals. - Zig Ziglar",
      "The mind is everything. What you think you become. - Buddha",
      "If you are not willing to learn, no one can help you. If you are determined to learn, no one can stop you. - Zig Ziglar",
      "The man who says he can, and the man who says he can't are both correct. - Confucius",
      "It is our choices that show what we truly are, far more than our abilities. - J.K. Rowling",
      "Your positive action combined with positive thinking results in success. - Shiv Khera",
      "Small minds discuss people. Average minds discuss events. Great minds discuss ideas. - Eleanor Roosevelt",
      "The only limit to our realization of tomorrow will be our dreams of today. - Franklin D. Roosevelt",
      "A creative man is motivated by the desire to achieve, not by the desire to beat others. - Ayn Rand",
      "What lies behind us and what lies before us are tiny matters compared to what lies within us. - Ralph Waldo Emerson",
      "Do not wait to strike till the iron is hot; but make it hot by striking. - William Butler Yeats",
      "The will to win, the desire to succeed, the urge to reach your full potential... these are the keys that will unlock the door to personal excellence. - Confucius",
      "You are never too old to set another goal or to dream a new dream. - C.S. Lewis",
      "Act as if what you do makes a difference. It does. - William James",

      // Facing Failure & Challenges
      "Success is not final, failure is not fatal: it is the courage to continue that counts. - Winston Churchill",
      "Our greatest glory is not in never falling, but in rising every time we fall. - Confucius",
      "A smooth sea never made a skilled sailor. - Franklin D. Roosevelt",
      "Fall seven times, stand up eight. - Japanese Proverb",
      "It's hard to beat a person who never gives up. - Babe Ruth",
      "Challenges are what make life interesting and overcoming them is what makes life meaningful. - Joshua J. Marine",
      "I can accept failure, everyone fails at something. But I can't accept not trying. - Michael Jordan",
      "Everything you’ve ever wanted is on the other side of fear. - George Addair",
      "The gem cannot be polished without friction, nor man perfected without trials. - Chinese Proverb",
      "Failure is simply the opportunity to begin again, this time more intelligently. - Henry Ford",
      "What seems to us as bitter trials are often blessings in disguise. - Oscar Wilde",
       "Strength does not come from winning. Your struggles develop your strengths. - Arnold Schwarzenegger",
      "When you have a dream, you've got to grab it and never let go. - Carol Burnett",
      "Do what you can, with what you have, where you are. - Theodore Roosevelt",
      "You just can't beat the person who won't give up. - Babe Ruth",
      "A winner is a dreamer who never gives up. - Nelson Mandela",
      "When everything seems to be going against you, remember that the airplane takes off against the wind, not with it. - Henry Ford",

      // Dreams & Vision
      "All our dreams can come true, if we have the courage to pursue them. - Walt Disney",
      "The future belongs to those who believe in the beauty of their dreams. - Eleanor Roosevelt",
      "Go confidently in the direction of your dreams. Live the life you have imagined. - Henry David Thoreau",
      "The size of your success is measured by the strength of your desire; the size of your dream; and how you handle disappointment along the way. - Robert Kiyosaki",
      "A goal is a dream with a deadline. - Napoleon Hill",
      "You are the master of your destiny. You can influence, direct and control your own environment. You can make your life what you want it to be. - Napoleon Hill",
      "If your dreams don’t scare you, they are too small. - Richard Branson",
      "The tragedy of life doesn't lie in not reaching your goal. The tragedy lies in having no goal to reach. - Benjamin E. Mays",
      "Without dreams and goals, there is no living, only merely existing, and that is not why we are here. - Mark Twain",
      "Set a goal so big that you can't achieve it until you grow into the person who can. - Zig Ziglar",
      "The distance between your dreams and reality is called action. - Unknown",
      "Dream big and dare to fail. - Norman Vaughan",
      "If you can imagine it, you can achieve it. If you can dream it, you can become it. - William Arthur Ward",
      "Never give up on a dream just because of the time it will take to accomplish it. The time will pass anyway. - Earl Nightingale",
      "A dream does not become reality through magic; it takes sweat, determination, and hard work. - Colin Powell",
      "There is only one thing that makes a dream impossible to achieve: the fear of failure. - Paulo Coelho",
      "Dreams are the seedlings of realities. - James Allen",
      "The biggest adventure you can take is to live the life of your dreams. - Oprah Winfrey",
      "To accomplish great things, we must not only act, but also dream; not only plan, but also believe. - Anatole France",

      // Action & Procrastination
      "Don't watch the clock; do what it does. Keep going. - Sam Levenson",
      "The way to get started is to quit talking and begin doing. - Walt Disney",
      "A year from now you may wish you had started today. - Karen Lamb",
      "Action is the foundational key to all success. - Pablo Picasso",
      "You don't have to be great to start, but you have to start to be great. - Zig Ziglar",
      "Do not wait for the perfect time and place to enter, for you are already onstage. - Unknown",
      "The value of an idea lies in the using of it. - Thomas Edison",
      "Thinking will not overcome fear but action will. - W. Clement Stone",
      "Your future is created by what you do today, not tomorrow. - Robert Kiyosaki",
      "Procrastination is the thief of time. - Edward Young",
      "Take the first step in faith. You don't have to see the whole staircase, just take the first step. - Martin Luther King Jr.",
      "Someday is not a day of the week. - Janet Dailey",
      "The best time to plant a tree was 20 years ago. The second best time is now. - Chinese Proverb",
      "Don't let what you cannot do interfere with what you can do. - John Wooden",
      "To think too long about doing a thing often becomes its undoing. - Eva Young",
      "If you spend too much time thinking about a thing, you'll never get it done. - Bruce Lee",
      "The great aim of education is not knowledge but action. - Herbert Spencer",
      "Small deeds done are better than great deeds planned. - Peter Marshall",
      "Well done is better than well said. - Benjamin Franklin",

      // More from Indian Icons
      "My religion is very simple. My religion is kindness. - Dalai Lama",
      "All power is within you; you can do anything and everything. - Swami Vivekananda",
      "Take risks in your life. If you win, you can lead. If you lose, you can guide. - Swami Vivekananda",
      "Thinking is the capital, Enterprise is the way, Hard Work is the solution. - A.P.J. Abdul Kalam",
      "Man needs his difficulties because they are necessary to enjoy success. - A.P.J. Abdul Kalam",
      "Strength is Life, Weakness is Death. - Swami Vivekananda",
      "You have to grow from the inside out. None can teach you, none can make you spiritual. There is no other teacher but your own soul. - Swami Vivekananda",
      "Be the change that you wish to see in the world. - Mahatma Gandhi",
      "First they ignore you, then they laugh at you, then they fight you, then you win. - Mahatma Gandhi",
      "An eye for an eye will only make the whole world blind. - Mahatma Gandhi",
      "Don't limit a child to your own learning, for he was born in another time. - Rabindranath Tagore",
      "True leaders are those who help others to be leaders. - Bill Gates (relevant for group study)",
      "Patience is a key element of success. - Bill Gates",
      "It's fine to celebrate success but it is more important to heed the lessons of failure. - Bill Gates",
      "If you are born poor it's not your mistake, but if you die poor it's your mistake. - Bill Gates",
      "We cannot solve our problems with the same thinking we used when we created them. - Albert Einstein",
      "Education is the most powerful weapon which you can use to change the world. - Nelson Mandela",
      "It always seems impossible until it's done. - Nelson Mandela",
      "I learned that courage was not the absence of fear, but the triumph over it. - Nelson Mandela",

      // Final Boosters
      "The future starts today, not tomorrow. - Pope John Paul II",
      "Either you run the day or the day runs you. - Jim Rohn",
      "Believe in yourself and all that you are. Know that there is something inside you that is greater than any obstacle. - Christian D. Larson",
      "The successful warrior is the average man, with laser-like focus. - Bruce Lee",
      "In order to succeed, we must first believe that we can. - Nikos Kazantzakis",
      "With the new day comes new strength and new thoughts. - Eleanor Roosevelt",
      "The secret of your future is hidden in your daily routine. - Mike Murdock",
      "Quality is not an act, it is a habit. - Aristotle",
      "Setting goals is the first step in turning the invisible into the visible. - Tony Robbins",
      "If you're going through hell, keep going. - Winston Churchill",
      "What you do today can improve all your tomorrows. - Ralph Marston",
      "A little progress each day adds up to big results. - Satya Nani",
      "The key is not to prioritize what's on your schedule, but to schedule your priorities. - Stephen Covey",
      "Focus on being productive instead of busy. - Tim Ferriss",
      "You are capable of more than you know. - Glinda the Good Witch",
      "The day you plant the seed is not the day you eat the fruit. - Unknown",
      "Doubt kills more dreams than failure ever will. - Suzy Kassem",
      "Work hard in silence, let your success be your noise. - Frank Ocean",
      "Success doesn't just find you. You have to go out and get it. - Unknown",
      "Don't stop when you're tired. Stop when you're done. - Unknown",
    ];
    // Return a random quote
    final modifiableQuotes = List<String>.from(quotes);
    modifiableQuotes.shuffle();
    return modifiableQuotes.first;
  }

  // --- NEW BATTLE MESSAGES ---
// --- UPDATED BATTLE MESSAGES (Handles Win, Loss, and Draw) ---
  String getBattleMessage(String result) {
    if (result == 'win') {
      const wins = [
        "Victory! You showed them who's boss! 🏆",
        "Woohoo! Another win for the Formula Racing team! 🏎️💨",
        "You crushed it! My bamboo tastes sweeter with victory. 🐼✨",
        "Champion! That was amazing. +10 Bamboo for us! 🎋",
        "Speed and precision! You are the Formula 1 of math. 🏁",
        "Winner winner, bamboo dinner! Great job! 🍽️",
        "That was legendary! You left them in the dust. 💨",
        "High five! You're unstoppable today. ✋",
        "Victory tastes sweet! Like fresh bamboo shoots. 🎍",
        "You're on fire! The competition didn't stand a chance. 🔥",
        "Bohot hard! You totally dominated that match. 💪",
        "King of the track! That win was well deserved. 👑",
        "Smooth operator! You made winning look easy. 😎",
        "That's how it's done! Another trophy for the shelf. 🏆",
        "You're a natural! Keep this winning streak alive. 🌟"
      ];
      return getRandomMessage(wins);
    }
    else if (result == 'draw') {
      const draws = [
        "It's a tie! Two speedsters crossing the line together. 🏁",
        "A draw! You are both equally matched geniuses. 🤝",
        "No winner today, just two champions! +5 Bamboo. 🐼",
        "Wow! Exact same score. That was a tight race! ⚖️",
        "Stalemate! You both played amazingly well. ✨",
        "A dead heat! Neither of you gave an inch. 🏎️",
        "Perfectly balanced, as all things should be. A draw! ⚖️",
        "Close call! It ended in a tie. Good game! 🎮"
      ];
      return getRandomMessage(draws);
    }
    else {
      // Result is 'loss'
      const losses = [
        "Ouch! That was close. Don't worry, we'll get them next time! 💪",
        "It's okay! Even the fastest racers need a pit stop. 🛑",
        "Defeat is just fuel for the next victory. Let's try again! 🔥",
        "Don't give up! Review your mistakes and come back stronger. 🧠",
        "A minor setback for a major comeback. You got this! 🚀",
        "So close! Next time, that win is ours. 🤝",
        "Chin up, racer! The track is still waiting for you. 🏎️",
        "Learning from defeat is the first step to victory. 📚",
        "No worries! Shake it off and let's race again. 🔄",
        "That was a tough one! But I believe in you. ❤️",
        "Even champions lose sometimes. It's about how you get back up! 🥊",
        "Take a deep breath. We'll crush them in the rematch! 😤",
        "Good effort! Just a little more speed next time. ⚡",
        "Don't let it get to you. You're still a winner in my eyes! 🐼",
        "Review the replay, find the gap, and win the next lap! 🏁"
      ];
      return getRandomMessage(losses);
    }
  }

  // --- NEW MISTAKES CLEARED MESSAGES ---
  String getMistakesClearedMessage(int count) {
    // SCENARIO: 0 Mistakes Resolved (Tried but failed)
    if (count == 0) {
      const messages = [
        "Koi baat nahi! Bade bade deshon mein aisi chhoti baatein hoti rehti hain. 🕊️",
        "Zero resolved? Aryabhata would be proud, but let's change it! 🍩",
        "Oof! Clean bowled on the first ball? Agli baar sixer marenge! 🏏",
        "Aaj din nahi tha. Kal phod denge! 🌅",
        "System hang ho gaya kya? Restart and try again! 💻",
        "No worries! Even Virat Kohli gets out on a duck sometimes. 🦆",
        "Khata nahi khula? Koi na, abhi poori match baaki hai. 📖",
        "It happens! Gir kar hi uthne wale ko Baazigar kehte hain. 🎭",
        "Zero? It's just a circle waiting to be turned into a 100. 💯",
        "Arey tension nahi lene ka! Chill maar, phir try kar. 🥤",
        "Oops! The questions were tough, or you were sleepy? 😴",
        "Blank slate! Drawing board pe wapas jao. 🎨",
        "Mission failed! We'll get 'em next time. 🕵️‍♂️",
        "Lagta hai aaj brain holiday pe hai. Wapas bulao! 🏖️",
        "Zero progress? Nah, you just found ways that don't work. Edison style! 💡",
        "Thoda focus aur! Agli baar pakka clear hoga. 🎯",
        "Bhai/Behen, kya kar raha hai? Jago grahak jago! 🔔",
        "No mistakes cleared? Maybe they are stubborn. You be stubborn-er! 😤",
        "Aaj ka score: 0. Kal ka target: Hero. 🦸‍♂️",
        "Galti sudharna mushkil hai, namumkin nahi. Don 3 loading... 🎬",
        "Warm-up khatam. Ab asli game shuru karo! 🏁",
        "Sannata kyu hai bhai? Tod phod machao next time! 💥",
        "Zero resolved. Dil chhota na kar, effort matter karta hai. ❤️",
        "Lagta hai questions ne dosti kar li galti se. Break the bond! 💔",
        "Try, try, but don't cry. Agli baar pakka fly! 🦋",
        "Aaj luck kharab tha. Kal hard work chalega. 🛠️",
        "Zero? It's a shape. A shape of resilience! (Just kidding, try again). 😜",
        "Hota hai, chalta hai, duniya hai. Next attempt will be better! 🌍",
        "Brain.exe stopped working? Reboot and attack! 🤖",
        "Khali haath aaye the, khali haath... nahi jayenge next time! 👊"
      ];
      return getRandomMessage(messages);
    }
    // SCENARIO: 1 Mistake Resolved
    else if (count == 1) {
      const messages = [
        "One less mistake! 🎯 Ek galti maaf, but seekh li na?",
        "Boom! One error deleted. Shuddhikaran complete! 🧘‍♂️",
        "Nice! That's one concept mastered. Dimag ki batti jali? 💡",
        "Small steps, big wins. Boond boond se sagar banta hai! 🌊",
        "One down! Slow and steady wins the race, mere dost. 🐢",
        "Mistake cleared! Ab ye galti sapne mein bhi nahi hogi. 😴",
        "Ek galti sudhari, life set! Keep going. 🚀",
        "One error fixed. You are becoming a Pro, dheere dheere! 😎",
        "Shabaash! One weak spot is now your strong point. 💪",
        "Oops moment fixed! Ab ye question exam mein aane do. 🥊",
        "One mistake gone. Safai abhiyan shuru! 🧹",
        "Good job! Ek aur concept clear. Confidence badha? 📈",
        "That's one less trap for you in the exam. Bach gaye! 😅",
        "Mistake resolved! You 1 - 0 Confusion. 🏆",
        "Ek kadam safalta ki aur. One step closer to IIT! 🎓",
        "Fixed it! Galti se mistake ab nahi hogi. 🚫",
        "One doubt crushed. Maza aaya? 🐼",
        "Sahi pakde hain! One error corrected perfectly. 👌",
        "One mistake less. You are polishing your brain diamond! 💎",
        "Correction done. Ab ye topic makkhan hai! 🧈",
        "Ek galti gayi paani mein... chapaak! (But you saved it). 🐸",
        "One hurdle crossed. Ab aage badho! 🏃‍♂️",
        "Mistake fixed. Your brain just got a software update. 📲",
        "Ek aur concept lock kiya jaye? Bilkul sahi! 🔒",
        "One error down. Darr ke aage jeet hai! 🏔️",
        "Fixed one! Chhota packet, bada dhamaka. 💥",
        "Mistake gone! Ab tension lene ka nahi, dene ka. 🕶️",
        "One less red mark. Green signals ahead! 🚦",
        "Sudhar gaya! One mistake is history now. 📜",
        "Ek galti kam. You are getting smarter by the second! 🧠"
      ];
      return getRandomMessage(messages);
    }
    // SCENARIO: 2-4 Mistakes Resolved
    else if (count < 5) {
      final messages = [
        "Great job! 🧹 You cleared $count mistakes! Jhadu laga diya!",
        "Cleaning up nicely! $count errors gone. Chamka diya boss! ✨",
        "You're crushing it! $count weak spots fixed. Bahut hard! 💪",
        "Progress! $count questions ab kabhi galat nahi honge. 🔥",
        "$count mistakes resolved. You are on a roll today! 🎲",
        "Waah! $count doubts cleared. Dimag tez ho raha hai. ⚡",
        "Solid comeback! $count errors fixed. Ab darna mana hai. 🚫",
        "$count mistakes down. Exam paper ki toh wat lag jayegi! 📝",
        "Keep it up! $count concepts are now crystal clear. 💎",
        "Badhiya! $count galtiyan sudhar li. Improvement dikh raha hai! 📈",
        "$count errors gone. You are cleaning up your act! 🧼",
        "Nice streak! $count mistakes resolved. Ruke na tu! 🚀",
        "$count problems solved. You are becoming a legend! 🦁",
        "Good going! $count less things to worry about. Chill maar! 🍹",
        "$count mistakes fixed. Ab ye topics halwa hain! 🍲",
        "Shabaash! $count concepts ab pakke ho gaye. 🧱",
        "$count errors deleted. System cleaning in progress... 🤖",
        "You fixed $count mistakes! Mummy will be proud. 👩‍👦",
        "$count doubts crushed. You are a problem solver! 🧩",
        "Awesome! $count mistakes won't haunt you anymore. 👻",
        "$count corrections! Dheere dheere expert ban rahe ho. 🎓",
        "Well done! $count mistakes cleared. Picture abhi baaki hai! 🎬",
        "$count errors fixed. You are sharpening your axe! 🪓",
        "Sahi ja rahe ho! $count mistakes down. Manzil kareeb hai. 🏁",
        "$count doubts gone. Brain fog clearing up! 🌫️",
        "You resolved $count mistakes. Confidence level: High! 🌡️",
        "$count errors bye-bye. Tata, khatam, gaya! 👋",
        "Nice work! $count mistakes fixed. Ab party toh banti hai? 🍕",
        "$count corrections done. You are building a fortress! 🏰",
        "Superb! $count mistakes cleared. You are unstoppable! 🛑"
      ];
      return getRandomMessage(messages);
    }
    // SCENARIO: 5+ Mistakes Resolved
    else {
      final messages = [
        "Wow! $count mistakes gone! 🚀 Aaj toh phod diya!",
        "Massive cleanup! $count errors destroyed. Tsunami la di! 🌊",
        "Unstoppable! $count concepts mastered. Kya baat hai! 👏",
        "Legendary session! $count mistakes resolved. Salute hai boss! 🫡",
        "You are a machine! $count problems solved. Robot ho kya? 🤖",
        "Mind-blowing! $count errors fixed. Toofan mail on fire! 🚂",
        "$count mistakes cleared! You are in Beast Mode today! 🦍",
        "Incredible! $count doubts crushed. Exam ki toh band bajegi! 🥁",
        "$count corrections! You are rewriting your destiny. ✍️",
        "Oof! $count mistakes gone. Safai abhiyan level: Pro! 🧹",
        "You fixed $count errors! Is this the power of almonds? 🥜",
        "$count mistakes down! You are eating problems for breakfast. 🥣",
        "Insane progress! $count concepts mastered. Chha gaye guru! 🌟",
        "$count errors deleted. Your brain is running on 5G now! 📶",
        "What a comeback! $count mistakes resolved. Sher jaag gaya! 🦁",
        "$count doubts cleared! You are basically a genius now. 🧠",
        "Epic! $count mistakes fixed. History create kar rahe ho! 📜",
        "$count corrections! You are unstoppable like a rocket. 🚀",
        "Boom! $count errors gone. Surgical strike on mistakes! 💥",
        "You resolved $count mistakes! Sharmaji ka beta who? 🤷‍♂️",
        "$count mistakes down! You are playing in the big leagues now. 🏏",
        "Fantastic! $count errors fixed. Ab koi nahi rok sakta! 🛑",
        "$count concepts clear! You are building an empire of knowledge. 🏰",
        "Sensational! $count mistakes gone. Aaj toh kamaal kar diya! 🌹",
        "$count errors crushed. You are the Bahubali of studies! ⚔️",
        "You fixed $count mistakes! That's some serious dedication. 🙏",
        "$count doubts resolved. You are winning at life! 🏆",
        "Crazy good! $count mistakes cleared. Aag laga di! 🔥",
        "$count corrections! You are polishing your skills to perfection. ✨",
        "Masterclass! $count mistakes gone. Take a bow, champion! 🙇‍♂️"
      ];
      return getRandomMessage(messages);
    }
  }

  String getRandomMessage(List<String> messages) {
    if (messages.isEmpty) return "";
    // Ensure you have 'import 'dart:math';' at the top of the file
    return messages[DateTime.now().millisecondsSinceEpoch % messages.length];
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

      final messages = [
        "I see you're avoiding '$chapterToSuggest'. Darr lag raha hai kya? 😉 Let's try it!",
        "The chapter '$chapterToSuggest' is feeling lonely. Let's give it some attention! 😂",
        "Psst... '$chapterToSuggest' is an unexplored territory. Time for an adventure? 🗺️",
        "You haven't touched '$chapterToSuggest' yet. Is it the 'Sharmaji ka beta' of chapters? Let's beat it! 💪",
        "'$chapterToSuggest' is waiting for you. Don't leave it on 'seen'. 😜",
        "Let's try some questions from '$chapterToSuggest'. What's the worst that could happen? 🤔",
        "New chapter unlocked: '$chapterToSuggest'. Ready to play this level? 🎮",
        "You've been ghosting '$chapterToSuggest'. Time to face your fears! 👻",
        "I dare you to try a few questions from '$chapterToSuggest'. Challenge accepted? 😎",
        "'$chapterToSuggest' is calling your name. Let's see what it has to say. 📞",
        "Let's give '$chapterToSuggest' a shot. It's not as scary as it looks, promise! 🙏",
        "You've mastered others, but '$chapterToSuggest' is still a mystery. Let's solve it! 🕵️",
        "Time to say 'Hi' to '$chapterToSuggest'. It won't bite! 🐍",
        "Let's break the ice with '$chapterToSuggest'. You might actually like it! 😊",
        "Are you and '$chapterToSuggest' in a fight? Let's make up by trying a few questions. 😂",
        "'$chapterToSuggest' is like the final boss of a game you haven't started. Let's go! 👾",
        "Let's add '$chapterToSuggest' to your list of conquered chapters. Ready for battle? ⚔️",
        "The only thing to fear is fear itself... and maybe '$chapterToSuggest'? Let's find out! 🧐",
        "You've been swiping left on '$chapterToSuggest'. Let's give it a 'super like'! ✨",
        "Let's see if you can handle the 'josh' of '$chapterToSuggest'. How's the josh? High sir! 💪",
        "What's the deal with '$chapterToSuggest'? Let's investigate and crack the case. 🔍",
        "'$chapterToSuggest' is the new trend. Let's see what the hype is about. 😉",
        "You've left '$chapterToSuggest' on the bench. Time to put it in the game! 🏏",
        "Let's take a small detour to '$chapterToSuggest'. It might be a scenic route! 🏞️",
        "Be a hero and tackle '$chapterToSuggest'. Your future self will thank you. 🦸",
        "Let's see if '$chapterToSuggest' is as tough as they say. Spoilers: it's not. 😎",
        "You've got 99 problems but '$chapterToSuggest' ain't one... yet. Let's try it! 😜",
        "Time to face the music and try '$chapterToSuggest'. Let's make it a hit song! 🎶",
        "Let's give '$chapterToSuggest' a try. It's easier than talking to your crush, promise. 😂",
        "The chapter '$chapterToSuggest' is like that one street food you're scared to try. Let's be brave! 🌶️"
      ];

      // Get a random message from the list and add it to possible insights
      final randomMessage = messages[_random.nextInt(messages.length)];
      possibleInsights.add(randomMessage);
    }

    // 4. Logic for Attempted Chapters
    for (final performance in performanceByChapter) {
      if (performance.totalAttempts < 3) continue; // Ignore chapters with too few attempts

      final accuracyPercent = (performance.accuracy * 100).round();
      final chapterName = performance.chapterName;

      // --- Start of Replacement ---

      if (accuracyPercent >= 90) {
        final messages = [
          "Mastered: '$chapterName' is strong ($accuracyPercent%). Move on. ✅",
          "Solid: You own '$chapterName' ($accuracyPercent%). No revision needed. 🏆",
          "Excellent: '$chapterName' is done ($accuracyPercent%). Focus elsewhere. 🚀",
          "Top Tier: '$chapterName' is your strength ($accuracyPercent%). Keep it up. 💪",
          "Perfect: You know '$chapterName' inside out ($accuracyPercent%). Great job. 🌟",
          "Expert: '$chapterName' is fully understood ($accuracyPercent%). 🥇",
          "Done: '$chapterName' is secured ($accuracyPercent%). Don't waste time here. ⏱️",
          "Strong: Your '$chapterName' concepts are clear ($accuracyPercent%). ✨",
          "Pro: You are a pro at '$chapterName' ($accuracyPercent%). Next topic! ⏭️",
          "Secured: Marks for '$chapterName' are safe ($accuracyPercent%). 🔒",
          "Elite: Top 1% performance in '$chapterName' ($accuracyPercent%). 💎",
          "Complete: '$chapterName' syllabus is finished ($accuracyPercent%). 🏁",
          "Ready: You are exam-ready for '$chapterName' ($accuracyPercent%). 🎓",
          "Sharp: Your mind is sharp on '$chapterName' ($accuracyPercent%). 🧠",
          "Easy: '$chapterName' is too easy for you ($accuracyPercent%). Skip it. ⏭️",
          "King: You rule the '$chapterName' kingdom ($accuracyPercent%). 👑",
          "Legend: Legendary score in '$chapterName' ($accuracyPercent%). 🦁",
          "Peak: You reached peak performance in '$chapterName' ($accuracyPercent%). 🏔️",
          "Sorted: '$chapterName' is sorted ($accuracyPercent%). Relax. 🧘",
          "Champ: Champion level in '$chapterName' ($accuracyPercent%). 🥊",
          "Clean: Clean sweep in '$chapterName' ($accuracyPercent%). 🧹",
          "Boss: You defeated the '$chapterName' boss ($accuracyPercent%). 👾",
          "Star: Gold star for '$chapterName' ($accuracyPercent%). ⭐",
          "Limitless: No limits for you in '$chapterName' ($accuracyPercent%). 🌌",
          "Speed: You solve '$chapterName' fast and right ($accuracyPercent%). ⚡",
          "Power: High power level in '$chapterName' ($accuracyPercent%). 🔋",
          "Magic: You are a wizard at '$chapterName' ($accuracyPercent%). 🧙‍♂️",
          "A+: Grade A+ for '$chapterName' ($accuracyPercent%). 💯",
          "Win: Big win in '$chapterName' ($accuracyPercent%). 🏅",
          "Best: This is your best topic: '$chapterName' ($accuracyPercent%). 🔝"
        ];
        possibleInsights.add(messages[_random.nextInt(messages.length)]);

      } else if (accuracyPercent >= 50) {
        final messages = [
          "Average: '$chapterName' needs work ($accuracyPercent%). Revise today. ⚠️",
          "Gap: You only know half of '$chapterName' ($accuracyPercent%). Study more. 📉",
          "Inconsistent: '$chapterName' is shaky ($accuracyPercent%). Fix your errors. 🛠️",
          "Practice: '$chapterName' is not exam-ready ($accuracyPercent%). Do more questions. 📝",
          "Mediocre: $accuracyPercent% in '$chapterName' isn't enough. Push harder. 👊",
          "Review: You are missing concepts in '$chapterName' ($accuracyPercent%). Read notes. 📖",
          "Unfinished: '$chapterName' needs polish ($accuracyPercent%). Don't settle. 🚫",
          "Focus: '$chapterName' is weak in parts ($accuracyPercent%). Identify them. 🔍",
          "Push: Turn this $accuracyPercent% in '$chapterName' into a 90%. You can do it. 🔼",
          "Not Enough: '$chapterName' is just okay ($accuracyPercent%). Aim higher. 🎯",
          "Warning: Don't get comfortable with '$chapterName' ($accuracyPercent%). Improve it. 🔔",
          "Action: Solve 10 more questions on '$chapterName' ($accuracyPercent%). Now. 🔟",
          "Analysis: Check what you got wrong in '$chapterName' ($accuracyPercent%). Fix it. 🧐",
          "Potential: '$chapterName' is decent ($accuracyPercent%) but needs mastery. 🚀",
          "Alert: You are guessing in '$chapterName' ($accuracyPercent%). Stop guessing. 🛑",
          "Refine: Your '$chapterName' basics are fine, but advanced is weak ($accuracyPercent%). ⚖️",
          "Study: $accuracyPercent% means you missed half the chapter '$chapterName'. Read up. 📚",
          "Drill: Practice '$chapterName' formulas again ($accuracyPercent%). 🔢",
          "Improve: '$chapterName' score is average ($accuracyPercent%). Be exceptional. ⭐",
          "Work: '$chapterName' requires more effort ($accuracyPercent%). Don't be lazy. 🏋️",
          "Attention: Small mistakes in '$chapterName' are costing you ($accuracyPercent%). ⚠️",
          "Target: Aim for full marks in '$chapterName', not just $accuracyPercent%. 🥅",
          "Reminder: '$chapterName' is important. $accuracyPercent% won't cut it. 📌",
          "Status: '$chapterName' is a 'Work in Progress' ($accuracyPercent%). Finish it. 🚧",
          "Challenge: Retake '$chapterName' and beat $accuracyPercent%. ⚔️",
          "Note: You are stuck at average in '$chapterName' ($accuracyPercent%). Break through. 🔨",
          "Advice: Don't ignore '$chapterName' ($accuracyPercent%). It needs time. ⏳",
          "Fact: $accuracyPercent% in '$chapterName' is passable, not great. Do better. 😐",
          "Plan: Revise '$chapterName' notes tonight ($accuracyPercent%). 🌙",
          "Goal: Get '$chapterName' to 100%. You are at $accuracyPercent%. 💯"
        ];
        possibleInsights.add(messages[_random.nextInt(messages.length)]);

      } else {
        final messages = [
          "Weak: '$chapterName' is critical ($accuracyPercent%). Study immediately. 🚨",
          "Fail: '$chapterName' score is too low ($accuracyPercent%). Open your book. 📚",
          "Alert: You are guessing in '$chapterName' ($accuracyPercent%). Learn basics. 🛑",
          "Bad: '$chapterName' needs serious attention ($accuracyPercent%). Do not ignore. ❌",
          "Critical: You don't know '$chapterName' ($accuracyPercent%). Watch a tutorial. 📺",
          "Action: Revise '$chapterName' now ($accuracyPercent%). You are losing marks. 📉",
          "Danger: '$chapterName' is a red flag ($accuracyPercent%). Fix it. 🚩",
          "Zero: Concepts missing in '$chapterName' ($accuracyPercent%). Start from scratch. 🔄",
          "Urgent: '$chapterName' is your weakest link ($accuracyPercent%). Fix it today. 🚑",
          "Stop: Don't play '$chapterName' again until you study ($accuracyPercent%). ✋",
          "Serious: $accuracyPercent% in '$chapterName' is dangerous. Wake up. ⏰",
          "Help: Ask a teacher about '$chapterName' ($accuracyPercent%). You are stuck. 🙋",
          "Restart: Read '$chapterName' from page 1 ($accuracyPercent%). 📖",
          "Focus: Drop everything and study '$chapterName' ($accuracyPercent%). 🎯",
          "Error: Too many mistakes in '$chapterName' ($accuracyPercent%). Analyze them. 🚫",
          "Warning: You will fail this topic '$chapterName' ($accuracyPercent%) without study. ⚠️",
          "Poor: '$chapterName' performance is very poor ($accuracyPercent%). Work harder. 📉",
          "Gap: Huge knowledge gap in '$chapterName' ($accuracyPercent%). Fill it. 🕳️",
          "Crisis: '$chapterName' is in crisis mode ($accuracyPercent%). Save it. 🆘",
          "No: You cannot ignore '$chapterName' ($accuracyPercent%). It will haunt you. 👻",
          "Basic: You lack fundamentals in '$chapterName' ($accuracyPercent%). Go back. 🔙",
          "Hard Work: '$chapterName' needs 100% effort now ($accuracyPercent%). 😤",
          "Reality: You don't know '$chapterName' ($accuracyPercent%). Accept and learn. 🧠",
          "Plan: Schedule 1 hour for '$chapterName' today ($accuracyPercent%). 🗓️",
          "Advice: Watch a video on '$chapterName' ($accuracyPercent%). You are confused. 🎥",
          "Task: Write down all formulas for '$chapterName' ($accuracyPercent%). 📝",
          "Low: $accuracyPercent% is not acceptable for '$chapterName'. Push up. 🔼",
          "Risk: High risk of losing marks in '$chapterName' ($accuracyPercent%). ⚡",
          "Must Do: '$chapterName' is mandatory. Learn it ($accuracyPercent%). ❗",
          "Start: You haven't started learning '$chapterName' properly ($accuracyPercent%). Begin. ▶️"
        ];
        possibleInsights.add(messages[_random.nextInt(messages.length)]);
      }

// --- End of Replacement ---




    }

    // 5. Select and Return an Insight
    // 5. Select and Return an Insight
    if (possibleInsights.isEmpty) {
      // This block runs if the user has played, but not enough questions in any single chapter
      // to generate specific advice. We give them a general nudge instead.
      final averageScore = performanceByChapter.map((p) => p.accuracy).average;
      if (averageScore >= 0.7) {
        const messages = [
          "You're doing great! Just play a few more questions in one chapter so I can give you some solid advice. 👍",
          "Good start! I'm still gathering data. Play a bit more in one topic and I'll have some tips for you. 📊",
          "You're warming up nicely! Focus on one chapter for a few more questions to unlock detailed insights. 🗝️",
          "Nice! You're exploring a lot. Settle on one chapter for a bit, and I can give you a proper analysis. 🕵️",
          "Keep this energy up! I need a little more data from a single chapter to give you pro-level advice. 🚀"
        ];
        return messages[_random.nextInt(messages.length)];
      } else {
        const messages = [
          "Good first attempt! Play a few more questions in one chapter, and I can help you pinpoint where to focus. 🎯",
          "Every journey starts with a single step! Play some more in one topic so I can guide you better. 🗺️",
          "Keep going! The more you play in one chapter, the better I can understand your style and help you out.🤝",
          "You've started the engine! Now let's go for a short drive in one chapter to see how it handles. 🚗",
          "Don't stop now! A few more questions in one chapter is all I need to give you some killer advice. 😎"
        ];
        return messages[_random.nextInt(messages.length)];
      }
    }

    return possibleInsights[_random.nextInt(possibleInsights.length)];
  }

  Future<String> getGeneralAppAdvice() async {
    // We group advice by category to ensure users see a variety of tips.
    const adviceByCategory = {

      'creator': [
        "Fun Fact: This app was made by Rakesh, an IIT Madras grad, to make revision less boring. Pretty cool, right? ✨",
        "This app was built by a guy from IIT Madras who got tired of seeing his students bored during revision. 😉",
        "My creator, Rakesh, made me to spice up your revision. Hope you're having fun! 🎉",
        "Want more tips? My creator has a YouTube channel: 'Physics with Rakesh | IIT Madras'. Check it out! 📺",
        "For more cool concepts, search for 'Physics with Rakesh | IIT Madras' on YouTube! 🚀"
      ],
      'formulas': [
        "Feeling lost in formulas? Just tap 'Revise all formulas' right here on the home screen. Sorted! 📜",
        "Psst! All the formulas you'll ever need are just a tap away. Look for 'Revise all formulas' on the home screen! 🕵️",
        "Forget a formula? No stress! Just hit 'Revise all formulas' on the main screen. Easy peasy. 😎",
        "Did you know? You can pin important formulas to move them to the top of the list! 📌",
        "Found a tricky formula? Just pin it! It will jump to the top for quick access. ✨",
        "Don't just read the formulas, pin the important ones so they're always at the top waiting for you! 📌"
        "When i say 90 % in Laws of Motion, i mean your accuracy percentage for all attempted questions in laws of Motion chapter is 90 %"
      ],
      'solo': [
        "Think you're a pro? 'Play Solo' gives you 10 questions that get tougher and tougher. Dum hai? 💪",
        "Heads up: 'Play Solo' isn't a walk in the park. The questions get harder as you go. 🔥",
        "Wanna test yourself? 'Play Solo' mode has 10 questions with increasing difficulty. Let's see what you've got! 🚀",
        "Chapter colors show your attempted questions percentage: 🔴(<40%) 🟠(40-70%) 🟢(>70%). Aim for Green!",
        "Quick Tip: Chapter colors track your progress. Red needs work, Green means you're a pro! 📊",
        "See the chapter colors? Your goal is to turn them all Green (>70%)! ✅"
      ],
      'friend': [
        "Studying alone is boring! Challenge your friends using 'Play Friend' and show 'em who's boss. 🏆",
        "Why practice alone? Use 'Play Friend' to make things more exciting. Loser treats, maybe? 😉",
        "Make revision fun! Grab a friend and battle it out in 'Play Friend'. Game on! 🎮",
      ],
      'mistakes': [
        "Every mistake you make is saved in 'My Mistakes'. It's your own personal 'what-not-to-do' list! 😂",
        "Want to see where you're going wrong? Check out 'My Mistakes'. It's your secret weapon for improvement. 🤫",
        "Once you've mastered your errors, hit 'Clear Mistakes' to delete them forever. Bye-bye, silly mistakes! 👋",
      ],

    };

    // 1. Move to the next category in a cycle.
    _lastAdviceCategoryIndex = (_lastAdviceCategoryIndex + 1) % adviceByCategory.length;

    // 2. Get the list of messages for the current category.
    final categoryKeys = adviceByCategory.keys.toList();
    final currentCategoryKey = categoryKeys[_lastAdviceCategoryIndex];
    final messagesForCategory = adviceByCategory[currentCategoryKey]!;

    // 3. Return a random message from within that category.
    return messagesForCategory[_random.nextInt(messagesForCategory.length)];
  }

}