// lib/screens/online_game_screen.dart
// ----------------------------------------------------
// Online Play screen → consistent with Solo Play:
// - totalQuestions = 10
// - Progress bar → 10 segmented bars
// - Game stops after 10 questions
// - One constant to control everything
// - CHUNK FORMAT
// ----------------------------------------------------
// .............START................. Import Dependencies.........................
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:audioplayers/audioplayers.dart';
import '../widgets/formula_option_button_online_play.dart';
import 'online_result_screen.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart'as firestore;
import 'package:formula_race_app/services/mistake_tracker_service.dart';


// .............END................. Import Dependencies.........................


// .............START................. Load Qns from combined JSON..........................
Future<List<dynamic>> loadQuestionsFromAssets() async {
  ////print("📦 Step 1: Loading JSON from assets...");
  final jsonString = await rootBundle.loadString('assets/formulas/full_syllabus_online_play.json');
  ////print("✅ Step 2: JSON loaded. Length of string: ${jsonString.length}");

  final decoded = jsonDecode(jsonString);
  ////print("🔍 Step 3: Decoded JSON length: ${decoded.length}");

  return decoded;
}
// .............END................. Load Qns from combined JSON..........................

// .............START................. Fn loads 10Qns from shared seed with given conditions........................
Future<List<Map<String, dynamic>>> getRandomQuestions(int seed) async {
  final allQuestions = await loadQuestionsFromAssets();
  final random = Random(seed);
  ////print("🎲 Step 4: Shuffling questions with seed: $seed");

  Map<String, List<Map<String, dynamic>>> buckets = {
    '11_easy': [],
    '11_medium': [],
    '11_god': [],
    '12_easy': [],
    '12_medium': [],
    '12_god': [],
  };

  for (var q in allQuestions) {
    final cls = q['tags']['class'];
    final diff = q['tags']['difficulty'];
    final key = '${cls}_$diff';
    if (buckets.containsKey(key)) {
      buckets[key]!.add(Map<String, dynamic>.from(q));
    }
  }

  List<Map<String, dynamic>> pickUniqueChapters(
      List<Map<String, dynamic>> questions,
      int count,
      Set<String> usedChapters,
      Random rng,
      ) {
    questions.shuffle(rng);
    final selected = <Map<String, dynamic>>[];
    for (var q in questions) {
      final chapter = q['tags']['chapter'];
      if (!usedChapters.contains(chapter)) {
        selected.add(q);
        usedChapters.add(chapter);
        if (selected.length == count) break;
      }
    }
    return selected;
  }

  final usedChapters = <String>{};
  final selected = <Map<String, dynamic>>[];

  selected.addAll(pickUniqueChapters(buckets['11_easy']!, 2, usedChapters, random));
  selected.addAll(pickUniqueChapters(buckets['11_medium']!, 2, usedChapters, random));
  selected.addAll(pickUniqueChapters(buckets['11_god']!, 1, usedChapters, random));
  selected.addAll(pickUniqueChapters(buckets['12_easy']!, 2, usedChapters, random));
  selected.addAll(pickUniqueChapters(buckets['12_medium']!, 2, usedChapters, random));
  selected.addAll(pickUniqueChapters(buckets['12_god']!, 1, usedChapters, random));

  ////print("📦 Final selected questions (full data):");
  for (var q in selected) {
    ////print(jsonEncode(q));
  }



  return selected;
}
// .............END................. Fn loads 10Qns from shared seed with given conditions..........................




// ............. Chunk 1 ONLINE GAME SCREEN WIDGET .............
class OnlineGameScreen extends StatefulWidget {
  final String matchId;
  final String playerId;
  final int seed;           // 👈 Add this
  final bool isPlayer1;


  // 👈 And this

  OnlineGameScreen({
    super.key,
    required this.matchId,
    required this.playerId,
    required this.seed,      // 👈 Include in constructor
    required this.isPlayer1,
  });
  @override
  State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}



class _OnlineGameScreenState extends State<OnlineGameScreen> with SingleTickerProviderStateMixin {

