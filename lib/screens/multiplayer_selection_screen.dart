// lib/screens/multiplayer_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:formula_race_app/services/matchmaking_service.dart';
import 'searching_for_opponent.dart';
import 'qr_host_screen.dart';
import 'qr_scan_screen.dart';
// Import other screens or services as needed

class MultiplayerSelectionScreen extends StatelessWidget {
  const MultiplayerSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            ElevatedButton(
              onPressed: () {
                final User? currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser != null && currentUser.uid.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SearchingForOpponent(userId: currentUser.uid),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error: User not authenticated.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.withOpacity(0.1),
                side: const BorderSide(color: Colors.amber, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: const Text(
                "Random Match",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            const SizedBox(height: 10),

            // --- Host Match (QR) Button ---
            ElevatedButton(
              onPressed: () async {
                final User? currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser != null && currentUser.uid.isNotEmpty) {
                  final createdMatchData = await MatchmakingService.createMatch(currentUser.uid);

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
                          playerId: currentUser.uid,
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
                backgroundColor: Colors.amber.withOpacity(0.1),
                side: const BorderSide(color: Colors.amber, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: const Text(
                "Host Match (QR)",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            const SizedBox(height: 10),

            // --- Join Match (Scan QR) Button ---
            ElevatedButton(
              onPressed: () {
                // Navigate to the QR scanning screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QRScanScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.withOpacity(0.1),
                side: const BorderSide(color: Colors.amber, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: const Text(
                "Join Match (Scan QR)",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}