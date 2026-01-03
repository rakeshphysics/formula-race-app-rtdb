// ----------------------------------------------------
// HomeScreen.dart — Corrected version based on your original
// - Solo Play button → unchanged
// - Online Play button → unchanged
// - AI Tracker button → now active (Chunk 3 updated)
// - Bottom text → unchanged
// ----------------------------------------------------

import 'package:flutter/material.dart';
//import 'solo_screen.dart';
//import 'online_play_screen.dart';
import 'solo_mode_selection_screen.dart';
import 'ai_tracker_screen.dart'; // Add this import
import 'package:shared_preferences/shared_preferences.dart';
//import 'searching_for_opponent.dart';
//import 'dart:io';
//import 'package:firebase_auth/firebase_auth.dart';
//import 'package:formularacing/services/matchmaking_service.dart'; // For MatchmakingService
//import 'package:formularacing/screens/qr_host_screen.dart';
import 'multiplayer_selection_screen.dart';
import 'package:flutter/services.dart';
//import 'package:cupertino_icons/cupertino_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../services/home_message_service.dart';
import 'package:formularacing/screens/info_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:formularacing/services/database_helper.dart';
import 'package:characters/characters.dart';
import 'package:formularacing/screens/revise_chapter_selection_screen.dart';





// Add this enum at the top of the file, outside the class
enum AiMessageTrigger {
  dailyGreeting,      // For normal app startup
  postGameAnalysis,   // For right after a game
}

// Add this enum at the top of the file
enum PandaConversationStage {
  idle,                   // Nothing is happening
  showingPostGameAnalysis,  // A: Post-test summary
  showingDetailedAdvice,    // B: Specific advice (e.g., "Focus on Fluids")
  showingFirstMotivation,   // C: First tailored motivation
  showingSecondMotivation,  // D: Second tailored motivation
  showingAppAdvice,         // E: General app tip
}

// ----------------------------------------------------
// HomeScreen Widget
// ----------------------------------------------------
class HomeScreen extends StatefulWidget {
  final String userId;
  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {  Timer? _typingTimer;
  Timer? _pandaUpdateTimer;
  int _charIndex = 0;
  String _fullAiMessage = "Loading...";
  String _displayedAiMessage = "";
  int _bamboos = 0;
  String _currentPandaLottie = 'assets/pandaai/meditate.json';
  bool _isTalking = false;
  bool _showMealButtons = false;
  PandaConversationStage _conversationStage = PandaConversationStage.idle;
  String? _adviceMessage;
  bool _postGameAnalysisTriggered = false;



  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkForNewBamboos(); // Check for bamboos on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstTimeUser();
    });
    _updatePandaAnimation();
    _pandaUpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updatePandaAnimation();
    });
  }

void _loadAiMessage({required AiMessageTrigger trigger}) async {
  if (_isTalking) return;

  final messageService = HomeMessageService.instance;

  if (trigger == AiMessageTrigger.postGameAnalysis) {
    //_conversationStage = PandaConversationStage.showingPostGameAnalysis;
    _conversationStage = PandaConversationStage.showingDetailedAdvice;
    _adviceMessage = null; // Reset advice message

    // Fetch both the analysis and the upcoming advice message
    _fullAiMessage = await messageService.getPostGameAnalysisMessage(widget.userId);
    _adviceMessage = await messageService.getGameAdviceMessage(widget.userId);

    // --- THIS IS THE FIX ---
    // We NO LONGER spend a bamboo here. The analysis is a free reward.
    if (mounted) {
      setState(() {
        _showMealButtons = false;
      });
    }
    print("Displaying FREE game analysis. Stage: $_conversationStage");
    // --- END OF FIX ---
    _postGameAnalysisTriggered = false;
  }  else {
    _conversationStage = PandaConversationStage.idle;
    final response = await messageService.getGreeting(widget.userId);

    _fullAiMessage = response.message;
    if (mounted) {
      setState(() {
        _showMealButtons = response.showMealButtons;
      });
    }
  }

  if (mounted) {
    setState(() {
      _isTalking = true;
      _currentPandaLottie = 'assets/pandaai/talk.json';
      _charIndex = 0;
      _displayedAiMessage = "";
    });
  }
  _startTypingAnimation();
  const talkAnimationDuration = Duration(milliseconds: 1000);
  Future.delayed(talkAnimationDuration, () {
    if (mounted) {
      setState(() {
        _isTalking = false;
      });
      _updatePandaAnimation();
    }
  });
}


