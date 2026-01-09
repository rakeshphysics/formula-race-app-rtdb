// import 'package:flutter/material.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// //import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/services.dart'; // Import for HapticFeedback
// import 'online_game_screen.dart'; // Import your game screen
//
// class QRScanScreen extends StatefulWidget {
//   final String userId;
//   const QRScanScreen({Key? key, required this.userId}) : super(key: key);
//
//   @override
//   State<QRScanScreen> createState() => _QRScanScreenState();
// }
//
// class _QRScanScreenState extends State<QRScanScreen> {
//   MobileScannerController controller = MobileScannerController(
//     detectionSpeed: DetectionSpeed.normal,
//     facing: CameraFacing.back,
//   );
//   bool _isProcessingScan = false; // To prevent multiple scans/joins
//
//   @override
//   void initState() {
//     super.initState();
//     controller.start(); // Start the camera when the screen initializes
//   }
//
//   @override
//   void dispose() {
//     controller.stop(); // Stop the camera when the screen is disposed
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         title: Text('Scan QR Code', style: TextStyle(color: Color(0xD9FFFFFF), fontSize: screenWidth*0.042)),
//         backgroundColor: Colors.black,
//         iconTheme: const IconThemeData(color: Color(0xD9FFFFFF),),
//       ),
//       body: Stack(
//         children: [
//           MobileScanner(
//             controller: controller,
//             onDetect: (capture) async {
//               if (_isProcessingScan) return; // Prevent processing if already busy
//
//               _isProcessingScan = true; // Set flag to true
//
//               final List<Barcode> barcodes = capture.barcodes;
//               if (barcodes.isNotEmpty) {
//                 final String? scannedMatchId = barcodes.first.rawValue;
//
//                 if (scannedMatchId != null && scannedMatchId.isNotEmpty) {
//                   HapticFeedback.lightImpact(); // Give feedback that a scan happened
//                   controller.stop(); // Stop scanning temporarily after first valid scan
//
//                   await _joinMatch(scannedMatchId); // Attempt to join the match
//                 }
//               }
//               _isProcessingScan = false; // Reset flag after processing
//             },
//           ),
//           Center(
//             child: Container(
//               width: 200,
//               height: 200,
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.amber, width: 3),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//           ),
//           const Positioned(
//             bottom: 50,
//             left: 0,
//             right: 0,
//             child: Text(
//               'Align QR code within the frame',
//               textAlign: TextAlign.center,
//               style: TextStyle(color: Color(0xD9FFFFFF), fontSize: 16),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _joinMatch(String matchId) async {
//
//     final userId = widget.userId;
//     final dbRef = FirebaseDatabase.instance.ref('matches/$matchId');
//
//     try {
//       final snapshot = await dbRef.get();
//
//       if (!snapshot.exists || snapshot.value == null) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Match does not exist or has been deleted.')),
//           );
//           // Navigator.of(context).pop(); // Removed immediate pop
//           controller.start(); // ADD THIS: Restart scanner
//         }
//         _isProcessingScan = false; // ADD THIS: Important: reset flag
//         return;
//       }
//
//       Map<String, dynamic> matchData;
//       try {
//         matchData = Map<String, dynamic>.from(snapshot.value as Map);
//       } catch (e) {
//         // Handle cases where snapshot.value is not a valid Map (e.g., scanned non-match QR)
//         //print("Error casting match data: $e"); // Debug print
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Invalid QR Code: Not a valid match data.')), // User-friendly message
//           );
//           controller.start(); // Restart scanner
//         }
//         _isProcessingScan = false; // Important: reset flag
//         return; // Exit the function as the data is invalid
//       }
//
//       if (matchData['player2Id'] != null) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Match is already full.')),
//           );
//           Navigator.of(context).pop();
//         }
//         return;
//       }
//
//       if (matchData['player1Id'] == userId) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('You cannot join your own match.')),
//           );
//           Navigator.of(context).pop();
//         }
//         return;
//       }
//
//       // Attempt to update player2Id in Realtime Database
//       await dbRef.update({
//         'player2Id': userId,
//       });
//
//       // All match data is now in RTDB
//       final seed = matchData['seed']; // Get seed directly from RTDB snapshot
//
//       if (seed != null) {
//         if (mounted) {
//           await dbRef.update({
//             'player1Ready': true, // Set player1 (host) as ready
//             'player2Ready': true, // Set player2 (scanner) as ready
//           });
//
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (_) => OnlineGameScreen(
//                 matchId: matchId,
//                 seed: seed,
//                 isPlayer1: false, // Joining player is Player 2
//                 playerId: userId,
//                 subject: matchData['subject'] ?? 'Physics',  // <--- Pass fetched subject
//
//               ),
//             ),
//           );
//         }
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Failed to get match details (seed).')),
//           );
//           Navigator.of(context).pop();
//         }
//       }
//     } catch (e) {
//       // General catch-all for any other unexpected errors during the process
//       //print("Error joining match via QR: $e"); // MODIFIED print for clarity
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Invalid QR Code or connection error.')), // MODIFIED: Generic user-friendly message
//         );
//         // Navigator.of(context).pop(); // REMOVED immediate pop
//         controller.start(); // ADDED: Restart scanner in case of general error
//       }
//       _isProcessingScan = false; // ADDED: Important: reset flag in general error
//     }
//     // REMOVED THE ENTIRE FINALLY BLOCK HERE
//
//   }
// }

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'online_game_screen.dart';

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

  bool _isProcessingScan = false;
  final TextEditingController _pinController = TextEditingController(); // Controller for PIN input

  @override
  void initState() {
    super.initState();
    controller.start();
  }

  @override
  void dispose() {
    controller.stop();
    _pinController.dispose(); // Clean up controller
    super.dispose();
  }

  /// NEW: Logic to look up matchId from a 4-digit PIN
  Future<void> _handlePinSubmit(String pin) async {
    if (pin.length != 4) return;

    setState(() => _isProcessingScan = true);
    HapticFeedback.mediumImpact();

    try {
      // Look up the matchId associated with this PIN
      final snapshot = await FirebaseDatabase.instance.ref('active_pins/$pin').get();

      if (snapshot.exists && snapshot.value != null) {
        final String matchId = snapshot.value.toString();

        // Once we have the matchId, we delete the PIN from active_pins
        // so it can be reused by others immediately.
        await FirebaseDatabase.instance.ref('active_pins/$pin').remove();

        // Use your existing join logic
        await _joinMatch(matchId);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid PIN. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error connecting to server.')),
        );
      }
    } finally {
      setState(() => _isProcessingScan = false);
      _pinController.clear(); // Clear input for next attempt
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom; // Detect keyboard height

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false, // Prevent camera jump when keyboard opens
      appBar: AppBar(
        title: Text('Join Match', style: TextStyle(color: const Color(0xD9FFFFFF), fontSize: screenWidth*0.042)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Color(0xD9FFFFFF),),
      ),
      body: Stack(
        children: [
          // 1. Camera Scanner
          MobileScanner(
            controller: controller,
            onDetect: (capture) async {
              if (_isProcessingScan) return;
              _isProcessingScan = true;

              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? scannedMatchId = barcodes.first.rawValue;
                if (scannedMatchId != null && scannedMatchId.isNotEmpty) {
                  HapticFeedback.lightImpact();
                  controller.stop();
                  await _joinMatch(scannedMatchId);
                }
              }
              _isProcessingScan = false;
            },
          ),

          // 2. QR Frame Overlay
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.amber.withOpacity(0.5), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // 3. PIN Input Section (Bottom Overlay)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                  bottom: bottomPadding > 0 ? bottomPadding + 20 : 50,
                  top: 20,
                  left: 30,
                  right: 30
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'OR ENTER 4-DIGIT PIN',
                    style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 15
                      ),
                      decoration: InputDecoration(
                        counterText: "", // Hide character count
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.amber.withOpacity(0.3)),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.amber),
                        ),
                        hintText: "0000",
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.1)),
                      ),
                      onChanged: (value) {
                        if (value.length == 4) {
                          FocusScope.of(context).unfocus(); // Close keyboard
                          _handlePinSubmit(value);
                        }
                      },
                    ),
                  ),
                  if (_isProcessingScan)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: SizedBox(height: 2, child: LinearProgressIndicator(color: Colors.amber)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- YOUR EXISTING JOIN MATCH LOGIC (UNCHANGED) ---
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
          controller.start();
        }
        _isProcessingScan = false;
        return;
      }

      Map<String, dynamic> matchData;
      try {
        matchData = Map<String, dynamic>.from(snapshot.value as Map);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid Data: Not a valid match.')),
          );
          controller.start();
        }
        _isProcessingScan = false;
        return;
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

      await dbRef.update({
        'player2Id': userId,
      });

      final seed = matchData['seed'];

      if (seed != null) {
        if (mounted) {
          await dbRef.update({

            'player2Ready': true,
          });

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OnlineGameScreen(
                matchId: matchId,
                seed: seed,
                isPlayer1: false,
                playerId: userId,
                subject: matchData['subject'] ?? 'Physics',
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid Code or connection error.')),
        );
        controller.start();
      }
      _isProcessingScan = false;
    }
  }
}