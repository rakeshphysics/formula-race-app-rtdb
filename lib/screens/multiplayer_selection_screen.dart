// lib/screens/multiplayer_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:formularacing/services/matchmaking_service.dart';
//import 'searching_for_opponent.dart';
import 'qr_host_screen.dart';
import 'qr_scan_screen.dart';
// Import other screens or services as needed

class MultiplayerSelectionScreen extends StatelessWidget {
  final String userId;
  const MultiplayerSelectionScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Choose Mode', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white), // For back arrow
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- Random Match Button ---
            // ElevatedButton(
            //   onPressed: () {
            //     final User? currentUser = FirebaseAuth.instance.currentUser;
            //     if (currentUser != null && currentUser.uid.isNotEmpty) {
            //       Navigator.push(
            //         context,
            //         MaterialPageRoute(
            //           builder: (context) => SearchingForOpponent(userId: userId),
            //         ),
            //       );
            //     }
            //   },
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: Colors.amber.withOpacity(0.1),
            //     side: const BorderSide(color: Colors.amber, width: 2),
            //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            //   ),
            //   child: const Text(
            //     "Random Match",
            //     style: TextStyle(fontSize: 20,color: Colors.white, fontWeight: FontWeight.normal),
            //   ),
            // ),
            // SizedBox(
            //   height: screenHeight * 0.03, // Using your already defined screenHeight
            // ),

            // --- Host Match (QR) Button ---
          SizedBox(
          width: screenWidth * 0.75, // Responsive width
          height: screenHeight * 0.075,
            child: ElevatedButton(
              onPressed: () async {
                final User? currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser != null && currentUser.uid.isNotEmpty) {
                  final createdMatchData = await MatchmakingService.createMatch(userId);

                  // No need for `if (mounted)` here as this is a new page's context
                  // that is guaranteed to be active until it's popped/replaced.
                  if (createdMatchData != null) {
                    final matchId = createdMatchData['matchId'];
                    final seed = createdMatchData['seed'];

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QRHostScreen(
                          matchId: matchId,
                          seed: seed,
                          isPlayer1: true,
                          playerId: userId,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to create match. Check console for Firebase errors.')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error: User not authenticated.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0x34FFC107), // More vibrant color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),side: BorderSide(color: Colors.amber, width: 1.2),

                ),
              ),
              child: const Text(
                "Host Match (QR)",
                style: TextStyle(fontSize: 20,color: Colors.white, fontWeight: FontWeight.normal)
              ),
            ),
          ),
            SizedBox(
              height: screenHeight * 0.03, // Using your already defined screenHeight
            ),

            // --- Join Match (Scan QR) Button ---
      SizedBox(
        width: screenWidth * 0.75, // Responsive width
        height: screenHeight * 0.075,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to the QR scanning screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QRScanScreen(userId: userId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0x34FFC107), // More vibrant color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),side: BorderSide(color: Colors.amber, width: 1.2),

                ),
              ),
              child: const Text(
                "Join Match (Scan QR)",
                style: TextStyle(fontSize: 20,color: Colors.white, fontWeight: FontWeight.normal)
              ),
            ),
      ),
          ],
        ),
      ),
    );
  }
}