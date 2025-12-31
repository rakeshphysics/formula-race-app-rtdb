// // -------------------------------------------------------------
// // AITrackerScreen.dart
// // -------------------------------------------------------------
// // Screen to show user mistakes → per chapter → dropdown list.
// // Data comes from users/{userId}/weak_areas → MistakeTrackerService.
// // Chapters sorted by total mistakes.
// // -------------------------------------------------------------
//
// // -------------------- CHUNK 1 — IMPORT -----------------------
// //import 'solo_screen.dart';
// import 'package:flutter/material.dart';
// //import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_math_fork/flutter_math.dart';
// import 'clear_mistakes_screen.dart'; // instead of solo_screen.dart
// import '../../services/mistake_tracker_service.dart';
// import 'package:flutter_html/flutter_html.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import 'package:confetti/confetti.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:model_viewer_plus/model_viewer_plus.dart';
// import 'package:formularacing/widgets/rive_viewer.dart';
//
// //.......START.......Render chapter names Correctly......................
// // String formatChapter(String input) {
// //   return input
// //       .split('_')
// //       .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
// //       .join(' ');
// // }
//
// String formatChapter(String input) {
//   // Define a map for specific acronyms or multi-word exceptions.
//   final Map<String, String> specialCases = {
//     'shm': 'SHM',
//     'emi': 'EMI',
//     'em_waves': 'EM Waves',
//     'ac': 'AC',
//     'xrays':'X Rays'
//   };
//
//   // Convert the input to a consistent format (lowercase with underscores) for the lookup.
//   final formattedInput = input.toLowerCase().replaceAll(' ', '_');
//
//   // Check if the formatted input is a special case.
//   if (specialCases.containsKey(formattedInput)) {
//     return specialCases[formattedInput]!;
//   }
//
//   // If not a special case, format the string by capitalizing each word and joining with a space.
//   return input
//       .split('_')
//       .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
//       .join(' ');
// }
// //.......END.......Render chapter names Correctly...........................
//
// // -------------------- CHUNK 2 — CLASS HEADER -----------------
// class AITrackerScreen extends StatefulWidget {
//   final String userId; // Pass current userId
//
//   const AITrackerScreen({Key? key, required this.userId}) : super(key: key);
//
//   @override
//   State<AITrackerScreen> createState() => _AITrackerScreenState();
// }
//
// // -------------------- CHUNK 3 — STATE CLASS -----------------
// class _AITrackerScreenState extends State<AITrackerScreen> {
//   Map<String, List<Map<String, dynamic>>> chapterMistakes = {};
//   Map<String, int> chapterTotals = {};
//   Map<String, bool> chapterExpanded = {}; // for dropdown state
//   bool isLoading = true;
//  late ConfettiController _confettiController;
//
//   @override
//   void initState() {
//     super.initState();
//     _confettiController = ConfettiController(duration: const Duration(seconds: 2));
//     _loadMistakes();
//   }
//
//
//   @override
//   void dispose() {
//     // _confettiControllerSmall.dispose();
//     // _confettiControllerLarge.dispose(); // ADD THIS LINE
//     _confettiController.dispose();
//     super.dispose();
//   }
//
//   // ... rest of the class
//
//   // -------------------- CHUNK 4 — LOAD MISTAKES -----------------
//   Future<void> _loadMistakes() async {
//     List<Map<String, dynamic>> all = await MistakeTrackerService.loadMistakesFromLocal();
//
//    // print('Loaded ${all.length} mistakes from local.');
//
//     Map<String, List<Map<String, dynamic>>> tempChapterMistakes = {};
//     Map<String, int> tempChapterTotals = {};
//
//     for (var q in all) {
//      // String chapter = q['tags']?['chapter'] ?? 'Unknown';
//       String chapter = (q['tags']?['chapter'] ?? q['chapter'] ?? 'Unknown').toString();
//
//       tempChapterMistakes.putIfAbsent(chapter, () => []);
//       tempChapterMistakes[chapter]!.add({
//         'formula': q['question'],
//         'answer': q['answer'],       // ✅ load the answer
//         'image': q['image'],         // ✅ load the image
//         'mistakeCount': 1,
//         'tip': q['tip'],
//       });
//
//
//       tempChapterTotals[chapter] = (tempChapterTotals[chapter] ?? 0) + 1;
//     }
//
//     // Sort chapters by total mistakes descending
//     List<MapEntry<String, int>> sortedChapters = tempChapterTotals.entries.toList()
//       ..sort((a, b) => b.value.compareTo(a.value));
//
//     Map<String, List<Map<String, dynamic>>> finalChapterMistakes = {};
//     Map<String, int> finalChapterTotals = {};
//     Map<String, bool> expandedState = {};
//
//     for (var entry in sortedChapters) {
//       String chapter = entry.key;
//       finalChapterMistakes[chapter] = tempChapterMistakes[chapter]!;
//       finalChapterTotals[chapter] = entry.value;
//       expandedState[chapter] = false; // collapsed
//     }
//
//     setState(() {
//       chapterMistakes = finalChapterMistakes;
//       chapterTotals = finalChapterTotals;
//       chapterExpanded = expandedState;
//       isLoading = false;
//     });
//   }
//
//
//   // -------------------- CHUNK 5 — BUILD FUNCTION -----------------
//   @override
//   Widget build(BuildContext context) {
//     final double screenWidth = MediaQuery.of(context).size.width;
//     final double screenHeight = MediaQuery.of(context).size.height;
//
//     // Calculate total active mistakes
//     int totalActiveMistakes = chapterMistakes.entries.fold(0, (sum, entry) {
//       return sum + entry.value.fold(0, (chapterSum, formulaEntry) {
//         return chapterSum + (formulaEntry['mistakeCount'] as int);
//       });
//     });
//
//
//     return Stack(
//    alignment: Alignment.topCenter,
//     children:[
//     Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         title:  Text('My Mistakes', style: TextStyle(fontSize:screenWidth*0.04,color: Colors.black)),
//         iconTheme: const IconThemeData(color: Color(0xD9FFFFFF)),
//         actions: [
//           if (totalActiveMistakes >= 1)
//
//         Padding(
//             padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
//            child: OutlinedButton(
//               onPressed: () async {
//                 final resolvedCount = await Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => const ClearMistakesScreen(),
//                   ),
//                 );
//
//                 if (resolvedCount != null && resolvedCount > 0) {
//
//                   // if (resolvedCount < 5) {
//                   //   _confettiControllerSmall.play(); // Play the small animation
//                   // } else {
//                   //   _confettiControllerLarge.play(); // Play the large animation
//                   // }
//
//                   _confettiController.play();
//
//                   showDialog(
//                     context: context,
//                     builder: (_) => Stack(
//                             alignment: Alignment.topCenter,
//                             children: [
//                         AlertDialog(
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(4.0),
//                         side: BorderSide(color: Colors.red, width: 0.8),
//                       ),
//                       backgroundColor: Color(0xFF000000),
//                       title: Text(
//                         resolvedCount == 1 // MODIFIED THIS LINE
//                             ? "1 Mistake Resolved  🎉"
//                             : "$resolvedCount Mistakes Resolved  🎉",
//                         style: TextStyle(color: Color(0xD9FFFFFF), fontSize:screenWidth*0.044), // Ensure text color is visible
//                         textAlign: TextAlign.center, // Center the text
//                       ),
//                       //content: SizedBox(height: screenWidth*0.02),
//                       actions: [
//                         Row(
//                         mainAxisAlignment: MainAxisAlignment.center, // Center the content of the Row
//                         children: [
//                         OutlinedButton(
//                           onPressed: () => Navigator.pop(context),
//                           style: OutlinedButton.styleFrom(
//                             side: BorderSide(color: const Color(0xD9FF0000), width: 0.8), // Made border thinner (was 1.5)
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(4.0),
//                             ),
//                           ),
//                           child:  Text(
//                             "OK",
//                             style: TextStyle(
//                               color: Color(0xD9FFFFFF),
//                               fontSize: screenWidth*0.04,
//                             ),
//                           ),
//                         ),
//                          ],
//                         ),
//                       ],
//                     ),
//
//                               ConfettiWidget(
//                                 confettiController: _confettiController,
//                                 blastDirectionality: BlastDirectionality.explosive,
//                                 shouldLoop: false,
//                                 numberOfParticles: resolvedCount == 1 ? 5 : (resolvedCount < 5 ? 10 : (resolvedCount < 10 ? 20 : 40)),
//                                 gravity: 0.3,
//                                 emissionFrequency: 0.03,
//                                 colors: const [
//                                   Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple
//                                 ],
//                               ),],),
//                   );
//                   // Optional: reload mistakes from Firebase
//                   _loadMistakes();
//                 }
//               },
//
//               style: OutlinedButton.styleFrom(
//                 // Border color and width are controlled by the 'side' property.
//                 side: BorderSide(
//                   color: Colors.redAccent, // Change the border color here
//                   width: 1.2,              // Change the border thickness here
//                 ),
//                 // Border radius and shape are controlled by the 'shape' property.
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(4), // Change the corner radius here
//                 ),
//                 padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.015),
//               ),
//
//               child: Text(
//                 'Clear Mistakes',
//                 style: TextStyle(fontSize:screenWidth*0.04,color: Colors.redAccent),
//               ),
//             ),
//         ),
//
//         ],
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : chapterMistakes.isEmpty
//           ? const Center(
//         child: Text(
//           'No mistakes to show.',
//           style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal, color: Color(0xD9FFFFFF)),
//         ),
//       )
//           : ListView(
//         padding:  EdgeInsets.all(screenWidth*0.03),
//         children: [
//
//
//
//
//           // ---------- TOTAL ACTIVE MISTAKES → NEW PART ----------
//           Padding(
//             padding:  EdgeInsets.symmetric(vertical: screenHeight*0.01),
//             child: Text(
//               'Total active Mistakes: $totalActiveMistakes',
//               style:TextStyle(fontSize: screenWidth*0.043, color: Color(0xD9FFFFFF), fontWeight: FontWeight.w500),
//             ),
//           ),
//           // -----------------------------------------------------
//
//           // ---------- EXISTING CHAPTER LIST ----------
//           ...chapterMistakes.entries.map((entry) {
//             String chapter = entry.key;
//             int totalMistakes = chapterTotals[chapter]!;
//             bool expanded = chapterExpanded[chapter]!;
//
//             return Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//
//
//
//                 ListTile(
//                   title: Text(
//                     '${formatChapter(chapter)} — $totalMistakes',
//                     style:  TextStyle(fontWeight: FontWeight.normal, fontSize: screenWidth*0.041),
//                   ),
//                   trailing: Icon(
//                     expanded ? Icons.expand_less : Icons.expand_more,
//                   ),
//                   onTap: () {
//                     setState(() {
//                       chapterExpanded[chapter] = !expanded;
//                     });
//                   },
//                 ),
//                 if (expanded)
//                   Padding(
//                     padding: const EdgeInsets.only(left: 16.0),
//                     child: Column(
//                       children: entry.value.map((formulaEntry) {
//                         String formula = formulaEntry['formula'];
//                         int count = formulaEntry['mistakeCount'];
//
//                         return Material(
//                           color: Colors.transparent,
//                           child: InkWell(
//                             borderRadius: BorderRadius.circular(12),
//                             onLongPress: () {
//                               // Optional: do something on long press (like show full solution)
//                             },
//                             splashColor: Colors.redAccent.withOpacity(0.3),
//                             highlightColor: Colors.red.withOpacity(0.1),
//                             child: Container(
//                               width: double.infinity,
//                               margin: const EdgeInsets.symmetric(vertical: 8),
//                               padding: const EdgeInsets.all(12),
//                               decoration: BoxDecoration(
//                                 color: Colors.black,
//                                 borderRadius: BorderRadius.circular(12),
//                                 border: Border.all(
//                                   color: Colors.redAccent.withOpacity(0.6),
//                                   width: 1.5,
//                                 ),
//                               ),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   // if (formulaEntry['image'] != null && formulaEntry['image'].toString().isNotEmpty)
//                                   //   Padding(
//                                   //         padding:  EdgeInsets.only(bottom: screenWidth * 0.02),
//                                   //         child: Center(
//                                   //           child: SizedBox(
//                                   //             width: screenWidth * 0.6,
//                                   //             height: (screenWidth * 0.6) / 1.5,
//                                   //         child: Image.asset(
//                                   //        formulaEntry['image'],
//                                   //         fit: BoxFit.contain,
//                                   //          errorBuilder: (context, error, stackTrace) => const Text(
//                                   //         'Image not found',
//                                   //         style: TextStyle(color: Colors.redAccent),
//                                   //       ),
//                                   //     ),),),
//                                   //   ),
//
//                                   // if (formulaEntry['image'] != null && formulaEntry['image'].toString().isNotEmpty)
//                                   //   Padding(
//                                   //     padding: EdgeInsets.only(bottom: screenWidth * 0.02),
//                                   //     child: Center(
//                                   //       child: SizedBox(
//                                   //         width: screenWidth * 0.6,
//                                   //         height: (screenWidth * 0.6) / 1.5, // Maintain the same aspect ratio
//                                   //         child: SvgPicture.asset(
//                                   //           formulaEntry['image'], // This path now correctly points to a .svg
//                                   //           fit: BoxFit.contain,
//                                   //         ),
//                                   //       ),
//                                   //     ),
//                                   //   ),
//
//                                   // ... inside the Column's children array in the _buildFormulaCard method
//
//                                   if (formulaEntry['image'] != null && formulaEntry['image'].toString().isNotEmpty)
//                                     Padding(
//                                       padding: EdgeInsets.only(bottom: screenWidth * 0.02),
//                                       child: Center(
//                                         child: SizedBox(
//                                           width: screenWidth * 0.6,
//                                           height: (screenWidth * 0.6) / 1.5,
//                                           child: formulaEntry['image'].endsWith('.svg')
//                                               ? SvgPicture.asset(
//                                             formulaEntry['image'],
//                                             fit: BoxFit.contain,
//                                             placeholderBuilder: (context) => const SizedBox.shrink(), // Optional: handle loading/errors
//                                           )
//                                               : Image.asset(
//                                             formulaEntry['image'],
//                                             fit: BoxFit.contain,
//                                             errorBuilder: (context, error, stackTrace) => const Text(
//                                               'Image not found',
//                                               style: TextStyle(color: Colors.redAccent),
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//
// // ... rest of the widgets in the Column
//
//
//                                   Html(
//                                     data: 'Q: ${formulaEntry['formula']}',
//                                     style: {
//                                       "body": Style(
//                                         fontSize: FontSize(screenWidth * 0.037),
//                                         color: Color(0xFFDCDCDC),
//                                         fontFamily: GoogleFonts.poppins().fontFamily,
//                                         margin: Margins.zero,
//                                       ),
//                                     },
//                                   ),
//                                   SizedBox(height: screenWidth * 0.016),
//
//                         SingleChildScrollView(
//                         scrollDirection: Axis.horizontal,
//                         physics: const BouncingScrollPhysics(),
//                                   child:Math.tex(
//                                     'Ans: ${formulaEntry['answer']}',
//                                     textStyle:  TextStyle(fontSize: screenWidth * 0.043, color: Colors.greenAccent),
//                                   ),
//                         ),
//
//                                   Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       if (formulaEntry['tip'] != null && formulaEntry['tip'].toString().isNotEmpty) ...[
//                                         SizedBox(height: screenWidth*0.05), // Spacing before tip
//                                         Text( // 'Tip:' label
//                                           'Tip:',
//                                           style: GoogleFonts.poppins(
//                                             color: Color(0xFFF8A46F),
//                                             fontSize:screenWidth * 0.045,
//                                             fontWeight: FontWeight.w600,
//                                             fontStyle: FontStyle.italic,
//                                           ),
//                                         ),
//                                         SizedBox(height: screenWidth*0.01),
//                                         Text( // Actual tip content
//                                           formulaEntry['tip'].toString(), // Ensure it's a string
//                                           style: GoogleFonts.poppins(
//                                             color: Color(0xFFF8A46F),
//                                             fontSize: screenWidth * 0.039,
//                                             fontStyle: FontStyle.italic,
//
//                                           ),
//                                         ),
//                                       ],
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         );
//
//
//                       }).toList(),
//
//                     ),
//                   ),
//                 const Divider(),
//               ],
//             );
//           }).toList(),
//           ////...........TEMPORARY......START..........BUTTON TO DEL MISTAKES JSON FILE .............................
//           //  Padding(
//           //    padding: const EdgeInsets.only(top: 20.0, bottom: 40.0),
//           //    child: Center(
//           //      child: ElevatedButton(
//           //        onPressed: () => deleteMistakeTrackerJson(context),
//           //        child: Text('CLEAR MISTAKES'),
//           //     ),
//           //    ),
//           //  ),
// ////...........TEMPORARY......END..........BUTTON TO DEL MISTAKES JSON FILE .........
//
//         ],
//       ),
//     ),
//
//     //   ConfettiWidget(
//     //     confettiController: _confettiControllerSmall,
//     // blastDirectionality: BlastDirectionality.explosive,
//     // shouldLoop: false,
//     // numberOfParticles: 15, // Fewer particles
//     // emissionFrequency: 0.03,
//     // gravity: 0.2,
//     // colors: const [Colors.green, Colors.blue, Colors.pink],
//     // ),
//     //
//     // // ADD another ConfettiWidget for the LARGE blast
//     // ConfettiWidget(
//     // confettiController: _confettiControllerLarge,
//     // blastDirectionality: BlastDirectionality.explosive,
//     // shouldLoop: false,
//     // numberOfParticles: 60, // More particles
//     // emissionFrequency: 0.01,
//     // gravity: 0.3,
//     // colors: const [Colors.orange, Colors.purple, Colors.yellow, Colors.red],
//     // ),
//     ],
//     );
//   }
// }
//
// //...........TEMPORARY......START...........FUNCTION TO DEL MISTAKES JSON FILE .................................
// // Future<void> deleteMistakeTrackerJson(BuildContext context) async {
// //   final dir = await getApplicationDocumentsDirectory();
// //   final file = File('${dir.path}/my_mistakes.json');
// //
// //   if (await file.exists()) {
// //     await file.delete();
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(content: Text('Mistake tracker cleared')),
// //     );
// //   } else {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(content: Text('No mistake file found')),
// //     );
// //   }
// //
// //   // ✅ Reload the screen with empty mistakes
// //   if (context.mounted) {
// //     final state = context.findAncestorStateOfType<_AITrackerScreenState>();
// //     state?._loadMistakes();
// //   }
// // }
//
// //...........TEMPORARY.......END...........FUNCTION TO DEL MISTAKES JSON FILE .................................