  // ............. Chunk 2 STATE VARIABLES .............
  final int totalQuestions = 2;  // ← control number of questions and progress bars

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final AudioPlayer audioPlayer = AudioPlayer();
  List<dynamic> questions = [];
  int currentQuestionIndex = 0;
  bool questionLocked = false;
  String feedbackMessage = '';
  StreamSubscription<DatabaseEvent>? answerSubscription;
  StreamSubscription<DatabaseEvent>? questionIndexSubscription;
  StreamSubscription<DatabaseEvent>? playerStatusSubscription;
  Timer? autoSkipTimer;
  bool opponentLeft = false;
  late String opponentId;
  bool gameOver = false;
  bool isMovingToNextQuestion = false;
  bool isLoading = true;
  String? winnerMessage;
  bool showCorrectAnswer = false;
  bool isCorrect = false;
  int myScore = 0;
  int opponentScore = 0;
  bool opponentAnswered = false;
  bool revealCorrectAnswerOnOpponentWin = false;
  bool showCorrectAnswerOnSelfWrong = false;


  List<String> shuffledOptions = [];
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  String? selectedOption;
  bool bothWrong = false;

// .............START................. This function stores the selected qns in game room so that
// ................................... both players call the same 10 Qns..........................
  Future<void> loadQuestionsFromRoom() async {
    try {
      final doc = await firestore.FirebaseFirestore.instance.collection('matches').doc(widget.matchId).get();

      if (doc.exists) {
        final seed = doc['seed'] ?? 0;

        final qns = await getRandomQuestions(seed);

        setState(() {
          questions = qns;
          isLoading = false;
        });
        ////print("📋 Step 6: Questions assigned. Length = ${qns.length}");
      } else {
        ////print('Room not found: ${widget.matchId}');
      }
    } catch (e) {
      ////print('Error fetching room seed: $e');
    }
  }
// .............END................. This function stores the selected qns in game room so that
// ................................... both players call the same 10 Qns..........................

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(_progressController);
    _progressController.addListener(() {
      setState(() {});
    });

