import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; // Import for HapticFeedback
import 'online_game_screen.dart'; // Import your game screen

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({Key? key}) : super(key: key);

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _isProcessingScan = false; // To prevent multiple scans/joins

  @override
  void initState() {
    super.initState();
    controller.start(); // Start the camera when the screen initializes
  }

  @override
  void dispose() {
    controller.stop(); // Stop the camera when the screen is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Code', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) async {
              if (_isProcessingScan) return; // Prevent processing if already busy

              _isProcessingScan = true; // Set flag to true

              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? scannedMatchId = barcodes.first.rawValue;

                if (scannedMatchId != null && scannedMatchId.isNotEmpty) {
                  HapticFeedback.lightImpact(); // Give feedback that a scan happened
                  controller.stop(); // Stop scanning temporarily after first valid scan

                  await _joinMatch(scannedMatchId); // Attempt to join the match
                }
              }
              _isProcessingScan = false; // Reset flag after processing
            },
          ),
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.amber, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Text(
              'Align QR code within the frame',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinMatch(String matchId) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User not authenticated.')),
        );
        Navigator.of(context).pop(); // Go back to selection screen
      }
      return;
    }

    final userId = currentUser.uid;
    final dbRef = FirebaseDatabase.instance.ref('matches/$matchId');

    try {
      // --- BEGIN REVISED NON-ATOMIC JOIN LOGIC ---
      final snapshot = await dbRef.get(); // Get current state of the match

      if (!snapshot.exists || snapshot.value == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Match does not exist or has been deleted.')),
          );
          Navigator.of(context).pop(); // Go back to selection screen
        }
        return;
      }

      final matchData = Map<String, dynamic>.from(snapshot.value as Map);

      if (matchData['player2Id'] != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Match is already full.')),
          );
          Navigator.of(context).pop(); // Go back to selection screen
        }
        return;
      }

      if (matchData['player1Id'] == userId) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You cannot join your own match.')),
          );
          Navigator.of(context).pop(); // Go back to selection screen
        }
        return;
      }

      // Attempt to update player2Id
      await dbRef.update({
        'player2Id': userId,
      });

      // --- END REVISED NON-ATOMIC JOIN LOGIC ---

      // Now, proceed to get seed from Firestore and navigate
      final doc = await FirebaseFirestore.instance.collection('matches').doc(matchId).get();
      final seed = doc.data()?['seed'];

      if (seed != null) {
        if (mounted) {
          // Mark player2 as ready in Firestore
          await FirebaseFirestore.instance.collection('matches').doc(matchId).update({'player2Ready': true});

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OnlineGameScreen(
                matchId: matchId,
                seed: seed,
                isPlayer1: false, // Joining player is Player 2
                playerId: userId,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to get match details (seed).')),
          );
          Navigator.of(context).pop(); // Go back to selection screen
        }
      }
    } catch (e) {
      print("Error joining match via QR: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error joining match: ${e.toString()}')),
        );
        Navigator.of(context).pop(); // Go back to selection screen on error
      }
    }finally {
      // Restart scanner after potential error or failed join
      // Removed controller.isClosed == false check
      if (mounted) {
        controller.start(); // Try to start the controller if the widget is still mounted
      }
    }
  }
}