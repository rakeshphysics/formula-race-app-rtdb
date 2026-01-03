// // -------------------------------------------------------------
// // OnlineModeSelectionScreen.dart → Final version
// // -------------------------------------------------------------
// // - Buttons centered
// // - Buttons sized by screenWidth / screenHeight
// // - Dark theme (black background, white text)
// // -------------------------------------------------------------
//
// // -------------------- CHUNK 1 — IMPORT -----------------------
// import 'package:flutter/material.dart';
// import 'online_game_screen.dart'; // import your OnlineScreen
// import 'chapter_selection_screen.dart';
// import '../widgets/glow_button_amber.dart';
// import 'multiplayer_selection_screen.dart';
// import 'online_chapter_selection_screen.dart';
// import 'qr_host_screen.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:formularacing/services/matchmaking_service.dart';
//
//
// // -------------------- CHUNK 2 — CLASS HEADER -----------------
// class OnlineModeSelectionScreen extends StatelessWidget {
//   final String userId;
//   //String determinedMatchId = 'your_match_id_here'; // Replace with actual value
//   //int determinedSeed = 12345; // Replace with actual value
//   //bool determinedIsPlayer1 = true; // Replace with actual value based on role
//   //String currentUserId = '123';
//    OnlineModeSelectionScreen({super.key, required this.userId});
//
//   // -------------------- CHUNK 3 — BUILD FUNCTION -----------------
//   @override
//   Widget build(BuildContext context) {
//     // Screen size → consistent with HomeScreen
//     final screenHeight = MediaQuery.of(context).size.height;
//     final screenWidth = MediaQuery.of(context).size.width;
//
//     return WillPopScope(
//         onWillPop: () async {
//       await Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MultiplayerSelectionScreen(userId:userId,)),
//       );
//       return false;
//     },
//
//     child: Scaffold(
//       backgroundColor: Colors.black, // DARK THEME
//
//       appBar: AppBar(
//         backgroundColor: Colors.black, // DARK THEME
//         title:  Text(
//             'Choose Subject & portion', style: TextStyle(fontSize:screenWidth*0.042,color: Color(
//             0xD9FFFFFF))),
//         iconTheme: const IconThemeData(color: Color(
//             0xD9FFFFFF)),
//       ),
//
//       body: Center( // CENTER THE COLUMN
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//
//             // -------------------- CHUNK 4 — BUTTONS -----------------
//             // Inside OnlineModeSelectionScreen build method
//
//         GlowButtonamber(
//         label: 'Chapter Wise',
//           width: screenWidth * 0.8,
//           height: screenHeight * 0.08,
//           onPressed: () { // No need for async if not calling createMatch here
//             // Removed the FirebaseAuth.instance.currentUser check and related if statement
//             //print('Navigating to OnlineChapterSelectionScreen with userId: $userId'); // Using userId directly
//
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => OnlineChapterSelectionScreen(userId: userId),
//               ),
//             );
//           },
//         ),
//
//             SizedBox(height: screenHeight * 0.024),
//
//             // Inside OnlineModeSelectionScreen build method
//             // --- Full 11th Button ---
//             GlowButtonamber(
//               label: 'Full 11th',
//               width: screenWidth * 0.8,
//               height: screenHeight * 0.08,
//               onPressed: () async { // Make onPressed async
//                 // Removed the FirebaseAuth.instance.currentUser check and related if statement
//                 //print('Navigating to QRHostScreen for Full 11th with userId: $userId'); // Using userId directly
//
//                 final createdMatchData = await MatchmakingService.createMatch(
//                   userId, // Directly use the userId from the widget's constructor
//                   gameMode: 'full_11th', // Pass the correct mode here
//                 );
//
//                 if (createdMatchData != null) {
//                   final matchId = createdMatchData['matchId'];
//                   final seed = createdMatchData['seed'];
//
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => QRHostScreen(
//                         matchId: matchId,
//                         seed: seed,
//                         isPlayer1: true, // Host is always Player 1
//                         playerId: userId, // Directly use the userId
//                       ),
//                     ),
//                   );
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Failed to create match for Full 11th. Please try again.')),
//                   );
//                 }
//               },
//             ),
//
//             SizedBox(height: screenHeight * 0.024), // Keep this SizedBox between buttons
//
// // --- Full 12th Button ---
//             GlowButtonamber(
//               label: 'Full 12th',
//               width: screenWidth * 0.8,
//               height: screenHeight * 0.08,
//               onPressed: () async { // Make onPressed async
//                 // Removed the FirebaseAuth.instance.currentUser check and related if statement
//                 //print('Navigating to QRHostScreen for Full 12th with userId: $userId'); // Using userId directly
//
//                 final createdMatchData = await MatchmakingService.createMatch(
//                   userId, // Directly use the userId from the widget's constructor
//                   gameMode: 'full_12th', // Pass the correct mode here
//                 );
//
//                 if (createdMatchData != null) {
//                   final matchId = createdMatchData['matchId'];
//                   final seed = createdMatchData['seed'];
//
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => QRHostScreen(
//                         matchId: matchId,
//                         seed: seed,
//                         isPlayer1: true, // Host is always Player 1
//                         playerId: userId, // Directly use the userId
//                       ),
//                     ),
//                   );
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Failed to create match for Full 12th. Please try again.')),
//                   );
//                 }
//               },
//             ),
//
//             SizedBox(height: screenHeight * 0.024),
//
//             // Inside OnlineModeSelectionScreen build method
//             GlowButtonamber(
//               label: '11th + 12th',
//               width: screenWidth * 0.8,
//               height: screenHeight * 0.08,
//               onPressed: () async { // Keep async because of MatchmakingService.createMatch
//                 // Removed the FirebaseAuth.instance.currentUser check and related if statement
//                // print('Navigating to QRHostScreen for 11th + 12th with userId: $userId'); // Using userId directly
//
//                 final createdMatchData = await MatchmakingService.createMatch(
//                   userId, // Directly use the userId from the widget's constructor
//                   gameMode: 'combined_11_12', // Assuming this is the correct mode string
//                 );
//
//                 if (createdMatchData != null) {
//                   final matchId = createdMatchData['matchId'];
//                   final seed = createdMatchData['seed'];
//
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => QRHostScreen(
//                         matchId: matchId,
//                         seed: seed,
//                         isPlayer1: true,
//                         playerId: userId, // Directly use the userId
//                       ),
//                     ),
//                   );
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Failed to create match. Please try again.')),
//                   );
//                 }
//               },
//             ),
//
//           ],
//         ),
//       ),
//     ));
//   }
// }

// -------------------------------------------------------------
// OnlineModeSelectionScreen.dart
// -------------------------------------------------------------

import 'package:flutter/material.dart';
import 'online_game_screen.dart';
import 'chapter_selection_screen.dart';
import '../widgets/glow_button_amber.dart';
import 'multiplayer_selection_screen.dart';
import 'online_chapter_selection_screen.dart';
import 'qr_host_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:formularacing/services/matchmaking_service.dart';

class OnlineModeSelectionScreen extends StatefulWidget {
  final String userId;

  const OnlineModeSelectionScreen({
    super.key,
    required this.userId,
    // We removed 'subject' from constructor because we select it here now
  });

  @override
  State<OnlineModeSelectionScreen> createState() => _OnlineModeSelectionScreenState();
}

class _OnlineModeSelectionScreenState extends State<OnlineModeSelectionScreen> {
  // Default selection
  String _selectedSubject = 'Physics';

  final Map<String, Color> subjectColors = {
    'Physics': Colors.cyan.shade700.withOpacity(0.7),
    'Chemistry': Colors.green.shade700.withOpacity(0.7),
    'Maths': Colors.blue.shade700.withOpacity(0.7),
  };


  // Helper to build the Amber Subject Buttons
  Widget _buildSubjectButton(String subjectName) {
    final bool isSelected = _selectedSubject == subjectName;

    // The Amber color used in Online Mode
    final Color activeColor = subjectColors[subjectName]!;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          transform: isSelected ? Matrix4.identity().scaled(1.05) : Matrix4.identity().scaled(0.95),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: activeColor.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 0),
              )
            ]
                : [],
          ),
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedSubject = subjectName;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected ? activeColor.withOpacity(0.2) : Colors.grey[900],
              foregroundColor: isSelected ? activeColor : Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(
                  color: isSelected ? activeColor : Colors.grey[800]!,
                  width: isSelected ? 2.0 : 1.5,
                ),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                subjectName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  //color: isSelected ? activeColor : Colors.white70,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final Color currentThemeColor = subjectColors[_selectedSubject]!;

    return WillPopScope(
        onWillPop: () async {
          await Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MultiplayerSelectionScreen(userId: widget.userId))
          );
          return false;
        },

        child: Scaffold(
          backgroundColor: Colors.black,

          appBar: AppBar(
            backgroundColor: Colors.black,
            title: Text(
                'Online Match Setup',
                style: TextStyle(fontSize: screenWidth * 0.042, color: const Color(0xD9FFFFFF))
            ),
            iconTheme: const IconThemeData(color: Color(0xD9FFFFFF)),
          ),

          body: SingleChildScrollView(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  // 1. TOP DOTTED LINE
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0, bottom: 15.0),
                    child: Text(
                      "................................................................................................................................................",
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        height: 0.5,
                      ),
                    ),
                  ),

                  // 2. SUBJECT SELECTION ROW
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSubjectButton('Physics'),
                        _buildSubjectButton('Chemistry'),
                        _buildSubjectButton('Maths'),
                      ],
                    ),
                  ),

                  // 3. BOTTOM DOTTED LINE
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 40.0),
                    child: Text(
                      "................................................................................................................................................",
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        height: 0.5,
                      ),
                    ),
                  ),

                  // 4. ACTION BUTTONS (Using _selectedSubject)

                  // --- Chapter Wise Button ---
                  GlowButtonamber(
                    label: 'Chapter Wise',
                    width: screenWidth * 0.8,
                    height: screenHeight * 0.08,
                    glowColor: currentThemeColor,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OnlineChapterSelectionScreen(
                            userId: widget.userId,
                            subject: _selectedSubject, // Pass the selected subject
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: screenHeight * 0.024),

                  // --- Full 11th Button ---
                  GlowButtonamber(
                    label: 'Full 11th',
                    width: screenWidth * 0.8,
                    height: screenHeight * 0.08,
                    glowColor: currentThemeColor,
                    onPressed: () async {
                      final createdMatchData = await MatchmakingService.createMatch(
                        widget.userId,
                        gameMode: 'full_11th',
                        subject: _selectedSubject, // Pass the selected subject
                      );
                      _handleMatchCreation(context, createdMatchData);
                    },
                  ),

                  SizedBox(height: screenHeight * 0.024),

                  // --- Full 12th Button ---
                  GlowButtonamber(
                    label: 'Full 12th',
                    width: screenWidth * 0.8,
                    height: screenHeight * 0.08,
                    glowColor: currentThemeColor,
                    onPressed: () async {
                      final createdMatchData = await MatchmakingService.createMatch(
                        widget.userId,
                        gameMode: 'full_12th',
                        subject: _selectedSubject, // Pass the selected subject
                      );
                      _handleMatchCreation(context, createdMatchData);
                    },
                  ),

                  SizedBox(height: screenHeight * 0.024),

                  // --- 11th + 12th Button ---
                  GlowButtonamber(
                    label: '11th + 12th',
                    width: screenWidth * 0.8,
                    height: screenHeight * 0.08,
                    glowColor: currentThemeColor,
                    onPressed: () async {
                      final createdMatchData = await MatchmakingService.createMatch(
                        widget.userId,
                        gameMode: 'combined_11_12',
                        subject: _selectedSubject, // Pass the selected subject
                      );
                      _handleMatchCreation(context, createdMatchData);
                    },
                  ),

                  SizedBox(height: screenHeight * 0.1),
                ],
              ),
            ),
          ),
        )
    );
  }

  // Helper to handle navigation after match creation
  void _handleMatchCreation(BuildContext context, Map<String, dynamic>? createdMatchData) {
    if (createdMatchData != null) {
      final matchId = createdMatchData['matchId'];
      final seed = createdMatchData['seed'];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QRHostScreen(
            matchId: matchId,
            seed: seed,
            isPlayer1: true,
            playerId: widget.userId,
            subject: _selectedSubject, // <--- Pass the selected subject
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create match. Please try again.')),
      );
    }
  }
}