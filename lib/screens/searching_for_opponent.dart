import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:formula_race_app/services/matchmaking_service.dart';
import 'online_game_screen.dart';
import 'home_screen.dart';


class SearchingForOpponent extends StatefulWidget {
  final String userId;
  const SearchingForOpponent({super.key, required this.userId});

  @override
  State<SearchingForOpponent> createState() => _SearchingForOpponentState();
}

class _SearchingForOpponentState extends State<SearchingForOpponent> {
  String statusText = "Searching for opponent";
  String? matchId;
  int? seed;
  bool isPlayer1 = false;
  bool opponentFound = false;
  bool startPressed = false;
  Timer? timeoutTimer;
  StreamSubscription<DatabaseEvent>? dbListener;
  StreamSubscription<DocumentSnapshot>? readyListener;

  bool matchStarted = false;
  final int roomDeletionTimeoutSeconds = 6;
  Timer? dotAnimationTimer;
  String animatedDots = "";

  @override
  void initState() {
    super.initState();

    dotAnimationTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        animatedDots = "." * ((timer.tick % 3) + 1); // Cycle . .. ...
      });
    });

    if (!matchStarted) {
      //print("🚀 handleMatchmaking() called");
      matchStarted = true;
      handleMatchmaking();
    } else {
      //print("⚠️ Skipping duplicate matchmaking");
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

        // STEP 1: Start 10s timeout to delete match and return home
        timeoutTimer = Timer(Duration(seconds: roomDeletionTimeoutSeconds), () async {
          if (!opponentFound && matchId != null) {
            //print("⏰ No opponent joined in 10s. Deleting match $matchId");

            await FirebaseDatabase.instance.ref('matches/$matchId').remove();

            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => HomeScreen()),
                    (route) => false,
              );
            }
          }
        });
        listenForPlayer2();
      }
    }
  }



  void listenForPlayer2() {
    final ref = FirebaseDatabase.instance.ref('matches/$matchId/player2Id');
    dbListener = ref.onValue.listen((event) {
      final val = event.snapshot.value;
      //print("🔍 DEBUG RTDB Player2: received val: $val. OpponentFound: $opponentFound. MatchId: $matchId"); // Debug print


      if (val != null && val.toString().isNotEmpty) {
        setState(() {
          statusText = "Match Found !";
          opponentFound = true;
        });
        listenForBothReady();
      }

    });
  }

  void listenForBothReady() {
    final docRef = FirebaseFirestore.instance.collection('matches').doc(matchId);
    readyListener = docRef.snapshots().listen((doc) {

      if (!doc.exists) { // This is the more robust check for deletion
        //print("⚠️ DEBUG: Match document deleted. Redirecting opponent to Home Screen."); // Debug print
        readyListener?.cancel(); // Cancel this listener
        dbListener?.cancel(); // Cancel the other listener if active (for Player 1)
        timeoutTimer?.cancel(); // Cancel any timeout timer

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => HomeScreen()),
                (route) => false,
          );
        }
        return; // Exit as match is deleted
      }
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

  void cancelSearch() async {
    // Cancel all listeners and timers
    dbListener?.cancel();
    readyListener?.cancel();
    timeoutTimer?.cancel();
    dotAnimationTimer?.cancel(); // Cancel the dot animation timer too

    // If this player was Player 1 and no opponent was found, delete the match
    if (isPlayer1 && !opponentFound && matchId != null) {
      await FirebaseDatabase.instance.ref('matches/$matchId').remove();
    }

    // Navigate back to the Home Screen
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => HomeScreen()),
            (route) => false,
      );
    }
  }

  @override
  void dispose() {
    dbListener?.cancel();
    readyListener?.cancel();
    dotAnimationTimer?.cancel();
    timeoutTimer?.cancel(); // Ensure timeoutTimer is cancelled on dispose as well
    super.dispose();
  }


  Future<bool> _onWillPop() async {
    // If opponent is found and start is not pressed, it means we are on the "Start Game" screen.
    if (opponentFound && !startPressed) {
      // Confirm with user before leaving match
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Leave Match?'),
          content: const Text('Are you sure you want to leave this match?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Yes')),
          ],
        ),
      );
      if (confirm == true) {
        await leaveMatchCleanup(); // Perform cleanup if user confirms
        return true; // Allow pop (will go to HomeScreen via cleanup)
      } else {
        return false; // Don't allow pop
      }
    }
    // For other states (searching), allow default back behavior to `cancelSearch`
    // or prevent it if the user initiated cancelSearch action.
    return true; // Allows back press by default for other states
  }

  // New function to handle leaving match cleanup
  Future<void> leaveMatchCleanup() async {
    // Cancel all listeners and timers for current player
    dbListener?.cancel();
    readyListener?.cancel();
    timeoutTimer?.cancel();
    dotAnimationTimer?.cancel();

    // Delete the entire match from Firebase
    if (matchId != null) {
      await FirebaseDatabase.instance.ref('matches/$matchId').remove();
    }

    // Navigate current player back to HomeScreen
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => HomeScreen()),
            (route) => false,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height; // Get screen height
    final screenWidth = MediaQuery.of(context).size.width;   // Get screen width

    return WillPopScope( // WRAP SCAFFOLD WITH WILLPOPSCOPE
        onWillPop: _onWillPop,
    child: Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ... existing widgets ...
            const CircularProgressIndicator(color: Colors.white),
            SizedBox(height: screenHeight * 0.03), // Use screen height for spacing
            Row(
              mainAxisSize: MainAxisSize.min, // Keep the row size to its children
              children: [
                Text(
                  statusText, // Static text
                  style: const TextStyle(color: Colors.white, fontSize: 24.0),
                ),
                SizedBox( // Give dots a fixed width to prevent shifting
                  width: 24.0, // Adjust this width as needed to fit "..." comfortably
                  child: Text(
                    animatedDots, // Animated dots
                    style: const TextStyle(color: Colors.white, fontSize: 24.0),
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.05), // Use screen height for spacing

            // Existing Start Game button
            if (opponentFound && !startPressed)
              SizedBox( // Wrap with SizedBox to control size
                width: screenWidth * 0.6, // Match Cancel button width
                height: screenHeight * 0.07, // Match Cancel button height
                child: ElevatedButton(
                  onPressed: markReady,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.withOpacity(0.1), // 10% opacity
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04, // Responsive horizontal padding
                      vertical: screenHeight * 0.015, // Responsive vertical padding
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: const BorderSide(color: Colors.amber, width: 2), // Amber orange border
                    ),
                    textStyle: const TextStyle(fontSize: 18), // Adjust text size
                  ),
                  child: const Text(
                    "Start Game",
                    style: TextStyle(color: Colors.white, fontSize: 22.0),  // White text
                  ),
                ),
              ),

            // NEW: Cancel Search Button styling
            if (!opponentFound)
              SizedBox( // Wrap with SizedBox to control size
                width: screenWidth * 0.6, // Make it big, e.g., 60% of screen width
                height: screenHeight * 0.07, // Make it big, e.g., 7% of screen height
                child: ElevatedButton(
                  onPressed: cancelSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.withOpacity(0.1), // 10% opacity
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04, // Responsive horizontal padding
                      vertical: screenHeight * 0.015, // Responsive vertical padding
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: const BorderSide(color: Color(0xFFFFA500), width: 2), // Amber orange border
                    ),
                    textStyle: const TextStyle(fontSize: 18), // Adjust text size
                  ),
                  child: const Text(
                    "Cancel Search",
                    style: TextStyle(color: Colors.white, fontSize: 22.0), // White text
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
    );

  }
}
