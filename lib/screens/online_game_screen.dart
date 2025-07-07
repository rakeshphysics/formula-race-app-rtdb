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
  print("📦 Step 1: Loading JSON from assets...");
  final jsonString = await rootBundle.loadString('assets/formulas/full_syllabus_online_play.json');
  print("✅ Step 2: JSON loaded. Length of string: ${jsonString.length}");

  final decoded = jsonDecode(jsonString);
  print("🔍 Step 3: Decoded JSON length: ${decoded.length}");

  return decoded;
}
// .............END................. Load Qns from combined JSON..........................

// .............START................. Fn loads 10Qns from shared seed with given conditions........................
Future<List<Map<String, dynamic>>> getRandomQuestions(int seed) async {
  final allQuestions = await loadQuestionsFromAssets();
  final random = Random(seed);
  print("🎲 Step 4: Shuffling questions with seed: $seed");

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

  print("📦 Final selected questions (full data):");
  for (var q in selected) {
    print(jsonEncode(q));
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
  final int totalQuestions = 10;  // ← control number of questions and progress bars

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
        print("📋 Step 6: Questions assigned. Length = ${qns.length}");
      } else {
        print('Room not found: ${widget.matchId}');
      }
    } catch (e) {
      print('Error fetching room seed: $e');
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
      print('📥 Raw score data from Firebase: $data');

      if (data is Map) {
        setState(() {
          if (widget.isPlayer1) {
            myScore = data['player1'] ?? 0;
            opponentScore = data['player2'] ?? 0;
          } else {
            myScore = data['player2'] ?? 0;
            opponentScore = data['player1'] ?? 0;
          }

          print('✅ myScore = $myScore, opponentScore = $opponentScore');
        });
      }
    });
  }



  // ............. Chunk 5 LISTEN TO QUESTION INDEX .............
  void listenToCurrentQuestionIndex() {
    DatabaseReference currentQuestionIndexRef = _database
        .child('matches/${widget.matchId}/currentQuestionIndex');

    questionIndexSubscription = currentQuestionIndexRef.onValue.listen((DatabaseEvent event) {
      int index = (event.snapshot.value ?? 0) as int;

      setState(() {
        currentQuestionIndex = index;
        questionLocked = false;
        feedbackMessage = '';
        isMovingToNextQuestion = false;
        selectedOption = null;
      shuffledOptions = [];

        bothWrong = false;
      });

      listenToAnswers();


      _progressController.reset();
      _progressController.forward();

      autoSkipTimer?.cancel();
      autoSkipTimer = Timer(const Duration(seconds: 18), () async {
        DataSnapshot snapshot = await _database.child('matches/${widget.matchId}/answers/$currentQuestionIndex/firstAnswerBy').get();
        if (snapshot.value == null) {
          await _database.child('matches/${widget.matchId}/answers/$currentQuestionIndex').update({
            'firstAnswerBy': 'none',
            'isCorrect': false,
          });

          setState(() {
            questionLocked = true;
            feedbackMessage = "Time's up! No one answered.";
          });

          // Wait 0.5 sec, then show correct option in green
          await Future.delayed(const Duration(milliseconds: 500));
          setState(() {
            showCorrectAnswer = true;
          });

          // Wait another 0.5 sec, then move to next question
          await Future.delayed(const Duration(milliseconds: 500));
          if (!isMovingToNextQuestion) {
           // _moveToNextQuestion();
          }
        }

      });
    });
  }

  // ............. Chunk 6 LISTEN TO ANSWERS .............
  void listenToAnswers() {
    answerSubscription?.cancel();

    DatabaseReference answerRef = _database
        .child('matches/${widget.matchId}/answers/$currentQuestionIndex/firstAnswerBy');

    answerSubscription = answerRef.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        String firstAnswerBy = event.snapshot.value as String;

        if (firstAnswerBy == 'none') {
          setState(() {
            questionLocked = true;
            bothWrong = true;
            feedbackMessage = 'Both marked incorrect.';
          });

          _progressController.stop();
          autoSkipTimer?.cancel();

          Timer(const Duration(seconds: 1), () {
            if (!isMovingToNextQuestion) {
              //_moveToNextQuestion();
            }
          });

          return;
        }

        setState(() {
          questionLocked = true;
          feedbackMessage = (firstAnswerBy == widget.playerId)
              ? 'You answered first!'
              : 'Opponent answered first.';
        });

        _progressController.stop();
        autoSkipTimer?.cancel();

        Timer(const Duration(seconds: 1), () {
          if (!isMovingToNextQuestion) {
            //_moveToNextQuestion();
          }
        });
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

    await Future.delayed(const Duration(milliseconds: 700));

    //if (questionLocked) return;

    DatabaseReference answerRef = _database
        .child('matches/${widget.matchId}/answers/$currentQuestionIndex');

    DataSnapshot snapshot = await answerRef.child('firstAnswerBy').get();

    if (snapshot.value != null) {
      return;
    }

    if (selectedAnswer == correctAnswer) {
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

      await Future.delayed(const Duration(seconds: 3));
      if (!isMovingToNextQuestion) {
        _moveToNextQuestion();
      }

    } else {
      DataSnapshot wrongAnswersSnapshot = await answerRef.child('wrongAnswers').get();

      List<dynamic> wrongAnswers = [];
      if (wrongAnswersSnapshot.value != null) {
        wrongAnswers = List<dynamic>.from(wrongAnswersSnapshot.value as List<dynamic>);
      }

      if (!wrongAnswers.contains(widget.playerId)) {
        wrongAnswers.add(widget.playerId);
        await answerRef.child('wrongAnswers').set(wrongAnswers);
        final currentQuestion = Map<String, dynamic>.from(questions[currentQuestionIndex]);
        await MistakeTrackerService.trackMistake(
          questionData: currentQuestion,
          userId: widget.playerId,
        );
      }

      setState(() {
        //feedbackMessage = 'Wrong! Try again.';
        questionLocked = true;
      });

      if (wrongAnswers.length >= 2) {
        DataSnapshot handledSnapshot = await answerRef.child('handledBy').get();

        // Only one player proceeds
        if (handledSnapshot.value == null) {
          // This player becomes the handler
          await answerRef.update({
            'firstAnswerBy': 'none',
            'isCorrect': false,
            'handledBy': widget.playerId, // lock it
          });

          setState(() {
            questionLocked = true;
            feedbackMessage = 'Both marked incorrect.';
            showCorrectAnswer = true;
          });

          _progressController.stop();
          autoSkipTimer?.cancel();

          await Future.delayed(Duration(seconds: 1));
          if (!isMovingToNextQuestion) {
            _moveToNextQuestion();
          }
        }
      }



      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          showCorrectAnswer = true;
        });
      });
    }
  }





  // ............. Chunk 9 MOVE TO NEXT QUESTION .............
  void _moveToNextQuestion() {
    listenToAnswers();
    if (isMovingToNextQuestion) return;
    isMovingToNextQuestion = true;

    answerSubscription?.cancel();
    autoSkipTimer?.cancel();

    _database.child('matches/${widget.matchId}/currentQuestionIndex')
        .get()
        .then((snapshot) {
      int index = (snapshot.value ?? 0) as int;
      if (index + 1 >= totalQuestions) {
        showResults();
      } else {
        _database.child('matches/${widget.matchId}/currentQuestionIndex').set(index + 1);
      }
    });
  }

  // ............. Chunk 10 SHOW RESULTS .............
  void showResults() async {
    gameOver = true;
    print("🚨 showResults triggered");
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
    print("🚨 showOpponentLeftResults triggered");
    await _database
        .child('matches/${widget.matchId}/scores/${widget.playerId}')
        .set(totalQuestions);  // give full score
    await _database
        .child('matches/${widget.matchId}/scores/$opponentId')
        .set(0);

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
    if ((option == correctAnswer) && (isCorrect || showCorrectAnswer)) {
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
      //print("🖥️ Step 7: Displaying question ${currentQuestionIndex + 1}/${questions.length}");
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
                  Text(
                    'YOU: $myScore POINT${myScore == 1 ? '' : 'S'}',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'OPPONENT: $opponentScore POINT${opponentScore == 1 ? '' : 'S'}',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
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
            const SizedBox(height: 24),



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

            const SizedBox(height: 24),


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
                      //questionLocked = true;
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


            const SizedBox(height: 24),
            Text(
              feedbackMessage,
              style: const TextStyle(fontSize: 20, color: Colors.blue),
            ),
          ],
        ),
      ),
      ),
      );


  }
}
