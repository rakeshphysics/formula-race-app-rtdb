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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'clear_mistakes_screen.dart'; // instead of solo_screen.dart
import '../../services/mistake_tracker_service.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

//.......START.......Render chapter names Correctly......................
String formatChapter(String input) {
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

  @override
  void initState() {
    super.initState();
    _loadMistakes();
  }

  // -------------------- CHUNK 4 — LOAD MISTAKES -----------------
  Future<void> _loadMistakes() async {
    List<Map<String, dynamic>> all = await MistakeTrackerService.loadMistakesFromLocal();

   // print('Loaded ${all.length} mistakes from local.');

    Map<String, List<Map<String, dynamic>>> tempChapterMistakes = {};
    Map<String, int> tempChapterTotals = {};

    for (var q in all) {
      String chapter = q['tags']?['chapter'] ?? 'Unknown';

      tempChapterMistakes.putIfAbsent(chapter, () => []);
      tempChapterMistakes[chapter]!.add({
        'formula': q['question'],
        'answer': q['answer'],       // ✅ load the answer
        'image': q['image'],         // ✅ load the image
        'mistakeCount': 1,
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
    // Calculate total active mistakes
    int totalActiveMistakes = chapterMistakes.entries.fold(0, (sum, entry) {
      return sum + entry.value.fold(0, (chapterSum, formulaEntry) {
        return chapterSum + (formulaEntry['mistakeCount'] as int);
      });
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('My Mistakes', style: TextStyle(fontSize:20,color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (totalActiveMistakes >= 1)
            TextButton(
              onPressed: () async {
                final resolvedCount = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ClearMistakesScreen(),
                  ),
                );

                if (resolvedCount != null && resolvedCount > 0) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                        side: BorderSide(color: Colors.red, width: 0.8),
                      ),
                      backgroundColor: Color(0xFF000000),
                      title: Text(" $resolvedCount Mistakes Resolved 🎉"),
                      content: const SizedBox(height: 10.0),
                      actions: [
                        Row(
                        mainAxisAlignment: MainAxisAlignment.center, // Center the content of the Row
                        children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.red, width: 0.8), // Made border thinner (was 1.5)
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                          child: const Text(
                            "OK",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20.0,
                            ),
                          ),
                        ),
                         ],
                        ),
                      ],
                    ),
                  );
                  // Optional: reload mistakes from Firebase
                  _loadMistakes();
                }
              },

              child: const Text(
                'Clear Mistakes',
                style: TextStyle(fontSize:20,color: Colors.redAccent),
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
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal, color: Colors.white),
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16.0),
        children: [




          // ---------- TOTAL ACTIVE MISTAKES → NEW PART ----------
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Total active mistakes: $totalActiveMistakes',
              style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
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
                    style: const TextStyle(fontWeight: FontWeight.normal),
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
                                  if (formulaEntry['image'] != null && formulaEntry['image'].toString().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Image.asset(
                                        formulaEntry['image'],
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) => const Text(
                                          'Image not found',
                                          style: TextStyle(color: Colors.redAccent),
                                        ),
                                      ),
                                    ),
                                  Html(
                                    data: 'Qn: ${formulaEntry['formula']}',
                                    style: {
                                      "body": Style(
                                        fontSize: FontSize(16),
                                        color: Colors.white,
                                        fontFamily: GoogleFonts.poppins().fontFamily,
                                        margin: Margins.zero,
                                      ),
                                    },
                                  ),
                                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),

                                  Math.tex(
                                    'Ans: ${formulaEntry['answer']}',
                                    textStyle: const TextStyle(fontSize: 16, color: Colors.greenAccent),
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
          //Padding(
            //padding: const EdgeInsets.only(top: 20.0, bottom: 40.0),
            //child: Center(
              //child: ElevatedButton(
                //onPressed: () => deleteMistakeTrackerJson(context),
                //child: Text('CLEAR MISTAKES'),
              //),
            //),
          //),
////...........TEMPORARY......END..........BUTTON TO DEL MISTAKES JSON FILE .........

        ],
      ),
    );
  }
}

//...........TEMPORARY......START...........FUNCTION TO DEL MISTAKES JSON FILE .................................
Future<void> deleteMistakeTrackerJson(BuildContext context) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/my_mistakes.json');

  if (await file.exists()) {
    await file.delete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mistake tracker cleared')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No mistake file found')),
    );
  }

  // ✅ Reload the screen with empty mistakes
  if (context.mounted) {
    final state = context.findAncestorStateOfType<_AITrackerScreenState>();
    state?._loadMistakes();
  }
}

//...........TEMPORARY.......END...........FUNCTION TO DEL MISTAKES JSON FILE .................................