// --- NEW HELPER FUNCTION ---
// --- UPDATED HELPER FUNCTION ---
Future<void> checkPlayFriendResult() async {
  final prefs = await SharedPreferences.getInstance();
  String? battleResult = prefs.getString('last_battle_result'); // Returns 'win', 'loss', or 'draw'

  if (battleResult != null) {
    // 1. Clear the flag immediately
    await prefs.remove('last_battle_result');

    // 2. Get the message using the String result
    final messageService = HomeMessageService.instance;
    String battleMsg = messageService.getBattleMessage(battleResult);

    // 3. Update UI
    if (mounted) {
      setState(() {
        // Bamboo Logic: Win = 10, Draw = 5, Loss = 5
        int bambooReward = (battleResult == 'win') ? 10 : 5;
        _bamboos += bambooReward;

        // Set Panda to talking mode
        _fullAiMessage = battleMsg;
        _conversationStage = PandaConversationStage.idle;
        _isTalking = true;
        _currentPandaLottie = 'assets/pandaai/talk.json';
        _charIndex = 0;
        _displayedAiMessage = "";
      });

      _startTypingAnimation();

      // Stop talking after the message finishes
      Future.delayed(Duration(milliseconds: (battleMsg.length * 70) + 1000), () {
        if (mounted) {
          setState(() {
            _isTalking = false;
          });
          _updatePandaAnimation();
        }
      });
    }
  }
}

// void _handlePandaTap() async {
//   if (_isTalking) return;
//
//   // If the panda is idle, just show a new greeting and stop.
//   if (_conversationStage == PandaConversationStage.idle) {
//     _loadAiMessage(trigger: AiMessageTrigger.dailyGreeting);
//     return;
//   }
//
//   final messageService = HomeMessageService.instance;
//   String newMessage;
//   bool bambooWasSpent = false;
//
//   if (_bamboos <= 0) {
//     // Case 1: Out of bamboos. Get the "hungry" message.
//     newMessage = _getOutOfEnergyMessage();
//     bambooWasSpent = false;
//
//   } else {
//     // Case 2: User has bamboos.
//     bambooWasSpent = true; // Mark that we are spending a bamboo.
//
//     if (_conversationStage == PandaConversationStage.showingGameAnalysis) {
//       // First tap after a game -> show advice.
//       _conversationStage = PandaConversationStage.showingAdvice;
//       newMessage = _adviceMessage ?? "Keep playing and I'll have more advice for you soon!";
//       print("Bamboo spent for advice. Stage: $_conversationStage");
//
//     } else {
//       // Any other tap -> show a quote.
//       _conversationStage = PandaConversationStage.showingQuote;
//       // CRITICAL: We 'await' for the message here BEFORE the final setState.
//       newMessage = await messageService.getMotivationalQuote();
//       print("Bamboo spent for quote. Stage: $_conversationStage");
//     }
//   }
//
//   // --- CONSOLIDATED STATE UPDATE ---
//   // All logic paths lead here. This is the ONLY place we call setState.
//   if (mounted) {
//     setState(() {
//       if (bambooWasSpent) {
//         _bamboos--; // Decrement bamboos here, just before the UI rebuilds.
//       }
//       _fullAiMessage = newMessage; // Set the new message.
//       _isTalking = true;
//       _currentPandaLottie = 'assets/pandaai/talk.json';
//       _charIndex = 0;
//       _displayedAiMessage = "";
//     });
//   }
//
//   // This part remains the same.
//   _startTypingAnimation();
//   const talkAnimationDuration = Duration(milliseconds: 3700);
//   Future.delayed(talkAnimationDuration, () {
//     if (mounted) {
//       setState(() {
//         _isTalking = false;
//       });
//       _updatePandaAnimation();
//     }
//   });
// }

