// -------------------------------------------------------------
// MistakeTrackerService.dart
// -------------------------------------------------------------
// Service to track user mistakes and correct answers.
// Writes to Firestore:
// users/{userId}/weak_areas/{formulaId} → {
//     formula: correct formula string,
//     chapter: chapter,
//     mistakeCount: int,
//     correctCount: int,
//     lastMistakeTime: timestamp
// }
// -------------------------------------------------------------

// -------------------- CHUNK 1 — IMPORT -----------------------
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';



// -------------------- CHUNK 2 — CLASS HEADER -----------------
class MistakeTrackerService {
  static final _firestore = FirebaseFirestore.instance;

  // -------------------- CHUNK 3 — TRACK MISTAKE -----------------
  // Call this when user clicks WRONG answer.
  static Future<void> trackMistake({
    required String userId,
    required Map<String, dynamic> questionData,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/mistake_tracker.json');

     //print('Saving mistake to: ${file.path}');

      List<Map<String, dynamic>> mistakes = [];
      if (await file.exists()) {
        final content = await file.readAsString();
        mistakes = List<Map<String, dynamic>>.from(jsonDecode(content));
      }

      // Prevent duplicates by checking question
      if (!mistakes.any((m) => m['question'] == questionData['question'])) {
        mistakes.add(questionData);  // ← full formula object
        await file.writeAsString(jsonEncode(mistakes));
        //print('Mistake saved: ${jsonEncode(mistakes)}');
      }
    } catch (e) {
      //print("Error tracking mistake: $e");
    }
  }
// -------------------- CHUNK 4 — TRACK CORRECT -----------------
  // Call this when user clicks CORRECT answer.
  static Future<void> trackCorrect({
    required String userId,
    required Map<String, dynamic> questionData,
  }) async {
    String formulaId = _generateFormulaId(questionData);

    DocumentReference docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('weak_areas')
        .doc(formulaId);

    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(docRef);

      if (snapshot.exists) {
        // If formula tracked → increment correctCount
        transaction.update(docRef, {
          'correctCount': (snapshot['correctCount'] ?? 0) + 1,
        });
      }
      // If not exists → do nothing → no need to create correctCount without mistake
    });
  }

  // -------------------- CHUNK 5 — HELPER FUNCTION -----------------
  // Generates a unique formulaId by hashing question + correct answer.
  static String _generateFormulaId(Map<String, dynamic> questionData) {
    String key = (questionData['question'] ?? '') + '|' + (questionData['answer'] ?? '');
    return key.hashCode.toString();
  }


// -------------------- CHUNK 6 — GET MISTAKE QUESTIONS -----------------
  static Future<List<Map<String, dynamic>>> loadMistakesFromLocal() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/mistake_tracker.json');

      if (await file.exists()) {
        final content = await file.readAsString();
        return List<Map<String, dynamic>>.from(jsonDecode(content));
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
  //...................JUST DEBUG.............DELETE LATER.........................................................
  static Future<void> printAllMistakes() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/mistake_tracker.json');

      if (await file.exists()) {
        final content = await file.readAsString();
        print('Full mistake_tracker.json content:\n$content');
      } else {
        print('mistake_tracker.json file does not exist.');
      }
    } catch (e) {
      print('Error reading mistake_tracker.json: $e');
    }
  }
//...................JUST DEBUG.............DELETE LATER.........................................................
}
