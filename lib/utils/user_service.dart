import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class UserService {
  static const String _key = 'userId';

  // Called at app start
  static Future<String> getOrCreateUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(_key);

    if (userId == null) {
      userId = const Uuid().v4();
      await prefs.setString(_key, userId);
    }

    return userId;
  }

  // Called if user sets a custom name
  static Future<void> setCustomUserId(String customId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, customId);
  }

  // Optional: fetch current saved ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }
}
