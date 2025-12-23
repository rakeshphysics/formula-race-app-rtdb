// -------------------------------------------------------------
// AITrackerScreen.dart
// -------------------------------------------------------------
// Screen to show user mistakes → per chapter → dropdown list.
// Data comes from users/{userId}/weak_areas → MistakeTrackerService.
// Chapters sorted by total mistakes.
// -------------------------------------------------------------

// -------------------- CHUNK 1 — IMPORT -----------------------
//import 'solo_screen.dart';
import 'package:flutter/material.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'clear_mistakes_screen.dart'; // instead of solo_screen.dart
import '../../services/mistake_tracker_service.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_svg/flutter_svg.dart';

//.......START.......Render chapter names Correctly......................
// String formatChapter(String input) {
//   return input
//       .split('_')
//       .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
//       .join(' ');
// }

String formatChapter(String input) {
  // Define a map for specific acronyms or multi-word exceptions.
  final Map<String, String> specialCases = {
    'shm': 'SHM',
    'emi': 'EMI',
    'em_waves': 'EM Waves',
    'ac': 'AC',
    'xrays':'X Rays'
  };

  // Convert the input to a consistent format (lowercase with underscores) for the lookup.
  final formattedInput = input.toLowerCase().replaceAll(' ', '_');

  // Check if the formatted input is a special case.
  if (specialCases.containsKey(formattedInput)) {
    return specialCases[formattedInput]!;
  }

  // If not a special case, format the string by capitalizing each word and joining with a space.
  return input
      .split('_')
      .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
      .join(' ');
}
//.......END.......Render chapter names Correctly...........................

// -------------------- CHUNK 2 — CLASS HEADER -----------------
class AITrackerScreen extends StatefulWidget {
  final String userId; // Pass current userId

  const AITrackerScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<AITrackerScreen> createState() => _AITrackerScreenState();
}

