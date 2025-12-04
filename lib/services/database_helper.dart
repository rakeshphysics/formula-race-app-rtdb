import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:formularacing/models/practice_attempt.dart';

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
      version: 1,
      onCreate: _onCreate, // This runs the first time the database is created.
    );
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
        timestamp INTEGER NOT NULL -- Storing date as milliseconds since epoch
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

// We will add methods here later to insert, query, and delete data.
// For example: Future<void> addAttempt(...)
}