void _handlePandaTap() async {
  if (_isTalking) return;

  // If the panda is idle, just show a new greeting and stop.
  // if (_conversationStage == PandaConversationStage.idle) {
  //   _loadAiMessage(trigger: AiMessageTrigger.dailyGreeting);
  //   return;
  // }

  final messageService = HomeMessageService.instance;
  String newMessage;
  bool bambooWasSpent = false;

  if (_bamboos <= 0) {
    // Case 1: Out of bamboos. Get the "hungry" message and reset the conversation.
    newMessage = _getOutOfEnergyMessage();
    _conversationStage = PandaConversationStage.idle;
    bambooWasSpent = false;

  } else {
    // Case 2: User has bamboos. Spend one and advance the conversation.
    bambooWasSpent = true;

    switch (_conversationStage) {

      case PandaConversationStage.idle:
      case PandaConversationStage.showingDetailedAdvice:

       // newMessage = _adviceMessage ?? "Keep playing and I'll have more advice for you soon!";
      String? freshAdvice = await messageService.getGameAdviceMessage(widget.userId);
      newMessage = freshAdvice ?? "Review your past games to find your weak spots!";
      // Update our local variable just in case
      _adviceMessage = newMessage;
        _conversationStage = PandaConversationStage.showingFirstMotivation;
        break;

      case PandaConversationStage.showingFirstMotivation:
      // C -> D: Show second motivation
        newMessage = await messageService.getMotivationalQuote();
        _conversationStage = PandaConversationStage.showingSecondMotivation;
        break;

      case PandaConversationStage.showingSecondMotivation:
      // D -> E: Show app advice
        newMessage = await messageService.getMotivationalQuote();
        _conversationStage = PandaConversationStage.showingAppAdvice;
        break;

      case PandaConversationStage.showingAppAdvice:
      // E -> B (Loop): Show detailed advice again
        newMessage = await messageService.getGeneralAppAdvice();
        _conversationStage = PandaConversationStage.showingDetailedAdvice;
        break;


      case PandaConversationStage.showingDetailedAdvice:
      // E -> B (Loop): Show detailed advice again
        _adviceMessage = await messageService.getGameAdviceMessage(widget.userId); // <-- Fetches and SAVES the new advice.
        newMessage = _adviceMessage ?? "Let's try another round of advice!";
        _conversationStage = PandaConversationStage.showingDetailedAdvice;
        break;

      default:
      // Fallback case
        newMessage = "Hmm, I seem to have lost my train of thought.";
        _conversationStage = PandaConversationStage.idle;
        bambooWasSpent = false; // Don't spend a bamboo on an error.
        break;
    }
  }

  // --- CONSOLIDATED STATE UPDATE ---
  // All logic paths lead here. This is the ONLY place we call setState.
  if (mounted) {
    setState(() {
      if (bambooWasSpent) {
        _bamboos--; // Decrement bamboos here, just before the UI rebuilds.
      }
      _fullAiMessage = newMessage; // Set the new message.
      _isTalking = true;
      _currentPandaLottie = 'assets/pandaai/talk.json';
      _charIndex = 0;
      _displayedAiMessage = "";
    });
  }

  // This part remains the same.
  _startTypingAnimation();
  int durationMs = (newMessage.length * 70) + 1000;

  // Ensure it plays for at least 2 seconds
  if (durationMs < 2000) durationMs = 2000;

  Future.delayed(Duration(milliseconds: durationMs), () {
    if (mounted) {
      setState(() {
        _isTalking = false;
      });
      _updatePandaAnimation();
    }
  });
}

String _getOutOfEnergyMessage() {
  const messages = [
    "Arre! My energy is low. I need more bamboo to talk. 🐼",
    "Oops, out of bamboo! Play a game and win some more for me. 🙏",
    "My brain has stopped working... please insert bamboo to continue. 😂",
    "I'm too hungry to talk! Go ace a quiz to earn some bamboo for me. 😋",
    "No bamboo, no gyaan! It's that simple. Go play! 😉",
    "My battery is dead! Bamboo is my charger. Go get some! 🔋",
    "I'm on low power mode. Only bamboo can fix this. ⚡",
    "Sorry, can't talk. I'm dreaming of bamboo. Go win some for me! 😴",
    "My throat is dry... from not eating bamboo! Help a panda out? 🥺",
    "Topper banne ke liye energy lagti hai! Mere liye thoda bamboo jeet lo. 💪",
    "Connection lost... please reconnect with bamboo. 📶",
    "I've run out of fuel! Go fill me up with some bamboo. ⛽",
    "You need to pay the toll... in bamboo! Go play a game.  टोल 😜",
    "I'm on a bamboo strike until you earn some more! ✊",
    "Error 404: Bamboo not found. Please play a game to resolve. 💻",
    "All this wisdom isn't free, you know! It costs bamboo. 😉",
    "I'm feeling hangry! A quiz victory is the only cure. 😠",
    "My 'gyaan' factory is closed for now. Reopens with bamboo supply! 🏭",
    "To unlock more advice, you must first defeat a quiz! ⚔️",
    "I'm saving my energy. Come back when you have more bamboo! 🤫"

  ];
  // This is an efficient way to get a random item from a const list.
  // Return a random message from the list
  final modifiableList = List<String>.from(messages);
  modifiableList.shuffle();
  return modifiableList.first;

  // return messages[_random.nextInt(messages.length)];
}

