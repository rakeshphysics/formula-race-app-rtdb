// -------------------------------------------------------------
// FormulaLoader.dart
// -------------------------------------------------------------
// Service to select formulas for Solo Play and Online Play.
// Solo Play: smart selection with mistakes + unseen formulas.
// Online Play: pure random selection.
// Uses MistakeTrackerService + SessionTrackerService.
// -------------------------------------------------------------

// -------------------- CHUNK 1 — IMPORT -----------------------
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'mistake_tracker_service.dart';
import 'session_tracker_service.dart';

// -------------------- CHUNK 2 — CLASS HEADER -----------------
class FormulaLoader {
  static final _firestore = FirebaseFirestore.instance;

  // -------------------- CHUNK 3 — SELECT SOLO GAME -----------------
  // Select formulas for Solo game.
  // Combines weak formulas + new formulas + handles cycle reset.
  static Future<List<dynamic>> selectFormulasForSoloGame({
    required String userId,
    required String chapterName,
    required String jsonPath,
    required int count,
  }) async {
    // Load full formulas from assets.
    String jsonString = await rootBundle.loadString(jsonPath);
    final List<dynamic> allFormulas = json.decode(jsonString);

    // Load session seen formulas.
    List<String> seenFormulas = await SessionTrackerService.getSessionSeenFormulas(
      userId: userId,
      chapter: chapterName,
    );

    // Load weak formulas (from AI Tracker).
    List<Map<String, dynamic>> weakFormulas = await _getWeakFormulas(userId, chapterName);

    // Decide how many weak formulas to use (30-50%)
    int numWeak = min((count * 0.5).round(), weakFormulas.length);

    // Select weak formulas first.
    List<Map<String, dynamic>> selectedWeak = weakFormulas.take(numWeak).toList();

    // Remaining formulas → select from unseen formulas.
    List<dynamic> unseenFormulas = allFormulas.where((q) {
      String formulaId = _generateFormulaId(q);
      return !seenFormulas.contains(formulaId);
    }).toList();

    int remainingCount = count - selectedWeak.length;
    List<dynamic> selectedNew = [];

    if (unseenFormulas.length >= remainingCount) {
      unseenFormulas.shuffle();
      selectedNew = unseenFormulas.take(remainingCount).toList();
    } else {
      // Not enough new formulas → take all unseen, then reset cycle.
      selectedNew = unseenFormulas;
      await SessionTrackerService.resetSessionSeenFormulas(userId, chapterName);

      // Now select remaining from full formulas (reshuffled).
      allFormulas.shuffle();
      int stillNeeded = remainingCount - selectedNew.length;
      selectedNew.addAll(allFormulas.take(stillNeeded));
    }

    // Update session seen formulas.
    List<String> newSeen = [
      ...seenFormulas,
      ...selectedNew.map((q) => _generateFormulaId(q))
    ];
    await SessionTrackerService.updateSessionSeenFormulas(
      userId: userId,
      chapter: chapterName,
      newSeenFormulas: newSeen,
    );

    // Combine and return.
    return [
      ...selectedWeak.map((wf) => wf['questionData']),
      ...selectedNew
    ];
  }

  // -------------------- CHUNK 4 — SELECT ONLINE GAME -----------------
  // Select formulas for Online game (pure random).
  static Future<List<dynamic>> selectFormulasForOnlineGame({
    required String chapterName,
    required String jsonPath,
    required int count,
  }) async {
    // Load full formulas from assets.
    String jsonString = await rootBundle.loadString(jsonPath);
    final List<dynamic> allFormulas = json.decode(jsonString);

    allFormulas.shuffle();
    return allFormulas.take(count).toList();
  }

  // -------------------- CHUNK 5 — HELPER: GET WEAK FORMULAS -----------------
  static Future<List<Map<String, dynamic>>> _getWeakFormulas(
      String userId, String chapterName) async {
    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('weak_areas')
        .where('chapter', isEqualTo: chapterName)
        .get();

    List<Map<String, dynamic>> weakFormulas = [];

    for (var doc in snapshot.docs) {
      int mistakeCount = doc['mistakeCount'] ?? 0;
      int correctCount = doc['correctCount'] ?? 0;
      int effectiveMistakeCount = mistakeCount - correctCount;

      if (effectiveMistakeCount > 0) {
        weakFormulas.add({
          'formulaId': doc.id,
          'formula': doc['formula'] ?? '',
          'mistakeCount': effectiveMistakeCount,
          'questionData': {
            'question': doc['formula'], // Use formula as question
            'options': [], // No options → you can customize if needed
            'answer': doc['formula'],
            'tags': {'chapter': chapterName}
          }
        });
      }
    }

    // Sort weak formulas → most mistakes first.
    weakFormulas.sort((a, b) => (b['mistakeCount']).compareTo(a['mistakeCount']));

    return weakFormulas;
  }

  // -------------------- CHUNK 6 — HELPER: GENERATE FORMULA ID -----------------
  static String _generateFormulaId(dynamic questionData) {
    String key = (questionData['question'] ?? '') + '|' + (questionData['answer'] ?? '');
    return key.hashCode.toString();
  }
}