// -------------------- CHUNK 3 — STATE CLASS -----------------
class _AITrackerScreenState extends State<AITrackerScreen> {
  Map<String, List<Map<String, dynamic>>> chapterMistakes = {};
  Map<String, int> chapterTotals = {};
  Map<String, bool> chapterExpanded = {}; // for dropdown state
  bool isLoading = true;
 late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _loadMistakes();
  }


  @override
  void dispose() {
    // _confettiControllerSmall.dispose();
    // _confettiControllerLarge.dispose(); // ADD THIS LINE
    _confettiController.dispose();
    super.dispose();
  }

  // ... rest of the class

  // -------------------- CHUNK 4 — LOAD MISTAKES -----------------
  Future<void> _loadMistakes() async {
    List<Map<String, dynamic>> all = await MistakeTrackerService.loadMistakesFromLocal();

   // print('Loaded ${all.length} mistakes from local.');

    Map<String, List<Map<String, dynamic>>> tempChapterMistakes = {};
    Map<String, int> tempChapterTotals = {};

    for (var q in all) {
     // String chapter = q['tags']?['chapter'] ?? 'Unknown';
      String chapter = (q['tags']?['chapter'] ?? q['chapter'] ?? 'Unknown').toString();

      tempChapterMistakes.putIfAbsent(chapter, () => []);
      tempChapterMistakes[chapter]!.add({
        'formula': q['question'],
        'answer': q['answer'],       // ✅ load the answer
        'image': q['image'],         // ✅ load the image
        'mistakeCount': 1,
        'tip': q['tip'],
      });


      tempChapterTotals[chapter] = (tempChapterTotals[chapter] ?? 0) + 1;
    }

    // Sort chapters by total mistakes descending
    List<MapEntry<String, int>> sortedChapters = tempChapterTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    Map<String, List<Map<String, dynamic>>> finalChapterMistakes = {};
    Map<String, int> finalChapterTotals = {};
    Map<String, bool> expandedState = {};

    for (var entry in sortedChapters) {
      String chapter = entry.key;
      finalChapterMistakes[chapter] = tempChapterMistakes[chapter]!;
      finalChapterTotals[chapter] = entry.value;
      expandedState[chapter] = false; // collapsed
    }

    setState(() {
      chapterMistakes = finalChapterMistakes;
      chapterTotals = finalChapterTotals;
      chapterExpanded = expandedState;
      isLoading = false;
    });
  }


  // -------------------- CHUNK 5 — BUILD FUNCTION -----------------
  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    // Calculate total active mistakes
    int totalActiveMistakes = chapterMistakes.entries.fold(0, (sum, entry) {
      return sum + entry.value.fold(0, (chapterSum, formulaEntry) {
        return chapterSum + (formulaEntry['mistakeCount'] as int);
      });
    });


    return Stack(
   alignment: Alignment.topCenter,
    children:[
    Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title:  Text('My Mistakes', style: TextStyle(fontSize:screenWidth*0.04,color: Colors.black)),
        iconTheme: const IconThemeData(color: Color(0xD9FFFFFF)),
        actions: [
          if (totalActiveMistakes >= 1)

        Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
           child: OutlinedButton(
              onPressed: () async {
                final resolvedCount = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ClearMistakesScreen(),
                  ),
                );

                if (resolvedCount != null && resolvedCount > 0) {

                  // if (resolvedCount < 5) {
                  //   _confettiControllerSmall.play(); // Play the small animation
                  // } else {
                  //   _confettiControllerLarge.play(); // Play the large animation
                  // }

                  _confettiController.play();

                  showDialog(
                    context: context,
                    builder: (_) => Stack(
                            alignment: Alignment.topCenter,
                            children: [
                        AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                        side: BorderSide(color: Colors.red, width: 0.8),
                      ),
                      backgroundColor: Color(0xFF000000),
                      title: Text(
                        resolvedCount == 1 // MODIFIED THIS LINE
                            ? "1 Mistake Resolved  🎉"
                            : "$resolvedCount Mistakes Resolved  🎉",
                        style: TextStyle(color: Color(0xD9FFFFFF), fontSize:screenWidth*0.044), // Ensure text color is visible
                        textAlign: TextAlign.center, // Center the text
                      ),
                      //content: SizedBox(height: screenWidth*0.02),
                      actions: [
                        Row(
                        mainAxisAlignment: MainAxisAlignment.center, // Center the content of the Row
                        children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: const Color(0xD9FF0000), width: 0.8), // Made border thinner (was 1.5)
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                          child:  Text(
                            "OK",
                            style: TextStyle(
                              color: Color(0xD9FFFFFF),
                              fontSize: screenWidth*0.04,
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
                                colors: const [
                                  Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple
                                ],
                              ),],),
                  );
                  // Optional: reload mistakes from Firebase
                  _loadMistakes();
                }
              },

              style: OutlinedButton.styleFrom(
                // Border color and width are controlled by the 'side' property.
                side: BorderSide(
                  color: Colors.redAccent, // Change the border color here
                  width: 1.2,              // Change the border thickness here
                ),
                // Border radius and shape are controlled by the 'shape' property.
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4), // Change the corner radius here
                ),
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.015),
              ),

              child: Text(
                'Clear Mistakes',
                style: TextStyle(fontSize:screenWidth*0.04,color: Colors.redAccent),
              ),
            ),
        ),

        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : chapterMistakes.isEmpty
          ? const Center(
        child: Text(
          'No mistakes to show.',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal, color: Color(0xD9FFFFFF)),
        ),
      )
          : ListView(
        padding:  EdgeInsets.all(screenWidth*0.03),
        children: [




          // ---------- TOTAL ACTIVE MISTAKES → NEW PART ----------
          Padding(
            padding:  EdgeInsets.symmetric(vertical: screenHeight*0.01),
            child: Text(
              'Total active Mistakes: $totalActiveMistakes',
              style:TextStyle(fontSize: screenWidth*0.043, color: Color(0xD9FFFFFF), fontWeight: FontWeight.w500),
            ),
          ),
          // -----------------------------------------------------

          // ---------- EXISTING CHAPTER LIST ----------
          ...chapterMistakes.entries.map((entry) {
            String chapter = entry.key;
            int totalMistakes = chapterTotals[chapter]!;
            bool expanded = chapterExpanded[chapter]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [



                ListTile(
                  title: Text(
                    '${formatChapter(chapter)} — $totalMistakes',
                    style:  TextStyle(fontWeight: FontWeight.normal, fontSize: screenWidth*0.041),
                  ),
                  trailing: Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
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
                        String formula = formulaEntry['formula'];
                        int count = formulaEntry['mistakeCount'];

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onLongPress: () {
                              // Optional: do something on long press (like show full solution)
                            },
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
                                  // if (formulaEntry['image'] != null && formulaEntry['image'].toString().isNotEmpty)
                                  //   Padding(
                                  //         padding:  EdgeInsets.only(bottom: screenWidth * 0.02),
                                  //         child: Center(
                                  //           child: SizedBox(
                                  //             width: screenWidth * 0.6,
                                  //             height: (screenWidth * 0.6) / 1.5,
                                  //         child: Image.asset(
                                  //        formulaEntry['image'],
                                  //         fit: BoxFit.contain,
                                  //          errorBuilder: (context, error, stackTrace) => const Text(
                                  //         'Image not found',
                                  //         style: TextStyle(color: Colors.redAccent),
                                  //       ),
                                  //     ),),),
                                  //   ),

                                  // if (formulaEntry['image'] != null && formulaEntry['image'].toString().isNotEmpty)
                                  //   Padding(
                                  //     padding: EdgeInsets.only(bottom: screenWidth * 0.02),
                                  //     child: Center(
                                  //       child: SizedBox(
                                  //         width: screenWidth * 0.6,
                                  //         height: (screenWidth * 0.6) / 1.5, // Maintain the same aspect ratio
                                  //         child: SvgPicture.asset(
                                  //           formulaEntry['image'], // This path now correctly points to a .svg
                                  //           fit: BoxFit.contain,
                                  //         ),
                                  //       ),
                                  //     ),
                                  //   ),

                                  // ... inside the Column's children array in the _buildFormulaCard method

                                  if (formulaEntry['image'] != null && formulaEntry['image'].toString().isNotEmpty)
                                    Padding(
                                      padding: EdgeInsets.only(bottom: screenWidth * 0.02),
                                      child: Center(
                                        child: SizedBox(
                                          width: screenWidth * 0.6,
                                          height: (screenWidth * 0.6) / 1.5,
                                          child: formulaEntry['image'].endsWith('.svg')
                                              ? SvgPicture.asset(
                                            formulaEntry['image'],
                                            fit: BoxFit.contain,
                                            placeholderBuilder: (context) => const SizedBox.shrink(), // Optional: handle loading/errors
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

// ... rest of the widgets in the Column


                                  Html(
                                    data: 'Q: ${formulaEntry['formula']}',
                                    style: {
                                      "body": Style(
                                        fontSize: FontSize(screenWidth * 0.037),
                                        color: Color(0xFFDCDCDC),
                                        fontFamily: GoogleFonts.poppins().fontFamily,
                                        margin: Margins.zero,
                                      ),
                                    },
                                  ),
                                  SizedBox(height: screenWidth * 0.016),

                        SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                                  child:Math.tex(
                                    'Ans: ${formulaEntry['answer']}',
                                    textStyle:  TextStyle(fontSize: screenWidth * 0.043, color: Colors.greenAccent),
                                  ),
                        ),

                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (formulaEntry['tip'] != null && formulaEntry['tip'].toString().isNotEmpty) ...[
                                        SizedBox(height: screenWidth*0.05), // Spacing before tip
                                        Text( // 'Tip:' label
                                          'Tip:',
                                          style: GoogleFonts.poppins(
                                            color: Color(0xFFF8A46F),
                                            fontSize:screenWidth * 0.045,
                                            fontWeight: FontWeight.w600,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                        SizedBox(height: screenWidth*0.01),
                                        Text( // Actual tip content
                                          formulaEntry['tip'].toString(), // Ensure it's a string
                                          style: GoogleFonts.poppins(
                                            color: Color(0xFFF8A46F),
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
                const Divider(),
              ],
            );
          }).toList(),
          ////...........TEMPORARY......START..........BUTTON TO DEL MISTAKES JSON FILE .............................
          //  Padding(
          //    padding: const EdgeInsets.only(top: 20.0, bottom: 40.0),
          //    child: Center(
          //      child: ElevatedButton(
          //        onPressed: () => deleteMistakeTrackerJson(context),
          //        child: Text('CLEAR MISTAKES'),
          //     ),
          //    ),
          //  ),
////...........TEMPORARY......END..........BUTTON TO DEL MISTAKES JSON FILE .........

        ],
      ),
    ),

    //   ConfettiWidget(
    //     confettiController: _confettiControllerSmall,
    // blastDirectionality: BlastDirectionality.explosive,
    // shouldLoop: false,
    // numberOfParticles: 15, // Fewer particles
    // emissionFrequency: 0.03,
    // gravity: 0.2,
    // colors: const [Colors.green, Colors.blue, Colors.pink],
    // ),
    //
    // // ADD another ConfettiWidget for the LARGE blast
    // ConfettiWidget(
    // confettiController: _confettiControllerLarge,
    // blastDirectionality: BlastDirectionality.explosive,
    // shouldLoop: false,
    // numberOfParticles: 60, // More particles
    // emissionFrequency: 0.01,
    // gravity: 0.3,
    // colors: const [Colors.orange, Colors.purple, Colors.yellow, Colors.red],
    // ),
    ],
    );
  }
}

//...........TEMPORARY......START...........FUNCTION TO DEL MISTAKES JSON FILE .................................
// Future<void> deleteMistakeTrackerJson(BuildContext context) async {
//   final dir = await getApplicationDocumentsDirectory();
//   final file = File('${dir.path}/my_mistakes.json');
//
//   if (await file.exists()) {
//     await file.delete();
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Mistake tracker cleared')),
//     );
//   } else {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('No mistake file found')),
//     );
//   }
//
//   // ✅ Reload the screen with empty mistakes
//   if (context.mounted) {
//     final state = context.findAncestorStateOfType<_AITrackerScreenState>();
//     state?._loadMistakes();
//   }
// }

//...........TEMPORARY.......END...........FUNCTION TO DEL MISTAKES JSON FILE .................................