// -------------------------------------------------------------
// AITrackerScreen.dart
// -------------------------------------------------------------
// Screen to show user mistakes → per chapter → dropdown list.
// Data comes from users/{userId}/weak_areas → MistakeTrackerService.
// Chapters sorted by total mistakes.
// -------------------------------------------------------------

// -------------------- CHUNK 1 — IMPORT -----------------------
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'clear_mistakes_screen.dart';
import '../../services/mistake_tracker_service.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:formularacing/widgets/rive_viewer.dart'; // Ensure this path is correct

//.......START.......Render chapter names Correctly......................
String formatChapter(String input) {
  final Map<String, String> specialCases = {
    'shm': 'SHM',
    'emi': 'EMI',
    'em_waves': 'EM Waves',
    'ac': 'AC',
    'xrays': 'X Rays'
  };

  final formattedInput = input.toLowerCase().replaceAll(' ', '_');

  if (specialCases.containsKey(formattedInput)) {
    return specialCases[formattedInput]!;
  }

  return input
      .split('_')
      .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
      .join(' ');
}
//.......END.......Render chapter names Correctly...........................

// -------------------- CHUNK 2 — CLASS HEADER -----------------
class AITrackerScreen extends StatefulWidget {
  final String userId;

  const AITrackerScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<AITrackerScreen> createState() => _AITrackerScreenState();
}

