import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:formularacing/models/practice_attempt.dart';
import 'package:formularacing/models/game_performance.dart';

class DatabaseHelper {
  // A private constructor. This prevents direct instantiation of the class.
  DatabaseHelper._privateConstructor();

  // The single, static instance of this class.
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // A private, nullable Database object.
  static Database? _database;

  // A getter for the database. If it's null, it initializes it.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // This method initializes the database.
  // It gets the path and opens the database, creating it if it doesn't exist.
  _initDatabase() async {
    String path = join(await getDatabasesPath(), 'student_practice.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // This method is called when the database version is increased.
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // We are upgrading from version 1 to 2, so add the new column.
      await db.execute('''
      ALTER TABLE practice_attempts ADD COLUMN bamboo_counted INTEGER NOT NULL DEFAULT 0
    ''');
    }
  }

  // This method defines the table structure.
  // It's called only when the database is created for the first time.
  Future _onCreate(Database db, int version) async {
    await db.execute('''
  CREATE TABLE practice_attempts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    userId TEXT NOT NULL,
    questionId TEXT NOT NULL,
    wasCorrect INTEGER NOT NULL, -- 0 for false, 1 for true
    topic TEXT NOT NULL,
    timestamp INTEGER NOT NULL, -- Storing date as milliseconds since epoch
    bamboo_counted INTEGER NOT NULL DEFAULT 0
  )
''');
  }

  Future<void> addAttempt(PracticeAttempt attempt) async {
    final db = await instance.database;

    // The `insert` method adds a new row to the table.
    // `conflictAlgorithm.replace` means if we ever insert an attempt
    // with the same primary key, it will be replaced. This is a safe default.
    await db.insert(
      'practice_attempts',
      attempt.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<PracticeAttempt>> getMistakes() async {
    final db = await instance.database;

    // Query the table for all attempts where wasCorrect is 0 (false).
    // Order them by the most recent first.
    final List<Map<String, dynamic>> maps = await db.query(
      'practice_attempts',
      where: 'wasCorrect = ?',
      whereArgs: [0], // 0 represents false
      orderBy: 'timestamp DESC',
    );

    // Convert the List<Map<String, dynamic>> into a List<PracticeAttempt>.
    return List.generate(maps.length, (i) {
      return PracticeAttempt(
        id: maps[i]['id'],
        userId: maps[i]['userId'],
        questionId: maps[i]['questionId'],
        wasCorrect: maps[i]['wasCorrect'] == 1, // Convert integer back to bool
        topic: maps[i]['topic'],
        timestamp: DateTime.fromMillisecondsSinceEpoch(maps[i]['timestamp']), // Convert int to DateTime
      );
    });
  }


  // lib/services/database_helper.dart

// ... (add this after your getMistakes() method)

  /// Fetches all practice attempts within a specific time range.
  /// This is a flexible method we can use to get data for "today", "yesterday", "this week", etc.
  Future<List<PracticeAttempt>> getAttemptsInDateRange(DateTime start, DateTime end) async {
    final db = await instance.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'practice_attempts',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'timestamp DESC',
    );

    // Re-use the same conversion logic from getMistakes()
    return List.generate(maps.length, (i) {
      return PracticeAttempt(
        id: maps[i]['id'],
        userId: maps[i]['userId'],
        questionId: maps[i]['questionId'],
        wasCorrect: maps[i]['wasCorrect'] == 1,
        topic: maps[i]['topic'],
        timestamp: DateTime.fromMillisecondsSinceEpoch(maps[i]['timestamp']),
      );
    });
  }

// lib/services/database_helper.dart

// ... (inside the DatabaseHelper class)

  // TEMPORARY METHOD FOR DEBUGGING: Prints all attempts in the database.
  // Future<void> printAllAttempts() async {
  //   final db = await instance.database;
  //   final List<Map<String, dynamic>> maps = await db.query('practice_attempts');
  //
  //   if (maps.isEmpty) {
  //     print('--- DATABASE IS EMPTY ---');
  //     return;
  //   }
  //
  //   print('--- PRINTING ALL DATABASE ATTEMPTS ---');
  //   for (var map in maps) {
  //     print('  ID: ${map['id']}, '
  //         'UserID: ${map['userId']}, '
  //         'QuestionID: ${map['questionId']}, '
  //         'Correct: ${map['wasCorrect'] == 1}, ' // Convert 1/0 back to true/false
  //         'Topic: ${map['topic']}, '
  //         'Timestamp: ${DateTime.fromMillisecondsSinceEpoch(map['timestamp'])}');
  //   }
  //   print('--- END OF DATABASE ATTEMPTS ---');
  // }

 // End of class
  /// Counts all correct answers that have not yet been counted for bamboos.
  Future<int> countUncountedCorrectAnswers() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) FROM practice_attempts WHERE wasCorrect = 1 AND bamboo_counted = 0'
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Marks all uncounted attempts as counted.
  Future<void> spendOneBamboo() async {
    final db = await instance.database;
    // Find one row that is a correct answer and hasn't been counted,
    // then update its bamboo_counted status to 1.
    await db.rawUpdate('''
    UPDATE practice_attempts
    SET bamboo_counted = 1
    WHERE id = (
      SELECT id FROM practice_attempts
      WHERE wasCorrect = 1 AND bamboo_counted = 0
      LIMIT 1
    )
  ''');
  }

