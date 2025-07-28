// lib/models/online_incorrect_answer_model.dart

class OnlineIncorrectAnswer {
  final String question;
  final String correctAnswer;
  final String? imagePath;
  final String userAnswer;
  final String opponentAnswer; // Could be correct or incorrect
  final String? tip;
  final String scenario; // e.g., 'user_wrong_opponent_wrong', 'user_wrong_opponent_correct', 'user_skipped', 'opponent_answered_first'

  OnlineIncorrectAnswer({
    required this.question,
    required this.correctAnswer,
    this.imagePath,
    required this.userAnswer,
    required this.opponentAnswer,
    this.tip,
    required this.scenario,
  });
}