// -------------------- CHUNK 3 — STATE CLASS -----------------
class _AITrackerScreenState extends State<AITrackerScreen> with SingleTickerProviderStateMixin {
  // Data structures for each subject
  Map<String, Map<String, List<Map<String, dynamic>>>> subjectMistakes = {
    'Physics': {},
    'Chemistry': {},
    'Maths': {},
  };

  Map<String, Map<String, int>> subjectChapterTotals = {
    'Physics': {},
    'Chemistry': {},
    'Maths': {},
  };

  Map<String, bool> chapterExpanded = {};
  bool isLoading = true;
  late ConfettiController _confettiController;
  late TabController _tabController;

  // Track active 3D models
  final Set<String> _active3DIndices = {};

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _tabController = TabController(length: 3, vsync: this);
    _loadMistakes();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _activate3DModel(String id) {
    setState(() {
      if (_active3DIndices.length >= 6) {
        _active3DIndices.remove(_active3DIndices.first);
      }
      _active3DIndices.add(id);
    });
  }

  void _deactivate3DModel(String id) {
    setState(() {
      _active3DIndices.remove(id);
    });
  }

  // 1. Add this helper function to guess subject from chapter name
  String _guessSubjectFromChapter(String chapter) {
    String c = chapter.toLowerCase();

    // MATHS KEYWORDS (Updated to include Conic Sections)
    if (c == 'ellipse' ||
        c == '3d geometry' ||
        c.contains('geometry') ||
        c.contains('ellipse')) {
      return 'Maths';
    }

    // --- CHEMISTRY CHAPTERS ---
    // Explicit checks for your current Chemistry chapters
    if (c == 'solid state' ||
        c == 'chemical equilibrium' ||
        c.contains('chemical') ||
        c.contains('solid')) {
      return 'Chemistry';
    }

    // Default to Physics
    return 'Physics';
  }