      loadQuestionsFromRoom();
      listenToCurrentQuestionIndex();
      listenToAnswers();
      setPlayerStatusOnline();
      listenToPlayerStatus();
      listenToScoreUpdates();
      listenToGameOverFlag();


  }

  @override
  void dispose() {
    //answerSubscription?.cancel();
    questionIndexSubscription?.cancel();
    playerStatusSubscription?.cancel();
    autoSkipTimer?.cancel();
    _progressController.dispose();

    if (!gameOver) {
      setPlayerStatusOffline();
    }
    super.dispose();
  }

  // ............. Chunk 3 PLAYER STATUS ONLINE/OFFLINE .............
  void setPlayerStatusOnline() {
    _database.child('matches/${widget.matchId}/playerStatus/${widget.playerId}').set('online');
    _database.child('matches/${widget.matchId}/playerStatus/${widget.playerId}')
        .onDisconnect()
        .set('offline');
  }

  void setPlayerStatusOffline() {
    _database.child('matches/${widget.matchId}/playerStatus/${widget.playerId}').set('offline');
  }

  void listenToScoreUpdates() {
    final scoreRef = _database.child('matches/${widget.matchId}/scores');

    final myId = widget.playerId;
    final opponentId = widget.isPlayer1 ? 'player2' : 'player1';

    scoreRef.onValue.listen((event) {
      final data = event.snapshot.value;
      ////print('📥 Raw score data from Firebase: $data');

      if (data is Map) {
        setState(() {
          if (widget.isPlayer1) {
            myScore = data['player1'] ?? 0;
            opponentScore = data['player2'] ?? 0;
          } else {
            myScore = data['player2'] ?? 0;
            opponentScore = data['player1'] ?? 0;
          }

          ////print('✅ myScore = $myScore, opponentScore = $opponentScore');
        });
      }
    });
  }



  // ............. Chunk 5 LISTEN TO QUESTION INDEX .............
  // ............. Chunk 5 LISTEN TO QUESTION INDEX .............
  void listenToCurrentQuestionIndex() {
    DatabaseReference currentQuestionIndexRef = _database
        .child('matches/${widget.matchId}/currentQuestionIndex');

    questionIndexSubscription = currentQuestionIndexRef.onValue.listen((DatabaseEvent event) {
      int index = (event.snapshot.value ?? 0) as int;

      print('🚀 DEBUG: currentQuestionIndex changed to: $index'); // Debug print

      setState(() {
        currentQuestionIndex = index;
        questionLocked = false;
        feedbackMessage = '';
        isMovingToNextQuestion = false; // Ensure this is false here
        selectedOption = null;
        shuffledOptions = [];
        bothWrong = false;
        revealCorrectAnswerOnOpponentWin = false; // Reset this flag
        showCorrectAnswerOnSelfWrong = false; // Reset this flag
        showCorrectAnswer = false; // Ensure this is reset for new question
      });

      // Re-subscribe to answers for the new question index
      listenToAnswers();

      // Reset and start progress timer for the new question
      _progressController.reset();
      _progressController.forward();

      // Cancel any existing auto-skip timer and set a new one
      autoSkipTimer?.cancel();
      autoSkipTimer = Timer(const Duration(seconds: 18), () async {
        print('⏰ DEBUG TIMER: Timer for Q${currentQuestionIndex + 1} expired.');
        DataSnapshot snapshot = await _database.child('matches/${widget.matchId}/answers/$currentQuestionIndex/firstAnswerBy').get();
        String firstAnswerByAtTimer = snapshot.value as String? ?? '';
        print('🔍 DEBUG TIMER: firstAnswerBy at timer expiry: "$firstAnswerByAtTimer"');

        // If no one answered correctly by the timer's end
        if (snapshot.value == null || firstAnswerByAtTimer.isEmpty) {
          print('✅ DEBUG TIMER: No firstAnswerBy found. Setting to "none" and moving.');
          await _database.child(
              'matches/${widget.matchId}/answers/$currentQuestionIndex').update(
              {
                'firstAnswerBy': 'none', // Set to 'none' if no one answered
                'isCorrect': false,
              });

          setState(() {
            questionLocked = true; // Lock after timer expiry
            // feedbackMessage will be updated by listenToAnswers when firstAnswerBy becomes 'none'
            showCorrectAnswer = true; // This will turn the correct answer green
          });

          // Wait a short delay to display feedback/correct answer
          await Future.delayed(const Duration(milliseconds: 500));

          if (currentQuestionIndex + 1 >= totalQuestions) {
            print("🛑 DEBUG GAME OVER: Timer expired, showing results.");
            await _database.child('matches/${widget.matchId}').update({
              'gameOver': true,
            });
            showResults();
          } else {
            if (!isMovingToNextQuestion) {
              print("🚀 DEBUG TIMER: Calling _moveToNextQuestion from timer expiry.");
              _moveToNextQuestion();
            }
          }
        } else {
          print('⚠️ DEBUG TIMER: firstAnswerBy was NOT null/empty: "$firstAnswerByAtTimer". Not forcing move.');
          // This 'else' block means a correct answer or 'both wrong' (via 'none') was already
          // submitted before the timer fully expired. The progression should have been
          // handled by the 'submitAnswer' or 'listenToAnswers' logic.
        }
      });
    });
  }
  // ............. Chunk 6 LISTEN TO ANSWERS .............
  void listenToAnswers() {
    answerSubscription?.cancel();

    DatabaseReference answerRef = _database
        .child('matches/${widget.matchId}/answers/$currentQuestionIndex');

    answerSubscription = answerRef.onValue.listen((DatabaseEvent event) async {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? answerData = event.snapshot.value as Map<dynamic, dynamic>?;

        if (answerData == null) {
          return; // No data, just return
        }

        String firstAnswerBy = answerData['firstAnswerBy'] as String? ?? '';
        bool firstAnswerWasCorrect = answerData['isCorrect'] as bool? ?? false;
        Map<dynamic, dynamic>? wrongAnswersMap = answerData['wrongAnswers'] as Map<dynamic, dynamic>?;

        //print('DEBUG listenToAnswers: My ID: ${widget.playerId}, First Answered By: "$firstAnswerBy", Was Correct: $firstAnswerWasCorrect, Raw Data: $answerData');

        setState(() {
          //questionLocked = true; // Always lock once an answer is registered
          bothWrong = false; // Reset for clarity
          revealCorrectAnswerOnOpponentWin = false; // Reset for clarity
          showCorrectAnswerOnSelfWrong = false; // Reset for clarity
          showCorrectAnswer = false; // Reset for clarity
          feedbackMessage = ''; // Clear previous feedback

          if (firstAnswerBy.isNotEmpty) {
            // A definite answer has been registered (either a player ID or 'none')
            if (firstAnswerBy == 'none') {
              bothWrong = true; // For "Both wrong" case, will be set by submitAnswer or timer.
              feedbackMessage = 'No one answered correctly.'; // More general message for 'none'
              showCorrectAnswer = true; // This ensures green highlight for correct answer
            } else {
              // A player answered correctly
              feedbackMessage = (firstAnswerBy == widget.playerId)
                  ? 'You answered first!'
                  : 'Opponent answered first.';
              if (firstAnswerBy != widget.playerId && firstAnswerWasCorrect) {
                revealCorrectAnswerOnOpponentWin = true;
              }
            }
          } else if (wrongAnswersMap != null && wrongAnswersMap.containsKey(widget.playerId) && !bothWrong) {
            // NEW: This is for the player who just answered wrong, waiting for opponent or timer
            feedbackMessage = 'Waiting for opponent...';
            // showCorrectAnswerOnSelfWrong should already be set in submitAnswer for red/green on self
          }
          // If opponent answered wrong, this listener will also trigger for this device.
          // The 'bothWrong' logic in submitAnswer will then set firstAnswerBy to 'none' and trigger above block.
        });

        //_progressController.stop();
        //autoSkipTimer?.cancel();
      }
    });
  }
  // ............. Chunk 7 LISTEN TO PLAYER STATUS .............
  void listenToPlayerStatus() async {
    DataSnapshot matchSnapshot = await _database.child('matches/${widget.matchId}').get();

    String player1Id = matchSnapshot.child('player1Id').value as String;
    String player2Id = matchSnapshot.child('player2Id').value as String;

    opponentId = (widget.playerId == player1Id) ? player2Id : player1Id;

    DatabaseReference playerStatusRef =
    _database.child('matches/${widget.matchId}/playerStatus/$opponentId');

    playerStatusSubscription = playerStatusRef.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.value == 'offline' && !opponentLeft && !gameOver) {
        opponentLeft = true;
        showOpponentLeftResults();
      }
    });
  }

  // ............. Chunk 8 SUBMIT ANSWER .............
  void submitAnswer(String selectedAnswer) async {
    if (questionLocked) return;

    setState(() {
      questionLocked = true;
      selectedOption = selectedAnswer;
    });

    String correctAnswer = questions[currentQuestionIndex]['answer'];

    if (selectedAnswer == correctAnswer) {
      audioPlayer.play(AssetSource('sounds/correct.mp3'));
    } else {
      audioPlayer.play(AssetSource('sounds/wrong.mp3'));
    }

    //await Future.delayed(const Duration(milliseconds: 700));

    //if (questionLocked) return;

    DatabaseReference answerRef = _database
        .child('matches/${widget.matchId}/answers/$currentQuestionIndex');

    DataSnapshot snapshot = await answerRef.child('firstAnswerBy').get();

    if (snapshot.value != null) {
      return;
    }

    if (selectedAnswer == correctAnswer) {
      //print('DEBUG:📥📥 Player ${widget.playerId} submitting answer. Selected: $selectedAnswer, Correct: $correctAnswer');
      await answerRef.set({
        'firstAnswerBy': widget.playerId,
        'isCorrect': true,
      });

      final playerKey = widget.isPlayer1 ? 'player1' : 'player2';

      await _database
          .child('matches/${widget.matchId}/scores/$playerKey')
          .runTransaction((value) {
        int currentScore = (value ?? 0) as int;
        return Transaction.success(currentScore + 1);
      });


      _progressController.stop();
      autoSkipTimer?.cancel();

      await Future.delayed(const Duration(seconds: 1));
      if (!isMovingToNextQuestion) {
        _moveToNextQuestion();
      }

    }  else {
  // ❌ Incorrect answer

  // Track mistake
  final currentQuestion = Map<String, dynamic>.from(questions[currentQuestionIndex]);
  await MistakeTrackerService.trackMistake(
  questionData: currentQuestion,
  userId: widget.playerId,
  );

  // Add to wrongAnswers as a map (safer than list)
  await answerRef.child('wrongAnswers/${widget.playerId}').set(true);

  setState(() {
  questionLocked = true;
  showCorrectAnswerOnSelfWrong = true;
  });

  // Check if both players answered wrong
  final wrongData = await answerRef.child('wrongAnswers').get();
  if (wrongData.exists && wrongData.children.length >= 2) {
  final handledSnapshot = await answerRef.child('handledBy').get();

  if (handledSnapshot.value == null) {
  // This player handles the transition
  await answerRef.update({
  'firstAnswerBy': 'none',
  'isCorrect': false,
  'handledBy': widget.playerId,
  });

  setState(() {
  feedbackMessage = 'Both marked incorrect.';
  showCorrectAnswer = true;
  });

  _progressController.stop();
  autoSkipTimer?.cancel();


  await Future.delayed(Duration(seconds: 1));

  if (currentQuestionIndex + 1 >= totalQuestions) {
    await _database.child('matches/${widget.matchId}').update({
      'gameOver': true,
    });
  }else{

  if (!isMovingToNextQuestion) {
    //print("DEBUG:  ⚠️ Calling _moveToNextQuestion from submitAnswer (both wrong)");
  _moveToNextQuestion();
  }
  }
  }
  }







    }
  }





  // ............. Chunk 9 MOVE TO NEXT QUESTION .............
  // ............. Chunk 9 MOVE TO NEXT QUESTION .............
  void _moveToNextQuestion() {
    print('🏃 DEBUG MOVE: Entering _moveToNextQuestion(). isMovingToNextQuestion: $isMovingToNextQuestion'); // Debug print

    if (isMovingToNextQuestion) {
      print('🚫 DEBUG MOVE: Already moving to next question. Aborting.'); // Debug print
      return;
    }
    isMovingToNextQuestion = true; // Set flag early

    answerSubscription?.cancel();
    autoSkipTimer?.cancel();
    print('🗑️ DEBUG MOVE: Subscriptions and timers cancelled.'); // Debug print


    _database.child('matches/${widget.matchId}/currentQuestionIndex')
        .get()
        .then((snapshot) async { // Added async here for consistency
      int index = (snapshot.value ?? 0) as int;
      print('🎯 DEBUG MOVE: Current index from DB: $index'); // Debug print

      if (index + 1 >= totalQuestions) {
        print('🛑 DEBUG MOVE: Game Over condition met. Calling showResults().'); // Debug print
        showResults();
      } else {
        print('✅ DEBUG MOVE: Updating currentQuestionIndex to ${index + 1} in Firebase.'); // Debug print
        await _database.child('matches/${widget.matchId}/currentQuestionIndex').set(index + 1);
      }
    }).catchError((error) {
      print('❌ DEBUG MOVE: Error getting currentQuestionIndex from DB: $error'); // Debug print
    });
    print('🚪 DEBUG MOVE: Exiting _moveToNextQuestion().'); // Debug print
  }

  void listenToGameOverFlag() {
    final gameOverRef = _database.child('matches/${widget.matchId}/gameOver');

    gameOverRef.onValue.listen((DatabaseEvent event) async {
      final value = event.snapshot.value;
      if (value == true && !gameOver) {
        gameOver = true;
        ////print("🛑 Game over flag received — showing results");

        DataSnapshot scoresSnapshot =
        await _database.child('matches/${widget.matchId}/scores').get();

        Map<dynamic, dynamic> scores = scoresSnapshot.value as Map<dynamic, dynamic>;

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => OnlineResultScreen(
                scores: scores,
                playerId: widget.playerId,
              ),
            ),
          );
        }
      }
    });
  }



  // ............. Chunk 10 SHOW RESULTS .............
  void showResults() async {
    gameOver = true;
    ////print("🚨 showResults triggered");

    await _database.child('matches/${widget.matchId}').update({
      'gameOver': true,
    });

    DataSnapshot scoresSnapshot =
    await _database.child('matches/${widget.matchId}/scores').get();

    Map<dynamic, dynamic> scores = scoresSnapshot.value as Map<dynamic, dynamic>;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => OnlineResultScreen(
          scores: scores,
          playerId: widget.playerId,
        ),
      ),
    );
  }

  // ............. Chunk 11 SHOW OPPONENT LEFT RESULTS .............
  void showOpponentLeftResults() async {
    gameOver = true;
    ////print("🚨 showOpponentLeftResults triggered");
    await _database
        .child('matches/${widget.matchId}/scores/${widget.playerId}')
        .set(totalQuestions);  // give full score
    await _database
        .child('matches/${widget.matchId}/scores/$opponentId')
        .set(0);

    await _database.child('matches/${widget.matchId}').update({
      'gameOver': true,
      'opponentLeft': true, // Optional, for debugging/logging
    });

    Map<dynamic, dynamic> scores = {
      widget.playerId: totalQuestions,
      opponentId: 0,
    };

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => OnlineResultScreen(
          scores: scores,
          playerId: widget.playerId,
        ),
      ),
    );
  }

  // ............. Chunk 12 OPTION COLOR LOGIC .............
  Color getOptionColor(String option) {
    String correctAnswer = questions[currentQuestionIndex]['answer'];

    if (!questionLocked && selectedOption == null) {
      return Colors.black;
    }

    // ✅ If this is the user's wrong selected option
    if (option == selectedOption && option != correctAnswer) {
      return Colors.red;
    }

    // ✅ If this is the correct answer and should be revealed
    if ((option == correctAnswer) && (isCorrect || showCorrectAnswer || revealCorrectAnswerOnOpponentWin || showCorrectAnswerOnSelfWrong)) { // ADD showCorrectAnswerOnSelfWrong
      return Colors.green;
    }

    return Colors.black;
  }


  // ............. Chunk 13 BUILD WIDGET TREE .............
  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!isLoading && questions.isNotEmpty) {
      //////print("🖥️ Step 7: Displaying question ${currentQuestionIndex + 1}/${questions.length}");
    }

    Map<String, dynamic> currentQuestion = Map<String, dynamic>.from(questions[currentQuestionIndex]);

    return Scaffold(
      backgroundColor: Colors.black,
      //appBar: AppBar(
        //title: Text('Question ${currentQuestionIndex + 1} of $totalQuestions'),
      //),
      body: SafeArea(
        child:Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Color(0xFFFFA500), width: 2), // Cyan border
                      color: const Color(0x33FFA500),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'YOU:  ',
                          style: TextStyle(
                            color: Color(0xFFFFA500),
                            fontSize: 20,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),

                        Text(
                          '$myScore',
                          style: const TextStyle(
                            color: Color(0xFFFFA500),
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Image.asset(
                    'assets/icon/bolt.png',
                    width: 36,
                    height: 49,
                  ),


                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    decoration: BoxDecoration(

                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Color(0xFFFFA500), width: 2), // Amber-Orange border
                      color: const Color(0x33FFA500),
                    ),
                    child: Row(
                      children: [
                        Text(
                        '$opponentScore',
                        style: const TextStyle(
                          color: Color(0xFFFFA500),
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                        const Text(
                          '  :RIVAL',
                          style: TextStyle(
                            color: Color(0xFFFFA500),
                            fontSize: 20,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),

                      ],
                    ),
                  ),
                ],
              )

            ),



            SizedBox(
              height: MediaQuery.of(context).size.height * 0.005, // 2% of screen height
            ),

            // Progress bar → 10 segmented bars
            Row(
              children: List.generate(totalQuestions, (index) {
                double value;
                if (index < currentQuestionIndex) {
                  value = 1;
                } else if (index == currentQuestionIndex) {
                  value = _progressAnimation.value;
                } else {
                  value = 0;
                }
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: LinearProgressIndicator(
                      value: value,
                      backgroundColor: Colors.grey.shade800,
                      color: Color(0xFFFFA500),
                      minHeight: 6,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Q${currentQuestionIndex + 1} of $totalQuestions',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            //const SizedBox(height: 24),



        Html(
          data: currentQuestion['question'] ?? '⚠️ null',
              style: {
                "body": Style(
                  fontSize: FontSize(18),
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                  fontFamily: GoogleFonts.poppins().fontFamily,
                ),
              },
            ),

            if (currentQuestion['image'] != null &&
                currentQuestion['image'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Center(
                  child: Image.asset(
                    currentQuestion['image'],
                    height: MediaQuery.of(context).size.height * 0.22,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

            //const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    ...(currentQuestion['options'] as List)
                        .where((opt) => opt != null && opt is String)
                        .map((option) {
                      return FormulaOptionButton(
                        text: option,
                        onPressed: questionLocked
                            ? () {}
                            : () async {
                          final correctAnswer = questions[currentQuestionIndex]['answer'];
                          setState(() {
                            selectedOption = option;
                            isCorrect = (option == correctAnswer);
                          });
                          submitAnswer(option);
                        },
                        color: getOptionColor(option),
                      );
                    }).toList(),

                    if (winnerMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          winnerMessage!,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                   // const SizedBox(height: 24),

                    Text(
                      feedbackMessage,
                      style: const TextStyle(fontSize: 20, color: Colors.blue),
                    ),
                  ],
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
