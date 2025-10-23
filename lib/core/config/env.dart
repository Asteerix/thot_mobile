import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
class EnvConfig {
  EnvConfig._();
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
      if (kDebugMode) {
        debugPrint('[EnvConfig] ✓ Loaded .env file');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[EnvConfig] ⚠ No .env file found (using defaults)');
      }
    }
  }
}