  // -------------------- CHUNK 4 — LOAD MISTAKES -----------------
// -------------------- CHUNK 4 — LOAD MISTAKES -----------------
  Future<void> _loadMistakes() async {
    List<Map<String, dynamic>> all = await MistakeTrackerService.loadMistakesFromLocal();

    // Temporary storage
    Map<String, Map<String, List<Map<String, dynamic>>>> tempSubjectMistakes = {
      'Physics': {},
      'Chemistry': {},
      'Maths': {},
    };
    Map<String, Map<String, int>> tempSubjectTotals = {
      'Physics': {},
      'Chemistry': {},
      'Maths': {},
    };

    for (var q in all) {
      String chapter = (q['tags']?['chapter'] ?? q['chapter'] ?? 'Unknown').toString();

      // 1. Try to get subject from saved data
      String? rawSubject = q['tags']?['subject'] ?? q['subject'];
      String subject;

      // 2. If subject is missing, GUESS it using your helper function
      if (rawSubject == null || rawSubject.toString().isEmpty || rawSubject.toString() == 'null') {
        subject = _guessSubjectFromChapter(chapter); // <--- CALLED HERE
      } else {
        subject = rawSubject.toString();
      }

      // 3. Normalize subject string (Safety check)
      if (subject.toLowerCase().contains('math')) subject = 'Maths';
      else if (subject.toLowerCase().contains('chem')) subject = 'Chemistry';
      else subject = 'Physics';

      // Initialize list if needed
      tempSubjectMistakes[subject]!.putIfAbsent(chapter, () => []);

      tempSubjectMistakes[subject]![chapter]!.add({
        'formula': q['question'],
        'answer': q['answer'],
        'image': q['image'],
        'mistakeCount': 1,
        'tip': q['tip'],
      });

      tempSubjectTotals[subject]![chapter] = (tempSubjectTotals[subject]![chapter] ?? 0) + 1;
    }

    // Sort chapters within each subject
    Map<String, Map<String, List<Map<String, dynamic>>>> finalSubjectMistakes = {};
    Map<String, Map<String, int>> finalSubjectTotals = {};
    Map<String, bool> expandedState = {};

    for (String subj in ['Physics', 'Chemistry', 'Maths']) {
      var sortedChapters = tempSubjectTotals[subj]!.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      finalSubjectMistakes[subj] = {};
      finalSubjectTotals[subj] = {};

      for (var entry in sortedChapters) {
        finalSubjectMistakes[subj]![entry.key] = tempSubjectMistakes[subj]![entry.key]!;
        finalSubjectTotals[subj]![entry.key] = entry.value;
        expandedState[entry.key] = false;
      }
    }

    setState(() {
      subjectMistakes = finalSubjectMistakes;
      subjectChapterTotals = finalSubjectTotals;
      chapterExpanded = expandedState;
      isLoading = false;
    });
  }

