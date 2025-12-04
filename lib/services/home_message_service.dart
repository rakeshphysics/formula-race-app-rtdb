// lib/services/home_message_service.dart

import 'dart:math';
import 'package:collection/collection.dart';
import 'package:formularacing/models/practice_attempt.dart';
import 'package:formularacing/services/database_helper.dart';

class HomeMessageService {
  HomeMessageService._privateConstructor() {
    _initialize();
  }
  static final HomeMessageService instance = HomeMessageService._privateConstructor();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Random _random = Random();
  String _lastMessage = '';

  // A list of functions that generate messages.
  // We'll try each one until we find a message to display.
  late final List<Future<String> Function(String)> _messageGenerators;

  factory HomeMessageService() {
    return instance;
  }

  void _initialize() {
    _messageGenerators = [
      _generateTodayPraiseMessage,
      _generateTodayEncouragementMessage,
      _generateYesterdayRecapMessage,
      _generateComebackMessage,
    ];
  }

  // --- Main public method ---
  Future<String> getHomePageMessage(String userId) async {
    final possibleMessages = <String>[];

    // 1. Gather all possible messages from all generators
    for (var generator in _messageGenerators) {
      final message = await generator(userId);
      if (message.isNotEmpty) {
        possibleMessages.add(message);
      }
    }

    // 2. Add generic messages to the list as fallbacks
    possibleMessages.addAll(_getGenericWelcomeMessages());

    // 3. Filter out the last message shown
    final uniqueMessages = possibleMessages.where((m) => m != _lastMessage).toList();

    String newMessage;
    if (uniqueMessages.isNotEmpty) {
      // 4. Pick a random message from the unique list
      newMessage = uniqueMessages[_random.nextInt(uniqueMessages.length)];
    } else if (possibleMessages.isNotEmpty) {
      // This happens if there's only one possible message and it's the same as the last one
      newMessage = possibleMessages.first;
    } else {
      // Absolute fallback
      newMessage = "Ready to start?";
    }

    // 5. Remember this new message for next time
    _lastMessage = newMessage;
    return newMessage;
  }

  // --- Message Generation Logic ---

  /// Praises the user for good work today.
  Future<String> _generateTodayPraiseMessage(String userId) async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final todaysAttempts = await _dbHelper.getAttemptsInDateRange(startOfToday, now);

    if (todaysAttempts.isEmpty) return '';

    final total = todaysAttempts.length;
    final correct = todaysAttempts.where((a) => a.wasCorrect).length;
    final accuracy = (correct / total) * 100;

    if (accuracy == 100 && total > 5) {
      return "Perfect streak! You've nailed all $total questions today. Amazing!";
    }
    if (total > 20) {
      return "Wow, $total questions today! Your dedication is impressive.";
    }
    if (accuracy > 80 && total > 10) {
      return "Great session! Over 80% accuracy on $total questions. You're getting it!";
    }
    return '';
  }

  /// Encourages the user based on today's mistakes.
  Future<String> _generateTodayEncouragementMessage(String userId) async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final todaysAttempts = await _dbHelper.getAttemptsInDateRange(startOfToday, now);

    final mistakes = todaysAttempts.where((a) => !a.wasCorrect).toList();
    if (mistakes.isEmpty) return '';

    final mostCommonMistakeTopic = groupBy(mistakes, (PracticeAttempt a) => a.topic)
        .entries
        .sortedBy<num>((e) => e.value.length)
        .lastOrNull;

    if (mostCommonMistakeTopic != null) {
      return "Mistakes in '${mostCommonMistakeTopic.key}' are just learning opportunities. Let's try again!";
    }
    return "Every mistake is a step forward. Don't give up!";
  }

  /// Gives a quick recap of yesterday's work.
  Future<String> _generateYesterdayRecapMessage(String userId) async {
    final now = DateTime.now();
    final startOfYesterday = DateTime(now.year, now.month, now.day - 1);
    final endOfYesterday = startOfYesterday.add(const Duration(days: 1));
    final yesterdaysAttempts = await _dbHelper.getAttemptsInDateRange(startOfYesterday, endOfYesterday);

    if (yesterdaysAttempts.isEmpty) return '';

    final total = yesterdaysAttempts.length;
    final mostPracticed = groupBy(yesterdaysAttempts, (PracticeAttempt a) => a.topic)
        .entries
        .sortedBy<num>((e) => e.value.length)
        .lastOrNull;

    if (mostPracticed != null && total > 5) {
      return "Yesterday you focused on ${mostPracticed.key}. Ready for round two?";
    }
    return '';
  }

  /// Encourages users who haven't practiced in a while.
  Future<String> _generateComebackMessage(String userId) async {
    final now = DateTime.now();
    final startOfYesterday = DateTime(now.year, now.month, now.day - 1);
    final allAttempts = await _dbHelper.getAttemptsInDateRange(DateTime(2020), startOfYesterday);

    if (allAttempts.isEmpty) {
      // This is a brand new user, so no comeback message needed.
      return '';
    }
    // If we get here, it means the user has past data but didn't play today or yesterday.
    return "It's been a little while! How about a quick practice session to warm up?";
  }

  /// Returns a random generic message for new users or as a fallback.
  /// Returns a list of generic messages.
  List<String> _getGenericWelcomeMessages() {
    return [
      "Ready to test your knowledge?",
      "Consistency is key. Let's solve some problems!",
      "Every question is a new opportunity to learn.",
      "Let's get started!",
    ];
  }
}