// lib/screens/online_game_screen.dart
// ----------------------------------------------------
// Online Play screen → consistent with Solo Play:
// - totalQuestions = 10
// - Progress bar → 10 segmented bars
// - Game stops after 10 questions
// - One constant to control everything
// - CHUNK FORMAT
// ----------------------------------------------------

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:audioplayers/audioplayers.dart';
import '../widgets/formula_option_button.dart';
import 'online_result_screen.dart';

// ............. Chunk 1 ONLINE GAME SCREEN WIDGET .............
class OnlineGameScreen extends StatefulWidget {
  final String matchId;
  final String playerId;

  const OnlineGameScreen({Key? key, required this.matchId, required this.playerId}) : super(key: key);

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

  List<String> shuffledOptions = [];
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  String? selectedOption;
  bool bothWrong = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(_progressController);

    loadQuestions();
    listenToCurrentQuestionIndex();
    setPlayerStatusOnline();
    listenToPlayerStatus();
  }

  @override
  void dispose() {
    answerSubscription?.cancel();
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

  // ............. Chunk 4 LOAD QUESTIONS .............
  void loadQuestions() async {
    DataSnapshot snapshot = await _database.child('matches/${widget.matchId}/questions').get();

    List<dynamic> allQuestions = snapshot.value as List<dynamic>;
    allQuestions.shuffle();

    setState(() {
      questions = allQuestions.take(totalQuestions).toList();
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
      shuffledOptions = [];
        bothWrong = false;
      });

      listenToAnswers();

      _progressController.reset();
      _progressController.forward();

      autoSkipTimer?.cancel();
      autoSkipTimer = Timer(const Duration(seconds: 10), () async {
        DataSnapshot snapshot = await _database.child('matches/${widget.matchId}/answers/$currentQuestionIndex/firstAnswerBy').get();
        if (snapshot.value == null) {
          await _database.child('matches/${widget.matchId}/answers/$currentQuestionIndex').update({
            'firstAnswerBy': 'none',
            'isCorrect': false,
          });
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
              _moveToNextQuestion();
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
            _moveToNextQuestion();
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
      selectedOption = selectedAnswer;
    });

    String correctAnswer = questions[currentQuestionIndex]['correctAnswer'];

    if (selectedAnswer == correctAnswer) {
      audioPlayer.play(AssetSource('sounds/correct.mp3'));
    } else {
      audioPlayer.play(AssetSource('sounds/wrong.mp3'));
    }

    await Future.delayed(const Duration(milliseconds: 700));

    if (questionLocked) return;

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

      await _database
          .child('matches/${widget.matchId}/scores/${widget.playerId}')
          .runTransaction((value) {
        int currentScore = (value ?? 0) as int;
        return Transaction.success(currentScore + 1);
      });
    } else {
      DataSnapshot wrongAnswersSnapshot = await answerRef.child('wrongAnswers').get();

      List<dynamic> wrongAnswers = [];
      if (wrongAnswersSnapshot.value != null) {
        wrongAnswers = List<dynamic>.from(wrongAnswersSnapshot.value as List<dynamic>);
      }

      if (!wrongAnswers.contains(widget.playerId)) {
        wrongAnswers.add(widget.playerId);
        await answerRef.child('wrongAnswers').set(wrongAnswers);
      }

      setState(() {
        feedbackMessage = 'Wrong! Try again.';
        questionLocked = true;
      });

      if (wrongAnswers.length >= 2) {
        await answerRef.update({
          'firstAnswerBy': 'none',
          'isCorrect': false,
        });
      }
    }
  }

  // ............. Chunk 9 MOVE TO NEXT QUESTION .............
  void _moveToNextQuestion() {
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
    String correctAnswer = questions[currentQuestionIndex]['correctAnswer'];

    if (!questionLocked && selectedOption == null) {
      return Colors.grey.shade800;
    }

    if (option == correctAnswer) {
      return Colors.green;
    } else if (option == selectedOption) {
      return Colors.red;
    } else {
      return Colors.grey.shade800;
    }
  }

  // ............. Chunk 13 BUILD WIDGET TREE .............
  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    Map<String, dynamic> currentQuestion = Map<String, dynamic>.from(questions[currentQuestionIndex]);

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${currentQuestionIndex + 1} of $totalQuestions'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
                      color: Colors.white,
                      minHeight: 6,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              'Question ${currentQuestionIndex + 1} of $totalQuestions',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            Text(
              currentQuestion['questionText'],
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 24),
            ...(currentQuestion['options'] as List<dynamic>).map((option) {
              return FormulaOptionButton(
                text: option,
                onPressed: questionLocked
                    ? () {}
                    : () {
                  submitAnswer(option);
                },
                color: getOptionColor(option),
              );
            }).toList(),
            const SizedBox(height: 24),
            Text(
              feedbackMessage,
              style: const TextStyle(fontSize: 20, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}