void _handlePersonalQuestionResponse(bool hadMeal) async {
  // 1. Hide the buttons and get the new message
  final messageService = HomeMessageService.instance;
  final newMessage = await messageService.getMealResponseMessage(hadMeal);
  _fullAiMessage = newMessage;

  // 2. --- THIS IS THE FIX ---
  //    Trigger the talking state and animation properly.
  if (mounted) {
    setState(() {
      _showMealButtons = false; // Hide buttons
      _isTalking = true; // Start talking
      _currentPandaLottie = 'assets/pandaai/talk.json'; // Change animation
      _charIndex = 0; // Reset text
      _displayedAiMessage = ""; // Clear display
    });
  }
  // --- END OF FIX ---

  // 3. Start the typing animation for the new message
  _startTypingAnimation();

  // 4. After a delay, stop the talking animation
  const talkAnimationDuration = Duration(milliseconds: 3600);
  Future.delayed(talkAnimationDuration, () {
    if (mounted) {
      setState(() {
        _isTalking = false;
      });
      _updatePandaAnimation();
    }
  });
}


  void _startTypingAnimation() {
    const typingSpeed = Duration(milliseconds: 70);
    _typingTimer?.cancel(); // Cancel any previous timer

     // <-- START the breathing animation here

    _typingTimer = Timer.periodic(typingSpeed, (timer) {
      if (_charIndex < _fullAiMessage.characters.length) { // Use .characters.length
        if (mounted) {
          setState(() {
            _charIndex++;
            // Use .characters.take() to safely get the first N characters
            _displayedAiMessage = _fullAiMessage.characters.take(_charIndex).toString();
          });
        }
      } else {
        _typingTimer?.cancel();
         // <-- STOP the breathing animation here
      }
    });
  }



