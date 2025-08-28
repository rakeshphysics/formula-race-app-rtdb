import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; // Import for HapticFeedback
import 'online_game_screen.dart'; // Import your game screen

class QRScanScreen extends StatefulWidget {
  final String userId;
  const QRScanScreen({Key? key, required this.userId}) : super(key: key);

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
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Scan QR Code', style: TextStyle(color: Colors.white, fontSize: screenWidth*0.042)),
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

    final userId = widget.userId;
    final dbRef = FirebaseDatabase.instance.ref('matches/$matchId');

    try {
      final snapshot = await dbRef.get();

      if (!snapshot.exists || snapshot.value == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Match does not exist or has been deleted.')),
          );
          // Navigator.of(context).pop(); // Removed immediate pop
          controller.start(); // ADD THIS: Restart scanner
        }
        _isProcessingScan = false; // ADD THIS: Important: reset flag
        return;
      }

      Map<String, dynamic> matchData;
      try {
        matchData = Map<String, dynamic>.from(snapshot.value as Map);
      } catch (e) {
        // Handle cases where snapshot.value is not a valid Map (e.g., scanned non-match QR)
        //print("Error casting match data: $e"); // Debug print
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid QR Code: Not a valid match data.')), // User-friendly message
          );
          controller.start(); // Restart scanner
        }
        _isProcessingScan = false; // Important: reset flag
        return; // Exit the function as the data is invalid
      }

      if (matchData['player2Id'] != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Match is already full.')),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      if (matchData['player1Id'] == userId) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You cannot join your own match.')),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      // Attempt to update player2Id in Realtime Database
      await dbRef.update({
        'player2Id': userId,
      });

      // All match data is now in RTDB
      final seed = matchData['seed']; // Get seed directly from RTDB snapshot

      if (seed != null) {
        if (mounted) {
          await dbRef.update({
            'player1Ready': true, // Set player1 (host) as ready
            'player2Ready': true, // Set player2 (scanner) as ready
          });

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
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      // General catch-all for any other unexpected errors during the process
      //print("Error joining match via QR: $e"); // MODIFIED print for clarity
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid QR Code or connection error.')), // MODIFIED: Generic user-friendly message
        );
        // Navigator.of(context).pop(); // REMOVED immediate pop
        controller.start(); // ADDED: Restart scanner in case of general error
      }
      _isProcessingScan = false; // ADDED: Important: reset flag in general error
    }
    // REMOVED THE ENTIRE FINALLY BLOCK HERE

  }
}