  // -------------------- CHUNK 5 — BUILD FUNCTION -----------------
  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    // Calculate total active mistakes across all subjects
    int totalActiveMistakes = 0;
    subjectMistakes.forEach((key, value) {
      value.forEach((k, v) {
        totalActiveMistakes += v.length;
      });
    });

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: Text('My Mistakes', style: TextStyle(fontSize: screenWidth * 0.04, color: Colors.white)),
            iconTheme: const IconThemeData(color: Color(0xD9FFFFFF)),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.redAccent,
              labelColor: Colors.redAccent,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: 'Physics'),
                Tab(text: 'Chemistry'),
                Tab(text: 'Maths'),
              ],
            ),
            actions: [
              if (totalActiveMistakes >= 1)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                  child: OutlinedButton(
                    onPressed: () async {

                      final int tabIndex = _tabController.index;
                      final String currentSubject = ['Physics', 'Chemistry', 'Maths'][tabIndex];

                      // 2. Check if there are mistakes to clear for this subject
                      final int totalSubjectMistakes = subjectChapterTotals[currentSubject]?.values.fold(0, (sum, count) => sum! + count!) ?? 0;

                      if (totalSubjectMistakes == 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('No mistakes to clear in $currentSubject!'),
                            backgroundColor: Colors.grey.shade800,
                          ),
                        );
                        return;
                      }


                      final resolvedCount = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClearMistakesScreen(subject: currentSubject),
                        ),
                      );

                      if (resolvedCount != null && resolvedCount > 0) {
                        _confettiController.play();
                        showDialog(
                          context: context,
                          builder: (_) => Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                  side: const BorderSide(color: Colors.red, width: 0.8),
                                ),
                                backgroundColor: const Color(0xFF000000),
                                title: Text(
                                  resolvedCount == 1
                                      ? "1 Mistake Resolved  🎉"
                                      : "$resolvedCount Mistakes Resolved  🎉",
                                  style: TextStyle(color: const Color(0xD9FFFFFF), fontSize: screenWidth * 0.044),
                                  textAlign: TextAlign.center,
                                ),
                                actions: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Color(0xD9FF0000), width: 0.8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4.0),
                                          ),
                                        ),
                                        child: Text(
                                          "OK",
                                          style: TextStyle(
                                            color: const Color(0xD9FFFFFF),
                                            fontSize: screenWidth * 0.04,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              ConfettiWidget(
                                confettiController: _confettiController,
                                blastDirectionality: BlastDirectionality.explosive,
                                shouldLoop: false,
                                numberOfParticles: resolvedCount == 1 ? 5 : (resolvedCount < 5 ? 10 : (resolvedCount < 10 ? 20 : 40)),
                                gravity: 0.3,
                                emissionFrequency: 0.03,
                                colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
                              ),
                            ],
                          ),
                        );
                        _loadMistakes();
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.015),
                    ),
                    child: Text(
                      'Clear Mistakes',
                      style: TextStyle(fontSize: screenWidth * 0.04, color: Colors.redAccent),
                    ),
                  ),
                ),
            ],
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
            controller: _tabController,
            children: [
              _buildSubjectList('Physics', screenWidth, screenHeight),
              _buildSubjectList('Chemistry', screenWidth, screenHeight),
              _buildSubjectList('Maths', screenWidth, screenHeight),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectList(String subject, double screenWidth, double screenHeight) {
    var mistakes = subjectMistakes[subject] ?? {};
    var totals = subjectChapterTotals[subject] ?? {};

    if (mistakes.isEmpty) {
      return Center(
        child: Text(
          'No mistakes in $subject.',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal, color: Color(0xD9FFFFFF)),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.all(screenWidth * 0.03),
      children: [
        // Total count for this subject
        Padding(
          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
          child: Text(
            'Total $subject Mistakes: ${totals.values.fold(0, (sum, count) => sum + count)}',
            style: TextStyle(fontSize: screenWidth * 0.043, color: const Color(
                0xD9FF5252), fontWeight: FontWeight.w500),
          ),
        ),

        ...mistakes.entries.map((entry) {
          String chapter = entry.key;
          int totalMistakes = totals[chapter]!;
          bool expanded = chapterExpanded[chapter] ?? false;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(
                  '${formatChapter(chapter)} — $totalMistakes',
                  style: TextStyle(fontWeight: FontWeight.normal, fontSize: screenWidth * 0.041, color: Color(
                      0xD9FFFFFF)),
                ),
                trailing: Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white70,
                ),
                onTap: () {
                  setState(() {
                    chapterExpanded[chapter] = !expanded;
                  });
                },
              ),
              if (expanded)
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Column(
                    children: entry.value.map((formulaEntry) {
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onLongPress: () {},
                          splashColor: Colors.redAccent.withOpacity(0.3),
                          highlightColor: Colors.red.withOpacity(0.1),
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.redAccent.withOpacity(0.6),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ---------------- IMAGE / 3D / RIVE RENDERING ----------------
                                if (formulaEntry['image'] != null && formulaEntry['image'].toString().isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.only(bottom: screenWidth * 0.02),
                                    child: Center(
                                      child: SizedBox(
                                        width: formulaEntry['image'].endsWith('.glb')
                                            ? screenWidth * 0.6
                                            : formulaEntry['image'].endsWith('.riv')
                                            ? screenWidth * 0.65
                                            : screenWidth * 0.6,
                                        height: formulaEntry['image'].endsWith('.glb')
                                            ? screenWidth * 0.6
                                            : formulaEntry['image'].endsWith('.riv')
                                            ? (screenWidth * 0.65) / 1.5
                                            : (screenWidth * 0.6) / 1.5,
                                        child: formulaEntry['image'].endsWith('.svg')
                                            ? Opacity(
                                          opacity: 0.85,
                                          child: SvgPicture.asset(
                                            formulaEntry['image'],
                                            fit: BoxFit.contain,
                                            placeholderBuilder: (context) => const SizedBox.shrink(),
                                          ),
                                        )
                                            : formulaEntry['image'].endsWith('.glb')
                                            ? Formula3DViewer(
                                          src: formulaEntry['image'],
                                          index: formulaEntry.hashCode,
                                          themeColor: Colors.redAccent,
                                          isActive: _active3DIndices.contains(formulaEntry['image']),
                                          onActivate: () => _activate3DModel(formulaEntry['image']),
                                          onDeactivate: () => _deactivate3DModel(formulaEntry['image']),
                                        )
                                            : formulaEntry['image'].endsWith('.riv')
                                            ? Opacity(
                                          opacity: 0.8,
                                          child: FormulaRiveViewer(
                                            key: ValueKey(formulaEntry['image']),
                                            src: formulaEntry['image'],
                                          ),
                                        )
                                            : Image.asset(
                                          formulaEntry['image'],
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) => const Text(
                                            'Image not found',
                                            style: TextStyle(color: Colors.redAccent),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                // ---------------- RESTORED QUESTION TEXT (HTML) ----------------
                                Html(
                                  data: 'Q: ${formulaEntry['formula']}',
                                  style: {
                                    "body": Style(
                                      fontSize: FontSize(screenWidth * 0.037),
                                      color: const Color(0xFFDCDCDC),
                                      fontFamily: GoogleFonts.poppins().fontFamily,
                                      margin: Margins.zero,
                                    ),
                                  },
                                ),
                                SizedBox(height: screenWidth * 0.016),

                                // ---------------- RESTORED ANSWER TEXT (Math.tex) ----------------
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Math.tex(
                                    'Ans: ${formulaEntry['answer']}',
                                    textStyle: TextStyle(fontSize: screenWidth * 0.043, color: Colors.greenAccent),
                                  ),
                                ),

                                // ---------------- RESTORED TIP TEXT ----------------
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (formulaEntry['tip'] != null && formulaEntry['tip'].toString().isNotEmpty) ...[
                                      SizedBox(height: screenWidth * 0.05), // Spacing before tip
                                      Text(
                                        'Tip:',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFFF8A46F),
                                          fontSize: screenWidth * 0.045,
                                          fontWeight: FontWeight.w600,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                      SizedBox(height: screenWidth * 0.01),
                                      Text(
                                        formulaEntry['tip'].toString(),
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFFF8A46F),
                                          fontSize: screenWidth * 0.039,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              const Divider(), // Added Divider between chapters as per original code
            ],
          );
        }).toList(),
      ],
    );
  }}

// -------------------- HELPER CLASS FOR 3D -----------------
class Formula3DViewer extends StatefulWidget {
  final String src;
  final int index;
  final Color themeColor;
  final bool isActive;
  final VoidCallback onActivate;
  final VoidCallback onDeactivate;

  const Formula3DViewer({
    Key? key,
    required this.src,
    required this.index,
    required this.themeColor,
    required this.isActive,
    required this.onActivate,
    required this.onDeactivate,
  }) : super(key: key);

  @override
  State<Formula3DViewer> createState() => _Formula3DViewerState();
}

class _Formula3DViewerState extends State<Formula3DViewer> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => widget.isActive;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.isActive) {
      return ModelViewer(
        key: ValueKey("${widget.src}_active"),
        src: widget.src,
        backgroundColor: Colors.transparent,
        alt: "A 3D model",
        ar: false,
        autoRotate: true,
        disableZoom: false,
        disablePan: true,
        cameraControls: true,
        interactionPrompt: InteractionPrompt.none,
        shadowIntensity: 0,
        autoPlay: true,
      );
    }

    return GestureDetector(
      onTap: widget.onActivate,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.threed_rotation_outlined,
              color: widget.themeColor,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              "Tap to view 3D",
              style: TextStyle(
                color: widget.themeColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}