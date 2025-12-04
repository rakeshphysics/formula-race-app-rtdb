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








// ----------------------------------------------------
// HomeScreen Widget
// ----------------------------------------------------
class HomeScreen extends StatefulWidget {
  final String userId;
  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin { // Add mixin
  Timer? _timer;
  int _charIndex = 0;
  String _fullAiMessage = "Loading...";
  String _displayedAiMessage = "";
  late AnimationController _breathingController; // <-- ADD THIS
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();
    _loadAiMessage();
    _breathingController = AnimationController( // <-- ADD THIS BLOCK
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _breathingAnimation = Tween<double>(begin: 0.18, end: 0.22).animate( // <-- ADD THIS BLOCK
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOut,
      ),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _breathingController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _breathingController.forward();
      }
    });

    //_breathingController.forward();
  }


  // Add this new method inside _HomeScreenState
  void _loadAiMessage() async {
    // Create an instance of our service
    final messageService = HomeMessageService.instance;
    // Call the service to get the message, passing the user's ID
    final message = await messageService.getHomePageMessage(widget.userId);

    // Update the state with the new message and reset the animation
    if (mounted) { // Good practice to check if the widget is still in the tree
      setState(() {
        _fullAiMessage = message;
        _charIndex = 0; // Reset animation index
        _displayedAiMessage = ""; // Clear the displayed message
      });
      _startTypingAnimation(); // Start the typing animation with the new message
    }
  }

  // In _HomeScreenState

  void _startTypingAnimation() {
    const typingSpeed = Duration(milliseconds: 70);
    _timer?.cancel(); // Cancel any previous timer

    _breathingController.forward(); // <-- START the breathing animation here

    _timer = Timer.periodic(typingSpeed, (timer) {
      if (_charIndex < _fullAiMessage.length) {
        if (mounted) {
          setState(() {
            _charIndex++;
            _displayedAiMessage = _fullAiMessage.substring(0, _charIndex);
          });
        }
      } else {
        _timer?.cancel();
        _breathingController.stop(); // <-- STOP the breathing animation here
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathingController.dispose(); // Important: cancel the timer to avoid memory leaks
    super.dispose();
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

                      // =========== AI AVATAR AND CHAT BUBBLE ===========
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // --- AVATAR ---
                            // Placeholder for your animated blob
                            // --- AVATAR ---
                            // --- AVATAR ---
                          SizedBox(
                          height: screenHeight * 0.15,
                            child:InkWell(
                              onTap: _loadAiMessage, // <-- Call our existing function on tap!
                              borderRadius: BorderRadius.circular(100), // Makes the splash effect circular
                              child: AnimatedBuilder(
                                animation: _breathingAnimation,
                                builder: (context, child) {
                                  return Container(
                                    padding: const EdgeInsets.all(16.0), // Add some padding so the tap area is larger
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.transparent, width: 2), // Transparent border
                                    ),
                                    child: Icon(
                                      Icons.bubble_chart,
                                      color: Colors.cyan,
                                      size: screenWidth * _breathingAnimation.value,
                                    ),
                                  );
                                },
                              ),
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
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.04,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),


              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Divider(
                  color: Colors.grey.withOpacity(0.5),
                  thickness: 1,
                ),
              ),


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
                            style: TextStyle(fontSize: screenWidth * 0.057, color: Colors.white,fontWeight: FontWeight.normal),
                          ),

                        ],
                      ),
                    ),

                    SizedBox(height: screenWidth*0.055),
                    //SizedBox(height: screenWidth*0.055),

                    AnimatedButton(
                      screenWidth: screenWidth,
                      screenHeight: screenWidth,


                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SoloModeSelectionScreen(userId: widget.userId)),
                        );
                      },
                      gradientColors: const [Color(0xFF00FFFF), Color(0xFF006C6C)],
                      child:  Text(
                        'Play Solo',
                        style: TextStyle(fontSize: screenWidth * 0.057, color: Colors.white,fontWeight: FontWeight.normal),
                      ),
                    ),

                    SizedBox(height: screenWidth*0.055),

                    AnimatedButton(
                      screenWidth: screenWidth,
                      screenHeight: screenWidth,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AITrackerScreen(userId: widget.userId)),
                        );
                      },
                      gradientColors: const [Colors.red, Color(0xFF8B0000)], // Red gradient
                      color: const Color(0xFF000000), // Black background
                      child: Text(
                        'My Mistakes',
                        style: TextStyle(fontSize: screenWidth * 0.057, color: Colors.redAccent, fontWeight: FontWeight.normal),
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
            width: widget.screenWidth * 0.8,
            height: widget.screenHeight * 0.19,
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