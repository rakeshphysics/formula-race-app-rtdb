import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:formula_race_app/services/matchmaking_service.dart';
import 'package:formula_race_app/screens/online_game_screen.dart';
import 'home_screen.dart';

class OnlinePlayScreen extends StatefulWidget {
  const OnlinePlayScreen({Key? key}) : super(key: key);

  @override
  State<OnlinePlayScreen> createState() => _OnlinePlayScreenState();
}

class _OnlinePlayScreenState extends State<OnlinePlayScreen> {
  final MatchmakingService matchmakingService = MatchmakingService();
  bool isSearching = false;
  bool matchFound = false;
  String? matchId;
  late BuildContext dialogContext;
  StreamSubscription<DatabaseEvent>? startStatusSubscription;
  bool startClicked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      startMatchmaking();
    });
  }

  @override
  void dispose() {
    startStatusSubscription?.cancel();
    super.dispose();
  }

  void startMatchmaking() async {
    setState(() {
      isSearching = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        dialogContext = context;
        return WillPopScope(
            onWillPop: () async {
          await Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()),
          );
          return false;
        },

        child: AlertDialog(
          title: const Text('Searching for Opponent...'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  cancelMatchmaking();
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        ));
      },
    );

    String? opponentId = await matchmakingService.findMatch();

    if (mounted) {
      Navigator.of(dialogContext).pop();
    }

    setState(() {
      isSearching = false;
      matchFound = opponentId != null;
      matchId = opponentId;
    });

    if (matchFound && matchId != null) {
      // Show Start Game screen
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Match Found!'),
                content: startClicked
                    ? const Text('Waiting for opponent to start...')
                    : const Text('Press Start Game when ready'),
                actions: [
                  if (!startClicked)
                    ElevatedButton(
                      onPressed: () {
                        // Write startStatus/playerId = true
                        _database
                            .child('matches/$matchId/startStatus/${matchmakingService.playerId}')
                            .set(true);

                        setState(() {
                          startClicked = true;
                        });

                        listenToStartStatus();
                      },
                      child: const Text('Start Game'),
                    ),
                ],
              );
            },
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('No Match Found'),
            content: const Text('Please try again.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  void listenToStartStatus() {
    DatabaseReference startStatusRef = _database.child('matches/$matchId/startStatus');

    startStatusSubscription = startStatusRef.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> statusMap = event.snapshot.value as Map<dynamic, dynamic>;

        if (statusMap.keys.length >= 2 &&
            statusMap.values.every((value) => value == true)) {
          // Both players clicked Start → navigate to OnlineGameScreen
          startStatusSubscription?.cancel();

          Navigator.of(context).pop(); // Close Start Game dialog
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => OnlineGameScreen(
              matchId: matchId!,
              playerId: matchmakingService.playerId,
            ),
          ));
        }
      }
    });
  }

  void cancelMatchmaking() async {
    await matchmakingService.cancelCurrentMatch();

    if (mounted) {
      Navigator.of(dialogContext).pop();
      Navigator.of(context).pop();
    }

    setState(() {
      isSearching = false;
    });
  }

  DatabaseReference get _database => FirebaseDatabase.instance.ref();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Online Play',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
