import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
class EnvConfig {
  EnvConfig._();
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
      if (kDebugMode) {
        print('[EnvConfig] ✓ Loaded .env file');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[EnvConfig] ⚠ No .env file found (using defaults)');
      }
    }
  }
}