// // lib/qr_host_screen.dart
// import 'package:flutter/material.dart';
// import 'package:qr_flutter/qr_flutter.dart'; // Make sure you added qr_flutter to pubspec.yaml
// import 'package:firebase_database/firebase_database.dart'; // For listening to player2Id
// //import 'package:cloud_firestore/cloud_firestore.dart'; // For listening to ready states
// import 'online_game_screen.dart'; // Import your game screen
// import 'dart:async';
//
//
// class QRHostScreen extends StatefulWidget {
//   final String matchId;
//   final int seed;
//   final bool isPlayer1;
//   final String playerId;
//   final String subject;
//  // <--- NEW: Required for game logic
//   // Host's own player ID
//
//   const QRHostScreen({
//     Key? key,
//     required this.matchId,
//     required this.seed,
//     required this.isPlayer1,
//     required this.playerId,
//     required this.subject,   // <--- Add this
//
//   }) : super(key: key);
//
//   @override
//   State<QRHostScreen> createState() => _QRHostScreenState();
// }
//
// class _QRHostScreenState extends State<QRHostScreen> {
//   String status = "Waiting for opponent...";
//   bool opponentFound = false;
//   bool matchStarted = false;
//   late StreamSubscription<DatabaseEvent> matchStatusListener;
//  // late StreamSubscription<DatabaseEvent> player2Listener;
//  // late StreamSubscription<DocumentSnapshot> readyListener;
//
//   @override
//   void initState() {
//     super.initState();
//     _listenForMatchStatus();
//   }
//
//
//   Future<void> markReady() async {
//     // Update player1Ready in Realtime Database
//     await FirebaseDatabase.instance
//         .ref('matches/${widget.matchId}')
//         .update({'player1Ready': true});
//     setState(() {
//       // startPressed is likely removed, so status is the main update
//       status = "You are ready! Waiting for opponent...";
//     });
//   }
//
//
//   void _listenForMatchStatus() {
//     matchStatusListener = FirebaseDatabase.instance
//         .ref('matches/${widget.matchId}')
//         .onValue
//         .listen((event) {
//       final data = event.snapshot.value as Map<dynamic, dynamic>?;
//
//       if (data == null) {
//         if (mounted) {
//           Navigator.of(context).pop();
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Opponent left or match was deleted.')),
//           );
//         }
//         return;
//       }
//
//       final player2Id = data['player2Id'];
//       final p1Ready = data['player1Ready'] == true; // Host's ready state
//       final p2Ready = data['player2Ready'] == true; // Opponent's ready state
//
//       if (!opponentFound && player2Id != null && player2Id.toString().isNotEmpty) {
//         setState(() {
//           opponentFound = true;
//           //status = "Opponent found! Waiting for them to start...";
//         });
//       }
//
//       // Navigate when both are ready
//       if (p1Ready && p2Ready && !matchStarted) {
//         matchStarted = true;
//         matchStatusListener.cancel();
//
//         //print('✅ DEBUG: Navigating to OnlineGameScreen. Seed: ${widget.seed}, MatchId: ${widget.matchId}, PlayerId: ${widget.playerId}');
//
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (_) => OnlineGameScreen(
//               matchId: widget.matchId,
//               seed: widget.seed, // Seed is read from initial match data in RTDB now
//               isPlayer1: widget.isPlayer1,
//               playerId: widget.playerId,
//               subject: widget.subject,   // <--- Pass fetched subject
//             ),
//           ),
//         );
//       }
//     });
//   }
//
//   // ... (markReady remains for now, will be removed for auto-start later)
//
//   @override
//   void dispose() {
//     // Cancel the single consolidated listener
//     matchStatusListener.cancel(); // Ensure this is the correct listener
//     super.dispose();
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         title:  Text('Host Match', style: TextStyle(color: Color(0xD9FFFFFF), fontSize:screenWidth*0.042)),
//         backgroundColor: Colors.black,
//         iconTheme: const IconThemeData(color: Color(0xD9FFFFFF),), // For back arrow
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               status,
//               textAlign: TextAlign.center,
//               style: const TextStyle(fontSize: 22, color: Color(0xD9FFFFFF)),
//             ),
//             const SizedBox(height: 30),
//             // Display QR Code
//             QrImageView(
//               data: widget.matchId, // The data encoded in the QR code is the matchId
//               version: QrVersions.auto,
//               size: 250.0,
//               backgroundColor: Color(0xD9FFFFFF),
//               foregroundColor: Colors.black,
//             ),
//             const SizedBox(height: 30),
//
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () async {
//                 // Allow host to cancel the match if no one joined or if they change mind
//                 await FirebaseDatabase.instance.ref('matches/${widget.matchId}').remove();
//                 if (mounted) Navigator.of(context).pop();
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.red.withOpacity(0.1),
//                 side: const BorderSide(color: Colors.red, width: 1.2),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
//                 padding:  EdgeInsets.symmetric(horizontal: screenWidth*0.06, vertical: screenWidth*0.04),
//               ),
//               child: Text(
//                 "Cancel Match",
//                 style: TextStyle(color: Color(0xD9FFFFFF), fontSize: screenWidth*0.044),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


// lib/qr_host_screen.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Make sure you added qr_flutter to pubspec.yaml
import 'package:firebase_database/firebase_database.dart'; // For listening to player2Id
import 'online_game_screen.dart'; // Import your game screen
import 'dart:async';
import 'dart:math'; // Added for PIN generation

class QRHostScreen extends StatefulWidget {
  final String matchId;
  final int seed;
  final bool isPlayer1;
  final String playerId;
  final String subject;

  const QRHostScreen({
    Key? key,
    required this.matchId,
    required this.seed,
    required this.isPlayer1,
    required this.playerId,
    required this.subject,
  }) : super(key: key);

  @override
  State<QRHostScreen> createState() => _QRHostScreenState();
}

class _QRHostScreenState extends State<QRHostScreen> {
  String status = "Waiting for opponent...";
  bool opponentFound = false;
  bool matchStarted = false;
  String? generatedPin; // Added to store the 4-digit PIN
  late StreamSubscription<DatabaseEvent> matchStatusListener;

  @override
  void initState() {
    super.initState();
    _setupMatchWithPin(); // Generate and save PIN to Firebase
    _listenForMatchStatus();
  }

  /// Generates a 4-digit PIN and maps it to the matchId in Firebase
  Future<void> _setupMatchWithPin() async {
    final random = Random();
    // Generates a number between 1000 and 9999
    final pin = (1000 + random.nextInt(9000)).toString();

    setState(() {
      generatedPin = pin;
    });

    // Save PIN to the match node AND create a lookup node for the scanner
    final updates = {
      'matches/${widget.matchId}/pin': pin,
      'active_pins/$pin': widget.matchId,
    };

    await FirebaseDatabase.instance.ref().update(updates);
  }

  Future<void> markReady() async {
    await FirebaseDatabase.instance
        .ref('matches/${widget.matchId}')
        .update({'player1Ready': true});
    setState(() {
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
      final p1Ready = data['player1Ready'] == true;
      final p2Ready = data['player2Ready'] == true;

      if (player2Id != null && !p1Ready) {
        markReady(); // This calls your existing markReady() function
      }

      if (!opponentFound && player2Id != null && player2Id.toString().isNotEmpty) {
        setState(() {
          opponentFound = true;
        });
      }

      if (p1Ready && p2Ready && !matchStarted) {
        matchStarted = true;
        matchStatusListener.cancel();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OnlineGameScreen(
              matchId: widget.matchId,
              seed: widget.seed,
              isPlayer1: widget.isPlayer1,
              playerId: widget.playerId,
              subject: widget.subject,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    // Cleanup: Remove the PIN from the lookup table when the host leaves
    if (generatedPin != null) {
      FirebaseDatabase.instance.ref('active_pins/$generatedPin').remove();
    }
    matchStatusListener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Host Match',
            style: TextStyle(
                color: const Color(0xD9FFFFFF), fontSize: screenWidth * 0.042)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(
          color: Color(0xD9FFFFFF),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              status,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, color: Color(0xD9FFFFFF)),
            ),
            const SizedBox(height: 30),
            // Display QR Code
            QrImageView(
              data: widget.matchId,
              version: QrVersions.auto,
              size: 250.0,
              backgroundColor: const Color(0xD9FFFFFF),
              foregroundColor: Colors.black,
            ),

            // --- NEW PIN DISPLAY SECTION ---
            if (generatedPin != null) ...[
              const SizedBox(height: 25),
              Text(
                "OR SHARE PIN",
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: screenWidth * 0.035,
                    letterSpacing: 1.2),
              ),
              const SizedBox(height: 5),
              Text(
                generatedPin!,
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: screenWidth * 0.1,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 12,
                ),
              ),
            ],
            // -------------------------------

            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                // Cleanup PIN lookup and Match node on cancel
                if (generatedPin != null) {
                  await FirebaseDatabase.instance.ref('active_pins/$generatedPin').remove();
                }
                await FirebaseDatabase.instance
                    .ref('matches/${widget.matchId}')
                    .remove();
                if (mounted) Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.1),
                side: const BorderSide(color: Colors.red, width: 1.2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
                padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.06,
                    vertical: screenWidth * 0.04),
              ),
              child: Text(
                "Cancel Match",
                style: TextStyle(
                    color: const Color(0xD9FFFFFF),
                    fontSize: screenWidth * 0.044),
              ),
            ),
          ],
        ),
      ),
    );
  }
}