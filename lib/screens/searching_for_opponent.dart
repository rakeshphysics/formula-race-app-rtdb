import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:formula_race_app/services/matchmaking_service.dart';
import 'online_game_screen.dart';


class SearchingForOpponent extends StatefulWidget {
  final String userId;
  const SearchingForOpponent({super.key, required this.userId});

  @override
  State<SearchingForOpponent> createState() => _SearchingForOpponentState();
}

class _SearchingForOpponentState extends State<SearchingForOpponent> {
  String statusText = "Searching for opponent...";
  String? matchId;
  int? seed;
  bool isPlayer1 = false;
  bool opponentFound = false;
  bool startPressed = false;
  Timer? timeoutTimer;
  StreamSubscription<DatabaseEvent>? dbListener;
  StreamSubscription<DocumentSnapshot>? readyListener;

  bool matchStarted = false;

  @override
  void initState() {
    super.initState();

    if (!matchStarted) {
      print("🚀 handleMatchmaking() called");
      matchStarted = true;
      handleMatchmaking();
    } else {
      print("⚠️ Skipping duplicate matchmaking");
    }
  }


  Future<void> handleMatchmaking() async {
    final matchData = await MatchmakingService.findMatch(widget.userId);

    if (matchData != null) {
      // Player 2 flow
      matchId = matchData['matchId'];
      seed = matchData['seed'];
      isPlayer1 = false;
      opponentFound = true;
      setState(() {
        statusText = "Match Found!";
      });
      listenForBothReady();
    } else {
      // Player 1 flow
      final created = await MatchmakingService.createMatch(widget.userId);
      if (created != null) {
        matchId = created['matchId'];
        seed = created['seed'];
        isPlayer1 = true;
        listenForPlayer2();
      }
    }
  }



  void listenForPlayer2() {
    final ref = FirebaseDatabase.instance.ref('matches/$matchId/player2Id');
    dbListener = ref.onValue.listen((event) {
      final val = event.snapshot.value;
      if (val != null && val.toString().isNotEmpty) {
        setState(() {
          statusText = "Match Found!";
          opponentFound = true;
        });
        listenForBothReady();
      }
    });
  }

  void listenForBothReady() {
    final docRef = FirebaseFirestore.instance.collection('matches').doc(matchId);
    readyListener = docRef.snapshots().listen((doc) {
      final data = doc.data();
      if (data == null) return;
      final p1Ready = data['player1Ready'] == true;
      final p2Ready = data['player2Ready'] == true;

      if (p1Ready && p2Ready) {
        readyListener?.cancel();
        dbListener?.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OnlineGameScreen(
              matchId: matchId!,
              seed: seed!,
              isPlayer1: isPlayer1,
              playerId: widget.userId,
            ),
          ),
        );
      }
    });
  }

  Future<void> markReady() async {
    final docRef = FirebaseFirestore.instance.collection('matches').doc(matchId);
    await docRef.update({
      isPlayer1 ? 'player1Ready' : 'player2Ready': true,
    });
    setState(() {
      startPressed = true;
      statusText = "Waiting for opponent to start...";
    });
  }

  @override
  void dispose() {
    dbListener?.cancel();
    readyListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 20),
            Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 30),
            if (opponentFound && !startPressed)
              ElevatedButton(
                onPressed: markReady,
                child: const Text("Start Game"),
              ),
          ],
        ),
      ),
    );
  }
}
