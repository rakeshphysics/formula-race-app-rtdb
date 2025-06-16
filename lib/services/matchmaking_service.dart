import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';

class MatchmakingService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final String _playerId = const Uuid().v4();
  String? _currentMatchId;

  String get playerId => _playerId;

  Future<String?> findMatch() async {
    print('[$_playerId] Starting matchmaking...');

    DatabaseReference matchesRef = _database.child('matches');
    DataSnapshot snapshot = await matchesRef.get();

    String? joinedMatchId;

    for (var matchEntry in snapshot.children) {
      Map<dynamic, dynamic>? matchData = matchEntry.value as Map<dynamic, dynamic>?;

      if (matchData != null &&
          matchData['player2Id'] == null &&
          matchData['player1Id'] != _playerId) {
        joinedMatchId = matchEntry.key;
        print('[$_playerId] Found open match: $joinedMatchId → joining');

        await matchesRef.child(joinedMatchId!).update({
          'player2Id': _playerId,
          'timestamp': ServerValue.timestamp,
        });

        await matchesRef.child(joinedMatchId).child('scores').update({
          _playerId: 0,
        });

        break;
      }
    }

    if (joinedMatchId != null) {
      _currentMatchId = joinedMatchId;
      return await _waitForMatch(joinedMatchId);
    } else {
      DatabaseReference newMatchRef = matchesRef.push();

      List<Map<String, dynamic>> questions = await _generateQuestions();

      await newMatchRef.set({
        'player1Id': _playerId,
        'player2Id': null,
        'timestamp': ServerValue.timestamp,
        'status': 'waiting',
        'questions': questions,
        'scores': {
          _playerId: 0,
        },
        'currentQuestionIndex': 0,
      });

      print('[$_playerId] Created new match: ${newMatchRef.key} → waiting');
      _currentMatchId = newMatchRef.key;

      return await _waitForMatch(newMatchRef.key!);
    }
  }

  Future<String?> _waitForMatch(String matchId) async {
    Completer<String?> completer = Completer<String?>();

    DatabaseReference matchRef = _database.child('matches/$matchId');
    late DatabaseReference player2Ref = matchRef.child('player2Id');

    StreamSubscription<DatabaseEvent>? subscription;

    subscription = player2Ref.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        print('[$_playerId] Match $matchId ready → player2Id: ${event.snapshot.value}');
        subscription?.cancel();
        completer.complete(matchId);
      }
    });

    Future.delayed(const Duration(seconds: 30), () async {
      if (!completer.isCompleted) {
        print('[$_playerId] Matchmaking timeout → canceling match $matchId');
        subscription?.cancel();
        await cancelMatch(matchId);
        completer.complete(null);
      }
    });

    return completer.future;
  }

  Future<void> cancelMatch(String matchId) async {
    print('[$_playerId] Deleting match $matchId');
    await _database.child('matches/$matchId').remove();
    if (_currentMatchId == matchId) {
      _currentMatchId = null;
    }
  }

  Future<void> cancelCurrentMatch() async {
    if (_currentMatchId != null) {
      await cancelMatch(_currentMatchId!);
    }
  }

  Future<List<Map<String, dynamic>>> _generateQuestions() async {
    return [
      {
        'questionText': 'Correct formula for Ohm\'s Law is:',
        'options': ['V = IR', 'V = IR²', 'I = VR', 'R = VI'],
        'correctAnswer': 'V = IR',
      },
      {
        'questionText': 'Correct formula for Newton\'s 2nd law:',
        'options': ['F = ma', 'F = mv', 'a = F/m', 'F = m + a'],
        'correctAnswer': 'F = ma',
      },
      {
        'questionText': 'Correct formula for Kinetic Energy:',
        'options': ['KE = 1/2 mv²', 'KE = mv²', 'KE = 1/2 m²v', 'KE = mv'],
        'correctAnswer': 'KE = 1/2 mv²',
      },
      {
        'questionText': 'Correct formula for Power:',
        'options': ['P = VI', 'P = V/I', 'P = I²V', 'P = VR'],
        'correctAnswer': 'P = VI',
      },
      {
        'questionText': 'Correct formula for Work Done:',
        'options': ['W = Fd', 'W = F/d', 'W = F + d', 'W = d/F'],
        'correctAnswer': 'W = Fd',
      },
    ];
  }
}