Future<void> _checkFirstTimeUser() async {
  final prefs = await SharedPreferences.getInstance();
  bool isFirstTime = prefs.getBool('isFirstTime') ?? true;

  if (isFirstTime) {
    // --- CASE A: First Time User ---
    // Funny intro, 0 bamboos.
    const introMessage = "Hi! I'm Panda AI. I talk for food! 🐼 Win games to earn bamboo. No bamboo = No talk! 🤐";

    if (mounted) {
      setState(() {
        _fullAiMessage = introMessage;
        _isTalking = true;
        _currentPandaLottie = 'assets/pandaai/talk.json';
        _charIndex = 0;
        _displayedAiMessage = "";
        // Note: We do NOT set _bamboos = 5 here. It stays 0.
      });
    }

    _startTypingAnimation();

    // Stop talking after 6 seconds (slightly longer for the intro)
    Future.delayed(const Duration(milliseconds: 6000), () {
      if (mounted) {
        setState(() {
          _isTalking = false;
        });
        _updatePandaAnimation();
      }
    });

    // Save flag so this doesn't happen again
    await prefs.setBool('isFirstTime', false);

  } else {
    // --- CASE B: Returning User ---
    // Show Daily Greeting.
    if (!_postGameAnalysisTriggered) {
      _loadAiMessage(trigger: AiMessageTrigger.dailyGreeting);
    }
  }
}

  void _updatePandaAnimation() {
    final hour = DateTime.now().hour;
    final minute = DateTime.now().minute;
    // Convert current time to minutes from midnight for easier comparison
    final nowInMinutes = hour * 60 + minute;

    // 9:30 PM = 21 * 60 + 30 = 1290 minutes
    const sleepStart = 1290;
    // 4:30 AM = 4 * 60 + 30 = 270 minutes
    const sleepEnd = 270;
    // 6:30 AM = 6 * 60 + 30 = 390 minutes
    const meditateEnd = 390;

    String newLottie;
    if (nowInMinutes >= sleepStart || nowInMinutes < sleepEnd) {
      newLottie = 'assets/pandaai/sleep.json';
    } else if (nowInMinutes >= sleepEnd && nowInMinutes < meditateEnd) {
      newLottie = 'assets/pandaai/meditate.json';
    } else {
      newLottie = 'assets/pandaai/eat.json';

    }

    // Only update the state if the animation has changed and the panda is not talking
    if (!_isTalking && _currentPandaLottie != newLottie) {
      setState(() {
        _currentPandaLottie = newLottie;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _typingTimer?.cancel();
    _pandaUpdateTimer?.cancel();
    super.dispose();
  }

@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  super.didChangeAppLifecycleState(state);
  // When the app resumes (e.g., user comes back from a quiz screen)
  if (state == AppLifecycleState.resumed) {
    _checkForNewBamboos();
  }
}

void _checkForNewBamboos() async {
  print("--- Calculating available bamboo balance... ---");
  final dbHelper = DatabaseHelper.instance;

  // Get the count of correct answers that have NOT been spent yet.
  final availableBamboos = await dbHelper.countUncountedCorrectAnswers(widget.userId);

  print("DATABASE REPORT: Found $availableBamboos available bamboos.");
  final bool hasNewBamboos = availableBamboos > _bamboos;
  final int newBamboos = availableBamboos;

  if (mounted && newBamboos > 0) { // Only update state if there's something new
    setState(() {
      // Add the new bamboos to the existing count.
      _bamboos += newBamboos;
    });
  }

  // if (hasNewBamboos) {
  //   print("New bamboos detected! Triggering AI message automatically.");
  //   _postGameAnalysisTriggered = true;
  //   _loadAiMessage(trigger: AiMessageTrigger.postGameAnalysis); // <-- THIS IS THE CRUCIAL ADDITION
  // }
  print("--- Load complete. Final balance on screen: $_bamboos ---");
}



  Widget build(BuildContext context) {

    // --------- SCREEN DIMENSIONS ----------
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = MediaQuery.of(context).size.height < 700;


    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(color: Colors.cyan.withOpacity(0.7), width: 1.2),
              ),
              backgroundColor: Color(0xFF000000),
              title: Text(
                'Exit App ?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: screenWidth*0.042),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(color: Colors.cyan.withOpacity(0.7), width: 1.2),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child:  Text(
                    'No',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: screenWidth*0.04,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                SizedBox(width: screenWidth*0.03),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(color: Colors.cyan.withOpacity(0.7), width: 1.2),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child:  Text(
                    'Yes',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: screenWidth*0.04, fontWeight: FontWeight.normal),
                  ),
                ),
              ],
            );
          },
        );

        if (shouldPop == true) {

          SystemNavigator.pop();

          return true; // Indicate that the pop action is handled (though SystemNavigator.pop takes over)
        }
        return shouldPop ?? false;
      },
    child: Scaffold(
        appBar: AppBar(
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFFA8A8A8)), // Hamburger icon
                onPressed: () {
                  // We'll add the drawer opening logic here later
                  Scaffold.of(context).openDrawer();
                },
                tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              );
            },
          ),
          title: Text(
            'Formula Racing',
            style: GoogleFonts.poppins(
              color: const Color(0xFFA8A8A8),
              fontSize: screenWidth * 0.06,
              fontWeight: FontWeight.w400,
            ),
          ),
          centerTitle: true, // This will center the title
          backgroundColor: Colors.transparent, // Makes the AppBar invisible
          elevation: 0, // Removes the shadow
        ),

        drawer: Padding(
         padding: EdgeInsets.only(top: 30.0),
        child: Align(
          alignment: Alignment.topLeft,

          child: Container(
          width: screenWidth * 0.5,
          height: screenHeight * 0.5,

        child: Drawer(
          backgroundColor: const Color(0xFF1E1E1E), // A dark background for the drawer
          child: ListView(
            // Important: Remove any padding from the ListView.
            padding: EdgeInsets.only(top: 50.0),
            children: <Widget>[

              // --- MENU ITEMS ---
          // Container(
          // margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), // Adds space around the item
          // decoration: BoxDecoration(
          //   color: const Color(0xD00BCD4),
          //   border: Border.all(
          //     color: const Color(0xCC00BCD4), // Using a cyan color to match your exit dialog
          //     width: 1.2,
          //   ),
          //   borderRadius: BorderRadius.circular(8.0),
          // ),
          //     child: ListTile(
          //       leading: const Icon(Icons.school_outlined, color: Color(
          //           0xCC00BCD4)), // An icon for learning/revising
          //       title: Text(
          //         'Revise All Formulas',
          //         style: GoogleFonts.poppins(color: const Color(0xCCFFFFFF)),
          //       ),
          //       onTap: () {
          //         Navigator.pop(context); // Close the drawer first
          //         Navigator.push(
          //           context,
          //           MaterialPageRoute(
          //             builder: (context) => const ReviseChapterSelectionScreen(),
          //           ),
          //         );
          //       },
          //     ),),

              // REPLACE the "Revise All Formulas" Container in the Drawer with this:
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: const Color(0x1AFD698C), // Keeping your existing color style
                  border: Border.all(
                    color: const Color(0xCCFD698C),
                    width: 1.2,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ListTile(
                  leading: const Icon(Icons.assignment_late_outlined, color: Color(
                      0xCCFD698C)), // Icon changed to represent Mistakes
                  title: Text(
                    'My Mistakes',
                    style: GoogleFonts.poppins(color: const Color(0xCCFD698C)),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AITrackerScreen(userId: widget.userId), // Navigate to Mistakes
                      ),
                    );
                  },
                ),
              ),


              ListTile(
                leading: const Icon(Icons.help_outline, color: Color(0xFFA8A8A8)),
                title: Text(
                  'How to Play',
                  style: GoogleFonts.poppins(color: const Color(0xFFA8A8A8)),
                ),
                onTap: () {
                  Navigator.pop(context); // Close the drawer first
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>  InfoScreen(
                        title: 'How to Play',
                        ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline, color: Color(0xFFA8A8A8)),
                title: Text(
                  'About Me', // Changed from "About Me" to match the screen title
                  style: GoogleFonts.poppins(color: const Color(0xFFA8A8A8)),
                ),
                onTap: () {
                  Navigator.pop(context); // Close the drawer first
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>  InfoScreen(
                        title: 'About Me',
                         ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),),),),
      // ............. Chunk 1 BACKGROUND SOLID BLACK.............
      body: Container(
        color: Colors.black,
        child: SafeArea(
        // ............. Chunk 2 SAFE AREA CONTENT .............

          child: Column(
            children: [
              // =========== TOP HALF: AI CHAT AREA ===========
              Expanded(
                flex: 1, // This makes it take up half the space
                child: Container( // Placeholder for your AI chat UI
                  width: double.infinity,
                  child: Column(
                    children: [

                            Padding(
                            padding: EdgeInsets.only(top: screenHeight * 0.0),
                            child:Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // --- AVATAR ---
                                Padding(
                                  padding: EdgeInsets.only(left: screenWidth * 0.1), // <-- ADD THIS PADDING
                                  child: SizedBox(
                                    height: screenWidth * 0.5,
                                    width: screenWidth * 0.5,
                                    child: GestureDetector(
                                      onTap: () {
                                        _handlePandaTap();
                                        },
                                      child: Lottie.asset(
                                        _currentPandaLottie,
                                        //repeat: !_isTalking,
                                        repeat: true,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                               // const SizedBox(width: 16), // A bit of space between panda and bamboo

                                // --- BAMBOO COUNTER (Image and Text) ---
                                // --- BAMBOO COUNTER (Image and Text) ---
// Wrap with Padding for manual vertical adjustment
                                Padding(
                                  padding: EdgeInsets.only(top: screenHeight * 0.07,right: screenWidth * 0.01), // <-- ADJUST THIS VALUE
                                  child: Stack(
                                    clipBehavior: Clip.none, // Allow badge to go outside the boundary
                                    alignment: Alignment.center,
                                    children: [
                                      // 1. The Bamboo Image (its position is preserved)
                                      Image.asset(
                                        _bamboos > 2
                                            ? 'assets/pandaai/bamboo_full.png'
                                            : 'assets/pandaai/bamboo_low.png',
                                        width: screenWidth * 0.3, // Responsive size
                                        height: screenWidth * 0.3, // Responsive size
                                      ),

                                      // 2. The Circular Counter, positioned on top
                                      Positioned(
                                        top: -10,  // <-- Negative value shifts it UP. Adjust as needed.
                                        right: 0, // <-- Adjust to position horizontally.
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 28,
                                            minHeight: 28,
                                          ),
                                          child: Text(
                                            '$_bamboos',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: screenWidth * 0.035,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),),

                            SizedBox(height: screenHeight * 0.015),


                            // --- CHAT BUBBLE ---
                            // --- CHAT BUBBLE ---
                            // Padding(
                            //   padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1), // <-- ADD THIS WRAPPER
                            //   child: Container(
                            //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            //     decoration: BoxDecoration(
                            //       color: const Color(0xFF1E1E1E), // Dark grey bubble
                            //       borderRadius: BorderRadius.circular(12),
                            //     ),
                            //     child: Text(
                            //       _displayedAiMessage,
                            //       textAlign: TextAlign.center, // <-- Optional: Looks better when centered
                            //       style: TextStyle(
                            //         color: const Color(0xFFDCDCDC),
                            //         fontSize: screenWidth * 0.04,
                            //       ),
                            //     ),
                            //   ),
                            // ),

              // Define this variable at the start of your build method


// ... inside your Column ...

// --- CHAT BUBBLE ---
            Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
        child: Container(
          // USE CONSTRAINTS INSTEAD OF FIXED HEIGHT
          constraints: BoxConstraints(
            // Minimum height to look like a bubble
            minHeight: 50,
            // Maximum height:
            // On small screens (<700px height), limit to 15% of screen.
            // On larger screens, allow up to 22% of screen.
            maxHeight: MediaQuery.of(context).size.height * (isSmallScreen ? 0.15 : 0.15),
          ),

          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
          ),

          // Make it scrollable ONLY if it exceeds the maxHeight defined above
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Center(
              child: Text(
                _displayedAiMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFDCDCDC),
                  fontSize: screenWidth * 0.04,
                  height: 1.4, // Slightly more line height for readability
                ),
              ),
            ),
          ),
        ),
      ),

                      // --- YES/NO BUTTONS FOR MEAL QUESTIONS ---
                      if (_showMealButtons)
                        // Padding(
                        //   padding: const EdgeInsets.only(top: 12.0),
                        //   child: Row(
                        //     mainAxisAlignment: MainAxisAlignment.center,
                        //     children: [
                        //       ElevatedButton(
                        //         onPressed: () {
                        //           // Call the handler with 'true' for Yes
                        //           _handlePersonalQuestionResponse(true);
                        //         },
                        //         child: Text('Yes'),
                        //       ),
                        //       SizedBox(width: 16),
                        //       ElevatedButton(
                        //         onPressed: () {
                        //           // Call the handler with 'false' for No
                        //           _handlePersonalQuestionResponse(false);
                        //         },
                        //         child: Text('No'),
                        //       ),
                        //     ],
                        //   ),
                        // ),

                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.grey, // Text color
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4), // Border radius
                                  ),
                                ),
                                onPressed: () {
                                  _handlePersonalQuestionResponse(true);
                                },
                                child: const Text('Yes'),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.grey, // Text color
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4), // Border radius
                                  ),
                                ),
                                onPressed: () {
                                  _handlePersonalQuestionResponse(false);
                                },
                                child: const Text('No'),
                              ),
                            ],
                          ),
                        ),

                    ],


                  ),
                ),
              ),


              // --- DOTTED DIVIDER ---
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0), // Add some vertical spacing
                child: Text(
                  // Using a string of dots. Adjust the number of dots to fit your design.
                  '• • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • • •',
                  maxLines: 1,
                  overflow: TextOverflow.clip, // Prevents wrapping
                  style: TextStyle(
                    color: Colors.grey.withOpacity(0.5),
                    letterSpacing: 0, // Adjust spacing between dots
                    fontSize: 10,
                  ),
                ),
              ),
