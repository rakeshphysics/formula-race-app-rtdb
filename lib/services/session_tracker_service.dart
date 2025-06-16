// -------------------------------------------------------------
// SessionTrackerService.dart
// -------------------------------------------------------------
// Service to track session_seen_formulas per user per chapter.
// Used in FormulaLoader → Solo Play.
// -------------------------------------------------------------

// -------------------- CHUNK 1 — IMPORT -----------------------
import 'package:cloud_firestore/cloud_firestore.dart';

// -------------------- CHUNK 2 — CLASS HEADER -----------------
class SessionTrackerService {
  static final _firestore = FirebaseFirestore.instance;

  // -------------------- CHUNK 3 — GET SEEN FORMULAS -----------------
  // Returns list of formulaIds already seen in this chapter.
  static Future<List<String>> getSessionSeenFormulas({
    required String userId,
    required String chapter,
  }) async {
    DocumentSnapshot snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('session_seen_formulas')
        .doc(chapter)
        .get();

    if (snapshot.exists) {
      List<dynamic> formulaIds = snapshot['formulaIds'] ?? [];
      return formulaIds.cast<String>();
    } else {
      return [];
    }
  }

  // -------------------- CHUNK 4 — UPDATE SEEN FORMULAS -----------------
  // Updates list of seen formulaIds for this chapter.
  static Future<void> updateSessionSeenFormulas({
    required String userId,
    required String chapter,
    required List<String> newSeenFormulas,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('session_seen_formulas')
        .doc(chapter)
        .set({
      'formulaIds': newSeenFormulas,
    });
  }

  // -------------------- CHUNK 5 — RESET SEEN FORMULAS -----------------
  // Clears seen formulas for this chapter (cycle reset).
  static Future<void> resetSessionSeenFormulas(String userId, String chapter) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('session_seen_formulas')
        .doc(chapter)
        .delete();
  }
}
