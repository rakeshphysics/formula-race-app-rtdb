// lib/services/mistake_tracker_service.dart
// --------------------------------------------------
// Clean version — stores only question, options, answer
// Does not affect questions JSON (tags etc remain there)
// Used by SoloScreen, ClearMistakesScreen, AITrackerScreen
// --------------------------------------------------

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class MistakeTrackerService {
  // TRACK MISTAKE — add new mistake if not duplicate
  static Future<void> trackMistake({
    required String userId,
    required Map<String, dynamic> questionData,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/my_mistakes.json');

      List<Map<String, dynamic>> mistakes = [];
      if (await file.exists()) {
        final content = await file.readAsString();
        mistakes = List<Map<String, dynamic>>.from(jsonDecode(content));
      }

      // Prevent duplicates by question text
      if (!mistakes.any((m) => m['question'] == questionData['question'])) {
        mistakes.add(questionData);

        await file.writeAsString(jsonEncode(mistakes));
        print('✅ Mistake saved: "${questionData['question']}"');
        print('DEBUG: Full mistakes json = ${jsonEncode(mistakes)}');

      } else {
        print('⚠️ Mistake already exists: "${questionData['question']}"');
      }
    } catch (e) {
      print('❌ Error saving mistake: $e');
    }
  }

  // REMOVE MISTAKE — by question
  static Future<void> removeMistake(String questionText) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/my_mistakes.json');

      if (!await file.exists()) {
        print('⚠️ my_mistakes.json not found — nothing to remove.');
        return;
      }

      final content = await file.readAsString();
      List<Map<String, dynamic>> mistakes = List<Map<String, dynamic>>.from(jsonDecode(content));

      int beforeCount = mistakes.length;
      mistakes.removeWhere((m) => m['question'] == questionText);
      int afterCount = mistakes.length;

      await file.writeAsString(jsonEncode(mistakes));

      if (beforeCount != afterCount) {
        print('✅ Mistake removed: "$questionText"');
      } else {
        print('⚠️ Mistake not found in file: "$questionText"');
      }
    } catch (e) {
      print('❌ Error removing mistake: $e');
    }
  }

  // LOAD MISTAKES — return full list
  static Future<List<Map<String, dynamic>>> loadMistakesFromLocal() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/my_mistakes.json');

      if (await file.exists()) {
        final content = await file.readAsString();
        List<Map<String, dynamic>> mistakes = List<Map<String, dynamic>>.from(jsonDecode(content));
        return mistakes;
      } else {
        print('⚠️ No my_mistakes.json found — returning empty list.');
        return [];
      }
    } catch (e) {
      print('❌ Error loading mistakes: $e');
      return [];
    }
  }

  // PRINT ALL MISTAKES — for debug
  static Future<void> printAllMistakes() async {
    final mistakes = await loadMistakesFromLocal();
    print('--- Mistakes (${mistakes.length}) ---');
    for (var m in mistakes) {
      print('• ${m['question']}');
    }
  }

  // CLEAR ALL MISTAKES — optional (admin button)
  static Future<void> clearAllMistakes() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/my_mistakes.json');

      if (await file.exists()) {
        await file.delete();
        print('✅ All mistakes cleared — my_mistakes.json deleted.');
      } else {
        print('⚠️ No my_mistakes.json found — nothing to clear.');
      }
    } catch (e) {
      print('❌ Error clearing mistakes: $e');
    }
  }
}
