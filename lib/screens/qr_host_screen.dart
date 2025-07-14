// lib/qr_host_screen.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Make sure you added qr_flutter to pubspec.yaml
import 'package:firebase_database/firebase_database.dart'; // For listening to player2Id
//import 'package:cloud_firestore/cloud_firestore.dart'; // For listening to ready states
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
  late StreamSubscription<DatabaseEvent> matchStatusListener;
 // late StreamSubscription<DatabaseEvent> player2Listener;
 // late StreamSubscription<DocumentSnapshot> readyListener;

  @override
  void initState() {
    super.initState();
    _listenForMatchStatus();
  }


  Future<void> markReady() async {
    // Update player1Ready in Realtime Database
    await FirebaseDatabase.instance
        .ref('matches/${widget.matchId}')
        .update({'player1Ready': true});
    setState(() {
      // startPressed is likely removed, so status is the main update
      status = "You are ready! Waiting for opponent...";
    });
  }


  void _listenForMatchStatus() {
    matchStatusListener = FirebaseDatabase.instance
        .ref('matches/${widget.matchId}')
        .onValue
        .listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opponent left or match was deleted.')),
          );
        }
        return;
      }

      final player2Id = data['player2Id'];
      final p1Ready = data['player1Ready'] == true; // Host's ready state
      final p2Ready = data['player2Ready'] == true; // Opponent's ready state

      if (!opponentFound && player2Id != null && player2Id.toString().isNotEmpty) {
        setState(() {
          opponentFound = true;
          status = "Opponent found! Waiting for them to start...";
        });
      }

      // Navigate when both are ready
      if (p1Ready && p2Ready && !matchStarted) {
        matchStarted = true;
        matchStatusListener.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OnlineGameScreen(
              matchId: widget.matchId,
              seed: widget.seed, // Seed is read from initial match data in RTDB now
              isPlayer1: widget.isPlayer1,
              playerId: widget.playerId,
            ),
          ),
        );
      }
    });
  }

  // ... (markReady remains for now, will be removed for auto-start later)

  @override
  void dispose() {
    // Cancel the single consolidated listener
    matchStatusListener.cancel(); // Ensure this is the correct listener
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