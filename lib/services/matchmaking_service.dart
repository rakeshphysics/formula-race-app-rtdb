import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class MatchmakingService {
  static Future<Map<String, dynamic>?> createMatch(String userId) async {
    final seed = Random().nextInt(1000000);
    final matchRef = FirebaseFirestore.instance.collection('matches').doc();
    final matchId = matchRef.id;

    await matchRef.set({
      'matchId': matchId,
      'seed': seed,
      'player1Id': userId,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
      'player1Ready': false, // Initialize ready states
      'player2Ready': false,
    });

    await FirebaseDatabase.instance.ref('matches/$matchId').set({
      'player1Id': userId,
      'player2Id': null,
    });

    return {
      'matchId': matchId,
      'seed': seed,
    };
  }

  // REVISED: Non-transactional findMatch (for Random Matchmaking)
  static Future<Map<String, dynamic>?> findMatch(String userId) async {
    final dbRef = FirebaseDatabase.instance.ref('matches');

    try {
      final snapshot = await dbRef.get();

      if (!snapshot.exists || snapshot.value == null) {
        return null; // No matches found
      }

      final matches = Map<String, dynamic>.from(snapshot.value as Map);

      // Iterate through existing matches to find an open one
      for (final entry in matches.entries) {
        final data = Map<String, dynamic>.from(entry.value);
        if (data['player2Id'] == null && data['player1Id'] != userId) {
          final matchId = entry.key;

          // Attempt to claim this match
          // WARNING: This update is not atomic. A race condition could still occur here
          // if two players try to claim the same match simultaneously.
          await dbRef.child(matchId).update({
            'player2Id': userId,
          });

          // After attempting to update, re-read to confirm it was successful
          final updatedSnapshot = await dbRef.child(matchId).get();
          final updatedData = Map<String, dynamic>.from(updatedSnapshot.value as Map);

          if (updatedData['player2Id'] == userId) { // Confirmed we claimed it
            final doc = await FirebaseFirestore.instance.collection('matches').doc(matchId).get();
            final seed = doc.data()?['seed'];

            if (seed != null) {
              return {
                'matchId': matchId,
                'seed': seed,
              };
            }
          }
        }
      }
    } catch (e) {
      print("Error finding match: $e");
    }

    return null; // No open match found or successfully joined
  }
}