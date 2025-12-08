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
//import 'package:shared_preferences/shared_preferences.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkForNewBamboos(); // Check for bamboos on initial load
    _loadAiMessage();
    _updatePandaAnimation();
    _pandaUpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updatePandaAnimation();
    });
  }


  // Add this new method inside _HomeScreenState
void _loadAiMessage() async {
  // Prevent starting a new talk if already talking
  if (_isTalking) return;

  final messageService = HomeMessageService.instance;
  final response = await messageService.getGreeting(widget.userId);

  // If we get a meal question, handle it separately.
  if (response.showMealButtons) {
    _fullAiMessage = response.message;
    if (mounted) {
      setState(() {
        _showMealButtons = true; // Show the Yes/No buttons
      });
    }
  } else {

    if (_bamboos > 0) {
      // --- This is the new logic ---
      _fullAiMessage = response.message; // 1. Immediately update the UI to show one less bamboo.
      if (mounted) {
        setState(() {
          _bamboos--;
        });
      }

      // 2. In the background, tell the database that one bamboo has been spent.
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.spendOneBamboo();
      print("Bamboo spent. Marked one row as counted in the database.");
      // --- End of new logic ---

      // Get a real message from the service
      // final messageService = HomeMessageService.instance;
      // final message = await messageService.getHomePageMessage(widget.userId);
      // _fullAiMessage = message;

    } else {
      // If user has no bamboos, use a predefined message
      _fullAiMessage = "I'm hungry! Please earn some bamboos by playing, and then we can talk.";
    }


  }
  // First, check if there are any bamboos to spend

  // --- Animation Logic (remains the same) ---
  if (mounted) {
    setState(() {
      _isTalking = true;
      _currentPandaLottie = 'assets/pandaai/talk.json';
      _charIndex = 0;
      _displayedAiMessage = "";
    });
  }
  _startTypingAnimation();
  const talkAnimationDuration = Duration(milliseconds: 1850 * 2);
  Future.delayed(talkAnimationDuration, () {
    if (mounted) {
      setState(() {
        _isTalking = false;
      });
      _updatePandaAnimation();
    }
  });
}

void _handleMealResponse(bool hadMeal) async {
  // 1. Hide the buttons immediately
  if (mounted) {
    setState(() {
      _showMealButtons = false;
    });
  }

  // 2. Call the service to get the correct follow-up message
  final messageService = HomeMessageService.instance;
  final message = await messageService.getMealResponseMessage(hadMeal);

  // 3. Display the new message using the same animation logic
  _fullAiMessage = message;
  if (mounted) {
    setState(() {
      _isTalking = true;
      _currentPandaLottie = 'assets/pandaai/talk.json';
      _charIndex = 0;
      _displayedAiMessage = "";
    });
  }
  _startTypingAnimation();
  const talkAnimationDuration = Duration(milliseconds: 1850 * 2); // Same duration
  Future.delayed(talkAnimationDuration, () {
    if (mounted) {
      setState(() {
        _isTalking = false;
      });
      _updatePandaAnimation();
    }
  });
}

  // In _HomeScreenState

  void _startTypingAnimation() {
    const typingSpeed = Duration(milliseconds: 70);
    _typingTimer?.cancel(); // Cancel any previous timer

     // <-- START the breathing animation here

    _typingTimer = Timer.periodic(typingSpeed, (timer) {
      if (_charIndex < _fullAiMessage.length) {
        if (mounted) {
          setState(() {
            _charIndex++;
            _displayedAiMessage = _fullAiMessage.substring(0, _charIndex);
          });
        }
      } else {
        _typingTimer?.cancel();
         // <-- STOP the breathing animation here
      }
    });
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
  final availableBamboos = await dbHelper.countUncountedCorrectAnswers();

  print("DATABASE REPORT: Found $availableBamboos available bamboos.");

  if (mounted) {
    setState(() {
      // Directly set the UI count to the available balance
      _bamboos = availableBamboos;
    });
  }
  print("--- Load complete. Final balance on screen: $_bamboos ---");
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

  Widget build(BuildContext context) {

    // --------- SCREEN DIMENSIONS ----------
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;


    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(color: Colors.cyan, width: 1.2),
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
                      side: BorderSide(color: Colors.cyan, width: 1.2),
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
                      side: BorderSide(color: Colors.cyan, width: 1.2),
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
                        title: 'About',
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
                                      onTap: _loadAiMessage,
                                      child: Lottie.asset(
                                        _currentPandaLottie,
                                        repeat: !_isTalking,
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

                            SizedBox(height: screenHeight * 0.02),


                            // --- CHAT BUBBLE ---
                            // --- CHAT BUBBLE ---
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1), // <-- ADD THIS WRAPPER
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E1E), // Dark grey bubble
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _displayedAiMessage,
                                  textAlign: TextAlign.center, // <-- Optional: Looks better when centered
                                  style: TextStyle(
                                    color: const Color(0xFFDCDCDC),
                                    fontSize: screenWidth * 0.04,
                                  ),
                                ),
                              ),
                            ),

                      // --- YES/NO BUTTONS FOR MEAL QUESTIONS ---
                      if (_showMealButtons)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  // Call the handler with 'true' for Yes
                                  _handleMealResponse(true);
                                },
                                child: Text('Yes'),
                              ),
                              SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () {
                                  // Call the handler with 'false' for No
                                  _handleMealResponse(false);
                                },
                                child: Text('No'),
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

                      onPressed: () {
                        //print('✅Navigating to MultiplayerSelectionScreen with userId: ${widget.userId}');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MultiplayerSelectionScreen(userId: widget.userId),
                            // Navigate to the new page
                          ),
                        );
                      },
                      gradientColors: const [Color(0xFFFFA500), Color(
                          0xFF874A01)],
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children:  [
                          Text(
                            'Play Friend',
                            style: TextStyle(fontSize: screenWidth * 0.053, color: Colors.white,fontWeight: FontWeight.normal),
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
                        _checkForNewBamboos();
                      },
                      gradientColors: const [Color(0xFF00FFFF), Color(0xFF006C6C)],
                      child:  Text(
                        'Play Solo',
                        style: TextStyle(fontSize: screenWidth * 0.053, color: Colors.white,fontWeight: FontWeight.normal),
                      ),
                    ),

                    SizedBox(height: screenWidth*0.06),

                    AnimatedButton(
                      screenWidth: screenWidth,
                      screenHeight: screenWidth,
                      color: const Color(0xFF230000),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AITrackerScreen(userId: widget.userId)),
                        );
                      },
                      gradientColors: const [Colors.red, Color(0xFF8B0000)], // Red gradient
                      //color: const Color(0xFF000000), // Black background
                      child: Text(
                        'My Mistakes',
                        style: TextStyle(fontSize: screenWidth * 0.053, color: Colors.redAccent, fontWeight: FontWeight.normal),
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