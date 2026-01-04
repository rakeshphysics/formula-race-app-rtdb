// // -------------------------------------------------------------
// // SoloModeSelectionScreen.dart → Final version
// // -------------------------------------------------------------
// // - Buttons centered
// // - Buttons sized by screenWidth / screenHeight
// // - Dark theme (black background, white text)
// // -------------------------------------------------------------
//
// // -------------------- CHUNK 1 — IMPORT -----------------------
// import 'package:flutter/material.dart';
// import 'solo_screen.dart'; // import your SoloScreen
// import 'chapter_selection_screen.dart';
// import '../widgets/glow_button_cyan.dart';
// import 'home_screen.dart';
//
//
// // -------------------- CHUNK 2 — CLASS HEADER -----------------
// class SoloModeSelectionScreen extends StatelessWidget {
//   final String userId;
//   const SoloModeSelectionScreen({super.key, required this.userId});
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
//       await Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen(userId:userId,)),
//       );
//       return false;
//     },
//
//     child: Scaffold(
//       backgroundColor: Colors.black, // DARK THEME
//
//       appBar: AppBar(
//         backgroundColor: Colors.black, // DARK THEME
//         title: Text(
//             'Choose Portion', style: TextStyle(fontSize:screenWidth*0.042,color: Color(0xD9FFFFFF))),
//         iconTheme: const IconThemeData(color: Color(0xD9FFFFFF)),
//       ),
//
//       body: Center( // CENTER THE COLUMN
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//
//             // -------------------- CHUNK 4 — BUTTONS -----------------
//          GlowButtonCyan(
//               label: 'Chapter Wise',
//               width: screenWidth * 0.8,
//               height: screenHeight * 0.08,
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => ChapterSelectionScreen(userId:userId),
//                   ),
//                 );
//               },
//
//         ),
//
//             SizedBox(height: screenHeight * 0.024),
//
//             GlowButtonCyan(
//               label: 'Full 11th',
//               width: screenWidth * 0.8,
//               height: screenHeight * 0.08,
//               onPressed: () {
//                 _startSoloGame(context, 'full11');
//               },
//             ),
//
//             SizedBox(height: screenHeight * 0.024),
//
//             GlowButtonCyan(
//               label: 'Full 12th',
//               width: screenWidth * 0.8,
//               height: screenHeight * 0.08,
//               onPressed: () {
//                 _startSoloGame(context, 'full12');
//               },
//             ),
//
//             SizedBox(height: screenHeight * 0.024),
//
//             GlowButtonCyan(
//               label: '11th + 12th',
//               width: screenWidth * 0.8,
//               height: screenHeight * 0.08,
//               onPressed: () {
//                 _startSoloGame(context, 'fullBoth');
//               },
//             ),
//
//           ],
//         ),
//       ),
//     ));
//   }
//
//   // -------------------- CHUNK 5 — START SOLO GAME -----------------
//   void _startSoloGame(BuildContext context, String mode) {
//     final String gameSessionId = DateTime.now().millisecondsSinceEpoch.toString();
//     //print('✅✅✅✅✅>>> Navigating to SoloScreen for mode: $mode <<<');
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => SoloScreen(selectedChapter: mode, userId: userId,game_session_id: gameSessionId),
//       ),
//     );
//   }
// }

// -------------------------------------------------------------
// SoloModeSelectionScreen.dart → Updated with Subject Selection
// -------------------------------------------------------------

import 'package:flutter/material.dart';
import 'solo_screen.dart';
import 'chapter_selection_screen.dart';
import '../widgets/glow_button_cyan.dart';
import 'home_screen.dart';
import 'package:formularacing/widgets/rive_viewer.dart';

class SoloModeSelectionScreen extends StatefulWidget {
  final String userId;
  const SoloModeSelectionScreen({super.key, required this.userId});

  @override
  State<SoloModeSelectionScreen> createState() => _SoloModeSelectionScreenState();
}

class _SoloModeSelectionScreenState extends State<SoloModeSelectionScreen> {
  // Default subject
  String _selectedSubject = 'Physics';

  // Define colors for subjects (using the Gold/Bronze theme you requested previously)
  final Map<String, Color> subjectColors = {
    // 'Physics': const Color(0x8000BCD4),
    // 'Chemistry': const Color(0x8000BCD4),
    // 'Maths': const Color(0x8000BCD4),
    'Physics': Colors.cyan.shade700.withOpacity(0.7),
    'Chemistry': Colors.green.shade700.withOpacity(0.7),
    'Maths': Colors.blue.shade700.withOpacity(0.7),
  };

