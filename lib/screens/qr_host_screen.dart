// lib/qr_host_screen.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Make sure you added qr_flutter to pubspec.yaml
import 'package:firebase_database/firebase_database.dart'; // For listening to player2Id
import 'package:cloud_firestore/cloud_firestore.dart'; // For listening to ready states
import 'online_game_screen.dart'; // Import your game screen
import 'dart:async';

class QRHostScreen extends StatefulWidget {
  final String matchId;
  final int seed;
  final bool isPlayer1;
  final String playerId; // Host's own player ID

  const QRHostScreen({
    Key? key,
    required this.matchId,
    required this.seed,
    required this.isPlayer1,
    required this.playerId,
  }) : super(key: key);

  @override
  State<QRHostScreen> createState() => _QRHostScreenState();
}

class _QRHostScreenState extends State<QRHostScreen> {
  String status = "Waiting for opponent...";
  bool opponentFound = false;
  bool matchStarted = false;
  late StreamSubscription<DatabaseEvent> player2Listener;
  late StreamSubscription<DocumentSnapshot> readyListener;

  @override
  void initState() {
    super.initState();
    _listenForOpponent();
  }

  void _listenForOpponent() {
    // Listen to Realtime Database for player2Id
    player2Listener = FirebaseDatabase.instance
        .ref('matches/${widget.matchId}/player2Id')
        .onValue
        .listen((event) {
      final player2Id = event.snapshot.value;
      if (player2Id != null && player2Id.toString().isNotEmpty) {
        setState(() {
          opponentFound = true;
          status = "Opponent found! Waiting for them to start...";
        });
        _listenForBothReady(); // Start listening for ready states once opponent is found
      }
    });
  }

  void _listenForBothReady() {
    // Listen to Firestore for player1Ready and player2Ready
    readyListener = FirebaseFirestore.instance
        .collection('matches')
        .doc(widget.matchId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) {
        // Match was deleted by opponent or an issue, navigate back
        if (mounted) {
          Navigator.of(context).pop(); // Or navigate to HomeScreen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opponent left the match.')),
          );
        }
        return;
      }

      final data = doc.data();
      if (data == null) return;

      final p1Ready = data['player1Ready'] == true;
      final p2Ready = data['player2Ready'] == true;

      if (p1Ready && p2Ready && !matchStarted) {
        matchStarted = true; // Prevent multiple navigations
        readyListener.cancel();
        player2Listener.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OnlineGameScreen(
              matchId: widget.matchId,
              seed: widget.seed,
              isPlayer1: widget.isPlayer1,
              playerId: widget.playerId,
            ),
          ),
        );
      }
    });
  }

  Future<void> markReady() async {
    final docRef = FirebaseFirestore.instance.collection('matches').doc(widget.matchId);
    await docRef.update({'player1Ready': true});
    setState(() {
      status = "You are ready! Waiting for opponent...";
    });
  }


  @override
  void dispose() {
    player2Listener.cancel();
    readyListener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Host Match', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white), // For back arrow
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              status,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, color: Colors.white),
            ),
            const SizedBox(height: 30),
            // Display QR Code
            QrImageView(
              data: widget.matchId, // The data encoded in the QR code is the matchId
              version: QrVersions.auto,
              size: 250.0,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            const SizedBox(height: 30),
            if (opponentFound)
              ElevatedButton(
                onPressed: markReady,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.withOpacity(0.1),
                  side: const BorderSide(color: Colors.amber, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text(
                  "Start Game",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Allow host to cancel the match if no one joined or if they change mind
                await FirebaseDatabase.instance.ref('matches/${widget.matchId}').remove();
                if (mounted) Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.1),
                side: const BorderSide(color: Colors.red, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: const Text(
                "Cancel Match",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}