// --- END OF DOTTED DIVIDER ---


              // ............. Chunk 4 SOLO / ONLINE CENTERED .............
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    // Solo Play button → your original style




                    // Online Play button → your original style
                    AnimatedButton(
                      screenWidth: screenWidth,
                      screenHeight: screenWidth,
                      color: const Color(0xFF201100),

                      onPressed: () async {
                        //print('✅Navigating to MultiplayerSelectionScreen with userId: ${widget.userId}');
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MultiplayerSelectionScreen(userId: widget.userId),
                            // Navigate to the new page
                          ),
                        );
                        await checkPlayFriendResult();
                      },
                      gradientColors: const [Color(0xFFFFA500), Color(
                          0xFF874A01)],
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children:  [
                          Text(
                            'Play Friend',
                            style: TextStyle(fontSize: screenWidth * 0.053, color: Color(
                                0xD9FFFFFF),fontWeight: FontWeight.normal),
                          ),

                        ],
                      ),
                    ),

                    SizedBox(height: screenWidth*0.06),
                    //SizedBox(height: screenWidth*0.055),

                    AnimatedButton(
                      screenWidth: screenWidth,
                      screenHeight: screenWidth,
                      color: const Color(0xFF001E1E),


                      onPressed: () async {
                        print("\n>>> User pressed 'Play Solo'. Navigating to selection screen and waiting...");
                        // Navigate to the solo mode selection screen and wait for it to complete.
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SoloModeSelectionScreen(userId: widget.userId),
                          ),
                        );


                        print("<<< User has returned to HomeScreen. Triggering bamboo check.");
                        _postGameAnalysisTriggered = true;
                        _loadAiMessage(trigger: AiMessageTrigger.postGameAnalysis);
                        _checkForNewBamboos();
                      },
                      gradientColors: const [Color(0xFF00FFFF), Color(0xFF006C6C)],
                      child:  Text(
                        'Play Solo',
                        style: TextStyle(fontSize: screenWidth * 0.053, color: Color(
                            0xD9FFFFFF),fontWeight: FontWeight.normal),
                      ),
                    ),

                    SizedBox(height: screenWidth*0.06),

                    // AnimatedButton(
                    //   screenWidth: screenWidth,
                    //   screenHeight: screenWidth,
                    //   color: const Color(0xFF230000),
                    //   onPressed: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(builder: (context) => AITrackerScreen(userId: widget.userId)),
                    //     );
                    //   },
                    //   gradientColors: const [Colors.red, Color(0xFF8B0000)], // Red gradient
                    //   //color: const Color(0xFF000000), // Black background
                    //   child: Text(
                    //     'My Mistakes',
                    //     style: TextStyle(fontSize: screenWidth * 0.053, color: Colors.redAccent, fontWeight: FontWeight.normal),
                    //   ),
                    // ),

                    // REPLACE the "My Mistakes" AnimatedButton in the Body with this:
                    AnimatedButton(
                      screenWidth: screenWidth,
                      screenHeight: screenWidth,
                      color: const Color(0x33AE9B52), // Dark Cyan/Black background
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ReviseChapterSelectionScreen()), // Navigate to Revise
                        );
                      },
                      // Changed gradient to Cyan/Blue to match the "Learning" theme
                      gradientColors: const [ Color(0xFFAE9B52), Color(
                          0xFF503F01)],
                      child: Text(
                        'Revise All Formulas',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: screenWidth * 0.053,
                            color: const Color(0xF2FFFFFF), // Changed text color to match
                            fontWeight: FontWeight.normal
                        ),
                      ),
                    ),

                  ],
                ),
              ),
              // ............. Chunk 5 BOTTOM TEXT (PHYSICS WITH RAKESH) .............
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Text(
                  'Physics with Rakesh  |  IIT Madras',
                  style: TextStyle(
                    color: Color(0xFFA8A8A8),
                    fontSize: screenWidth * 0.04,

                  ),
                ),
              ),

            ],
          ),
        ),
    )
    ),
    );
  }//
}

