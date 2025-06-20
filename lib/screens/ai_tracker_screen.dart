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

    print('Loaded ${all.length} mistakes from local.');

    Map<String, List<Map<String, dynamic>>> tempChapterMistakes = {};
    Map<String, int> tempChapterTotals = {};

    for (var q in all) {
      String chapter = 'My Mistakes';

      tempChapterMistakes.putIfAbsent(chapter, () => []);
      tempChapterMistakes[chapter]!.add({
        'formula': q['question'],
        'mistakeCount': 1, // since each mistake is one occurrence
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
          if (totalActiveMistakes >= 5)
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
                      title: Text("✅ $resolvedCount mistakes resolved 🎉"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("OK"),
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
                    '$chapter — $totalMistakes mistakes',
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

                        return ListTile(
                          title: Row(
                            children: [




                              Expanded(
                                child: Math.tex(
                                  formula,
                                  textStyle: const TextStyle(fontSize: 18, color: Colors.white),
                                ),
                              ),
                              Text(
                                ' (${count == 1 ? '1 time' : '$count times'})',
                                style: const TextStyle(fontSize: 16, color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                const Divider(),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}
