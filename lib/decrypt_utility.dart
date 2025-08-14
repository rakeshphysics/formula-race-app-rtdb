// lib/decrypt_utility.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:encrypt/encrypt.dart';

// IMPORTANT: Replace these with the key and IV printed from your encryption script!
final key = Key.fromBase64('Iab5jYKlQgdOQYahIR3ufnX6M21LHuAlZw76xXhM9Tc=');
final iv = IV.fromBase64('xjToKjJYezgw5We19wY9Ow==');
final encrypter = Encrypter(AES(key));

Future<String> decryptFile(String filePath) async {
  try {
    final encryptedBase64 = await rootBundle.loadString(filePath);
    final encrypted = Encrypted.fromBase64(encryptedBase64);
    final decrypted = encrypter.decrypt(encrypted, iv: iv);
    return decrypted;
  } catch (e) {
    print('Error decrypting file: $filePath -> $e');
    return '{}'; // Return empty JSON on error
  }
}