//...............................CHUNK 6............. ANIMATED BUTTON..................................
class AnimatedButton extends StatefulWidget {
  final double screenWidth;
  final double screenHeight;
  final VoidCallback onPressed;
  final Widget child;
  final List<Color> gradientColors;
  final Color color;


  const AnimatedButton({
    required this.screenWidth,
    required this.screenHeight,
    required this.onPressed,
    required this.child,
    required this.gradientColors,
    this.color = Colors.black,

    Key? key,
  }) : super(key: key);

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _scale = 0.97),
      onPointerUp: (_) => setState(() => _scale = 1.0),
      child: Transform.scale(
        scale: _scale,
        child: CustomPaint(
          painter: GradientBorderPainter(gradientColors: widget.gradientColors),
          child: Container(
            width: widget.screenWidth * 0.64,
            height: widget.screenHeight * 0.17,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              child: InkWell(
                splashColor: Colors.grey.withOpacity(0.3),
                highlightColor: Colors.grey.withOpacity(0.1),
                splashFactory: InkRipple.splashFactory,
                borderRadius: BorderRadius.circular(4),
                onTap: widget.onPressed,
                child: Center(child: widget.child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GradientBorderPainter extends CustomPainter {
  final List<Color> gradientColors; // ADD THIS LINE

  GradientBorderPainter({required this.gradientColors});
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(4));
    final gradient = LinearGradient(
      colors: gradientColors,
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}



//Future<void> loadUserId() async {
// final prefs = await SharedPreferences.getInstance();
// final storedId = prefs.getString('user_id');
// if (storedId != null) {
// setState(() {
//  userId = storedId;
//  });
// } else {
// print("No user ID found");
// }
// }