  // lib/services/database_helper.dart

  Future<Map<String, dynamic>?> getLastGameDetails() async {
    final db = await instance.database;

    // 1. Find the timestamp of the most recent attempt.
    final List<Map<String, dynamic>> lastAttemptResult = await db.query(
      'practice_attempts',
      columns: ['timestamp'],
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (lastAttemptResult.isEmpty) {
      return null; // No attempts ever made.
    }

    final int lastTimestamp = lastAttemptResult.first['timestamp'] as int;

    // 2. Define a "session" as all attempts within a 5-minute window of the last one.
    // This groups all questions from the last game together.
    final int sessionThreshold = Duration(minutes: 5).inMilliseconds;
    final int sessionStartTime = lastTimestamp - sessionThreshold;

    // 3. Get all attempts from that last session.
    final List<Map<String, dynamic>> gameAttempts = await db.query(
      'practice_attempts',
      where: 'timestamp >= ?',
      whereArgs: [sessionStartTime],
      orderBy: 'timestamp DESC',
    );

    if (gameAttempts.isEmpty) {
      return null; // Should not happen, but it's a safe check.
    }

    // 4. Calculate stats for that game session.
    int correctCount = 0;
    int totalQuestions = gameAttempts.length;
    Set<String> topics = {}; // Use a Set to store unique topics.

    for (var attempt in gameAttempts) {
      if (attempt['wasCorrect'] == 1) {
        correctCount++;
      }
      topics.add(attempt['topic'] as String);
    }

    // 5. Return a map with the game's summary.
    return {
      'correct_count': correctCount,
      'total_questions': totalQuestions,
      'topics': topics.toList(), // Convert the Set of topics to a List.
      'timestamp': lastTimestamp, // The timestamp of the very last answer.
    };
  }

// lib/services/database_helper.dart

  // Future<Map<String, dynamic>?> getLastGameDetails() async {
  //   final db = await instance.database;
  //
  //   // TWEAK: Instead of using a time window, we will now fetch the last 10 attempts directly.
  //   // This simplifies the function significantly.
  //
  //   // 1. Get the last 10 attempts from the database.
  //   final List<Map<String, dynamic>> gameAttempts = await db.query(
  //     'practice_attempts',
  //     orderBy: 'timestamp DESC', // Get the most recent ones first
  //     limit: 10,                 // Limit the result to 10
  //   );
  //
  //   if (gameAttempts.isEmpty) {
  //     return null; // No attempts ever made.
  //   }
  //
  //   // 2. The timestamp of the last game is from the first item in our sorted list.
  //   final int lastTimestamp = gameAttempts.first['timestamp'] as int;
  //
  //
  //   // 3. Calculate stats for that game session.
  //   int correctCount = 0;
  //   int totalQuestions = gameAttempts.length; // This will be 10 or less
  //   Set<String> topics = {}; // Use a Set to store unique topics.
  //
  //   for (var attempt in gameAttempts) {
  //     if (attempt['wasCorrect'] == 1) {
  //       correctCount++;
  //     }
  //     topics.add(attempt['topic'] as String);
  //   }
  //
  //   // 4. Return a map with the game's summary.
  //   return {
  //     'correct_count': correctCount,
  //     'total_questions': totalQuestions,
  //     'topics': topics.toList(), // Convert the Set of topics to a List.
  //     'timestamp': lastTimestamp, // The timestamp of the very last answer.
  //   };
  // }
  // --- New function to get performance of recent games ---
  Future<List<GamePerformance>> getPerformanceOverLast5Games() async {
    final db = await instance.database;

    // Step 1: Get the timestamps of the last 5 distinct game sessions.
    // A "game session" is defined by a group of questions answered at the exact same time.
    final List<Map<String, dynamic>> distinctTimestamps = await db.rawQuery('''
      SELECT DISTINCT timestamp
      FROM practice_attempts
      ORDER BY timestamp DESC
      LIMIT 5
    ''');

    if (distinctTimestamps.isEmpty) {
      return [];
    }

    final List<GamePerformance> performanceList = [];

    // Step 2: For each of those 5 timestamps, calculate the score.
    for (var row in distinctTimestamps) {
      final int timestamp = row['timestamp'];

      // Get total questions for this timestamp
      final totalResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM practice_attempts WHERE timestamp = ?',
        [timestamp],
      );
      final int totalQuestions = totalResult.first['count'] as int;

      // Get correct questions for this timestamp
      final correctResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM practice_attempts WHERE timestamp = ? AND wasCorrect = 1',
        [timestamp],
      );
      final int correctQuestions = correctResult.first['count'] as int;

      if (totalQuestions > 0) {
        final double score = correctQuestions / totalQuestions;
        performanceList.add(
          GamePerformance(
            score: score,
            timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
          ),
        );
      }
    }

    // The list might be in descending order from the query, so let's reverse it
    // to have the oldest of the 5 games first.
    return performanceList.reversed.toList();
  }


}