  // Helper widget to build the subject selection buttons
  // Widget _buildSubjectButton(String subjectName) {
  //   final bool isSelected = _selectedSubject == subjectName;
  //   final Color color = subjectColors[subjectName]!;
  //
  //   return ElevatedButton(
  //     onPressed: () {
  //       setState(() {
  //         _selectedSubject = subjectName;
  //       });
  //     },
  //     style: ElevatedButton.styleFrom(
  //       backgroundColor: isSelected ? color : color.withOpacity(0.2),
  //       foregroundColor: Colors.white,
  //       elevation: isSelected ? 4 : 0,
  //       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(4),
  //         side: BorderSide(
  //           color: color,
  //           width: isSelected ? 2.5 : 1.0,
  //         ),
  //       ),
  //     ),
  //     child: Text(
  //       subjectName,
  //       style: TextStyle(
  //         fontSize: 16,
  //         fontWeight: isSelected ? FontWeight.bold : FontWeight.w200,
  //       ),
  //     ),
  //   );
  // }

  // Helper widget to build the subject selection buttons
  // Helper widget to build the subject selection buttons
  Widget _buildSubjectButton(String subjectName) {
    final bool isSelected = _selectedSubject == subjectName;
    final Color color = subjectColors[subjectName]!;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut, // Smooths the animation
          transform: isSelected ? Matrix4.identity().scaled(1.05) : Matrix4.identity().scaled(0.95),
          transformAlignment: Alignment.center, // <--- THIS FIXES THE SCALING ORIGIN
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 0,
                spreadRadius: 0,
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
              //backgroundColor: isSelected ? color.withOpacity(0.1) : Colors.grey[900],
              backgroundColor: isSelected ? color.withOpacity(0.1) : Colors.grey[900],
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(
                  color: isSelected ? color: Colors.grey[800]!,
                  width: isSelected ? 2.0 : 1.5,
                ),
              ),

            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // if (isSelected) ...[
                //   const Icon(Icons.check_circle, size: 18, color: Color(0xD9FFFFFF)),
                //   const SizedBox(width: 4),
                // ],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      subjectName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        shadows: isSelected
                            ? [
                          const Shadow(
                            blurRadius: 2.0,
                            color: Colors.black45,
                            offset: Offset(1.0, 1.0),
                          ),
                        ]
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   // Screen size
  //   final screenHeight = MediaQuery.of(context).size.height;
  //   final screenWidth = MediaQuery.of(context).size.width;
  //
  //   return WillPopScope(
  //     onWillPop: () async {
  //       await Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(builder: (context) => HomeScreen(userId: widget.userId)),
  //       );
  //       return false;
  //     },
  //     child: Scaffold(
  //       backgroundColor: Colors.black, // DARK THEME
  //       appBar: AppBar(
  //         backgroundColor: Colors.black,
  //         title: Text(
  //           'Play a Solo Game',
  //           style: TextStyle(fontSize: screenWidth * 0.042, color: const Color(0xD9FFFFFF)),
  //         ),
  //         iconTheme: const IconThemeData(color: Color(0xD9FFFFFF)),
  //       ),
  //       // 1. REMOVED 'Center' WIDGET
  //       body: SingleChildScrollView(
  //         child: SizedBox(
  //           width: double.infinity, // Ensures content is centered horizontally
  //           child: Column(
  //             mainAxisAlignment: MainAxisAlignment.start, // Aligns content to top
  //             crossAxisAlignment: CrossAxisAlignment.center, // Centers buttons horizontally
  //             children: [
  //               // 2. ADDED TOP SPACING
  //               //SizedBox(height: screenHeight * 0.05),
  //
  //
  //               Padding(
  //                 padding: const EdgeInsets.only(top: 0.0, bottom: 15.0),
  //                 child: Text(
  //                   "................................................................................................................................................",
  //                   maxLines: 1,
  //                   overflow: TextOverflow.clip, // Cuts off extra dots so it fits perfectly
  //                   softWrap: false,
  //                   textAlign: TextAlign.center,
  //                   style: TextStyle(
  //                     color: Colors.white.withOpacity(0.7),
  //                     fontSize: 20,
  //                     fontWeight: FontWeight.w900,
  //                     letterSpacing: 1, // Adjust this to change space between dots
  //                     height: 0.5, // Reduces vertical height
  //                   ),
  //                 ),
  //               ),
  //               // SUBJECT SELECTION ROW
  //               Padding(
  //                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
  //                 child: Row(
  //                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //                   children: [
  //                     _buildSubjectButton('Physics'),
  //                     _buildSubjectButton('Chemistry'),
  //                     _buildSubjectButton('Maths'),
  //                   ],
  //                 ),
  //               ),
  //
  //               Padding(
  //                 padding: const EdgeInsets.only(top: 8.0, bottom: 40.0),
  //                 child: Text(
  //                   "................................................................................................................................................",
  //                   maxLines: 1,
  //                   overflow: TextOverflow.clip, // Cuts off extra dots so it fits perfectly
  //                   softWrap: false,
  //                   textAlign: TextAlign.center,
  //                   style: TextStyle(
  //                     color: Colors.white.withOpacity(0.7),
  //                     fontSize: 20,
  //                     fontWeight: FontWeight.w900,
  //                     letterSpacing: 1, // Adjust this to change space between dots
  //                     height: 0.5, // Reduces vertical height
  //                   ),
  //                 ),
  //               ),
  //
  //               // MAIN BUTTONS
  //               GlowButtonCyan(
  //                 label: 'Chapter Wise',
  //                 width: screenWidth * 0.8,
  //                 height: screenHeight * 0.08,
  //                 glowColor: subjectColors[_selectedSubject]!,
  //                 onPressed: () {
  //                   Navigator.push(
  //                     context,
  //                     MaterialPageRoute(
  //                       builder: (context) => ChapterSelectionScreen(
  //                         userId: widget.userId,
  //                         subject: _selectedSubject,
  //                       ),
  //                     ),
  //                   );
  //                 },
  //               ),
  //               SizedBox(height: screenHeight * 0.024),
  //               GlowButtonCyan(
  //                 label: 'Full 11th',
  //                 width: screenWidth * 0.8,
  //                 height: screenHeight * 0.08,
  //                 glowColor: subjectColors[_selectedSubject]!,
  //                 onPressed: () {
  //                   _startSoloGame(context, 'full11');
  //                 },
  //               ),
  //               SizedBox(height: screenHeight * 0.024),
  //               GlowButtonCyan(
  //                 label: 'Full 12th',
  //                 width: screenWidth * 0.8,
  //                 height: screenHeight * 0.08,
  //                 glowColor: subjectColors[_selectedSubject]!,
  //                 onPressed: () {
  //                   _startSoloGame(context, 'full12');
  //                 },
  //               ),
  //               SizedBox(height: screenHeight * 0.024),
  //               GlowButtonCyan(
  //                 label: '11th + 12th',
  //                 width: screenWidth * 0.8,
  //                 height: screenHeight * 0.08,
  //                 glowColor: subjectColors[_selectedSubject]!,
  //                 onPressed: () {
  //                   _startSoloGame(context, 'fullBoth');
  //                 },
  //               ),
  //
  //               // Bottom spacing for scrolling
  //               SizedBox(height: screenHeight * 0.1),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    // Screen size
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return WillPopScope(
      onWillPop: () async {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(userId: widget.userId)),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black, // DARK THEME
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(
            'Play a Solo Game',
            style: TextStyle(fontSize: screenWidth * 0.042, color: const Color(0xD9FFFFFF)),
          ),
          iconTheme: const IconThemeData(color: Color(0xD9FFFFFF)),
        ),
        // SWITCH TO COLUMN TO MANAGE LAYOUT VERTICALLY
        body: Column(
          children: [
            // 1. TOP CONTENT (Your existing buttons, wrapped in Expanded/SingleChildScrollView)
            Expanded(
              child: SingleChildScrollView(
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 0.0, bottom: 15.0),
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
                      // SUBJECT SELECTION ROW
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

                      // MAIN BUTTONS
                      GlowButtonCyan(
                        label: 'Chapter Wise',
                        width: screenWidth * 0.8,
                        height: screenHeight * 0.08,
                        glowColor: subjectColors[_selectedSubject]!,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChapterSelectionScreen(
                                userId: widget.userId,
                                subject: _selectedSubject,
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: screenHeight * 0.024),
                      GlowButtonCyan(
                        label: 'Full 11th',
                        width: screenWidth * 0.8,
                        height: screenHeight * 0.08,
                        glowColor: subjectColors[_selectedSubject]!,
                        onPressed: () {
                          _startSoloGame(context, 'full11');
                        },
                      ),
                      SizedBox(height: screenHeight * 0.024),
                      GlowButtonCyan(
                        label: 'Full 12th',
                        width: screenWidth * 0.8,
                        height: screenHeight * 0.08,
                        glowColor: subjectColors[_selectedSubject]!,
                        onPressed: () {
                          _startSoloGame(context, 'full12');
                        },
                      ),
                      SizedBox(height: screenHeight * 0.024),
                      GlowButtonCyan(
                        label: '11th + 12th',
                        width: screenWidth * 0.8,
                        height: screenHeight * 0.08,
                        glowColor: subjectColors[_selectedSubject]!,
                        onPressed: () {
                          _startSoloGame(context, 'fullBoth');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. BOTTOM ANIMATION (Fills remaining space at the bottom)
            SizedBox(
              height: screenWidth * 0.8/1.5 ,// Adjust height as needed (e.g., 25% of screen)
              width: screenWidth * 0.8,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Opacity(
                       opacity: 0.9,// Handles the alignment here
                child: FormulaRiveViewer(
                  src: 'assets/pandaai/soloGame.riv',
                ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  void _startSoloGame(BuildContext context, String mode) {
    final String gameSessionId = DateTime.now().millisecondsSinceEpoch.toString();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SoloScreen(
          selectedChapter: mode,
          userId: widget.userId,
          game_session_id: gameSessionId,
          subject: _selectedSubject,
          // IMPORTANT: You likely need to update SoloScreen to accept the subject!
          // subject: _selectedSubject,
        ),
      ),
    );
  }
}