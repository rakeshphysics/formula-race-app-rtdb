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

  static Future<Map<String, dynamic>?> findMatch(String userId) async {
    final dbRef = FirebaseDatabase.instance.ref('matches');
    final snapshot = await dbRef.get();

    if (!snapshot.exists) return null;

    final matches = Map<String, dynamic>.from(snapshot.value as Map);

    for (final entry in matches.entries) {
      final data = Map<String, dynamic>.from(entry.value);
      if (data['player2Id'] == null) {
        final matchId = entry.key;

        await dbRef.child(matchId).update({
          'player2Id': userId,
        });

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

    return null;
  }
}
