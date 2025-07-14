/*import 'dart:async';
import 'package:flutter/material.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';
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
  //bool startPressed = false;
  Timer? timeoutTimer;
  //StreamSubscription<DatabaseEvent>? dbListener;
  late StreamSubscription<DatabaseEvent>? matchStatusListener;

  bool matchStarted = false;
  final int roomDeletionTimeoutSeconds = 6;
  Timer? dotAnimationTimer;
  String animatedDots = "";

  void initState() {
    super.initState();
    dotAnimationTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        animatedDots = "." * ((timer.tick % 3) + 1);
      });
    });

    if (!matchStarted) {
      matchStarted = true;
      // REMOVE: handleMatchmaking(); // This is only called once at startup
      // The handleMatchmaking will call _listenForMatchStatus from player1 or player2 flow.
    }
    _startMatchmakingFlow(); // New function to encapsulate flow
  }


  Future<void> _startMatchmakingFlow() async {
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
      _listenForMatchStatus(); // Start listening for status changes
    } else {
      // Player 1 flow
      final created = await MatchmakingService.createMatch(widget.userId);
      if (created != null) {
        matchId = created['matchId'];
        seed = created['seed'];
        isPlayer1 = true;

        timeoutTimer = Timer(Duration(seconds: roomDeletionTimeoutSeconds), () async {
          if (!opponentFound && matchId != null) {
            await FirebaseDatabase.instance.ref('matches/$matchId').remove();
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => HomeScreen(userId: widget.userId)),
                    (route) => false,
              );
            }
          }
        });
        _listenForMatchStatus(); // Start listening for status changes
      }
    }
  }

  // New consolidated listener for all match status changes from Realtime Database
  void _listenForMatchStatus() {
    matchStatusListener = FirebaseDatabase.instance
        .ref('matches/$matchId')
        .onValue
        .listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) { // Match might have been deleted
        if (mounted) {
          matchStatusListener?.cancel(); // Cancel listener
          timeoutTimer?.cancel(); // Cancel any timeout
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => HomeScreen(userId: widget.userId)),
                (route) => false,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Match deleted by opponent or timed out.')),
          );
        }
        return;
      }

      final player2Id = data['player2Id'];
      final p1Ready = data['player1Ready'] == true;
      final p2Ready = data['player2Ready'] == true;

      // Detect opponent joining
      if (!opponentFound && player2Id != null && player2Id.toString().isNotEmpty) {
        setState(() {
          statusText = "Match Found!";
          opponentFound = true;
        });
        timeoutTimer?.cancel(); // Cancel timeout if opponent joined
      }

      // Navigate when both players are ready
      if (p1Ready && p2Ready && !matchStarted) {
        matchStarted = true; // Set flag to prevent multiple navigations
        matchStatusListener?.cancel(); // Cancel listener before navigating
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











  void cancelSearch() async {
    // Cancel all listeners and timers
    matchStatusListener?.cancel(); // Use the consolidated listener
    // REMOVE: dbListener?.cancel();
    // REMOVE: readyListener?.cancel();
    timeoutTimer?.cancel();
    dotAnimationTimer?.cancel();

    // If this player was Player 1 and no opponent was found, delete the match
    if (isPlayer1 && !opponentFound && matchId != null) {
      await FirebaseDatabase.instance.ref('matches/$matchId').remove();
    }

    // Navigate back to the Home Screen
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => HomeScreen(userId: widget.userId)),
            (route) => false,
      );
    }
  }

  @override
  void dispose() {
    matchStatusListener?.cancel(); // Use the consolidated listener
    // REMOVE: dbListener?.cancel();
    // REMOVE: readyListener?.cancel();
    dotAnimationTimer?.cancel();
    timeoutTimer?.cancel();
    super.dispose();
  }


  Future<bool> _onWillPop() async {
    // If opponent is found and start is not pressed, it means we are on the "Start Game" screen.
    if (opponentFound) {
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
    matchStatusListener?.cancel(); // Use the consolidated listener
    // REMOVE: dbListener?.cancel(); // This was replaced by matchStatusListener
    // REMOVE: readyListener?.cancel(); // This was replaced by matchStatusListener
    timeoutTimer?.cancel();
    dotAnimationTimer?.cancel();

    // Delete the entire match from Firebase
    if (matchId != null) {
      await FirebaseDatabase.instance.ref('matches/$matchId').remove();
    }

    // Navigate current player back to HomeScreen
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => HomeScreen(userId: widget.userId)),
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
} */
