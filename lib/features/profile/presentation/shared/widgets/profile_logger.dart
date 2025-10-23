import 'package:logger/logger.dart';
class ProfileLogger {
  static final _instance = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 120,
      colors: false,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.none,
    ),
    level: Level.debug,
  );
  ProfileLogger._();
  static void d(String message, {dynamic error, StackTrace? stackTrace}) {
    _instance.d(message, error: error, stackTrace: stackTrace);
  }
  static void i(String message, {dynamic error, StackTrace? stackTrace}) {
    _instance.i(message, error: error, stackTrace: stackTrace);
  }
  static void w(String message, {dynamic error, StackTrace? stackTrace}) {
    _instance.w(message, error: error, stackTrace: stackTrace);
  }
  static void e(String message, {dynamic error, StackTrace? stackTrace}) {
    _instance.e(message, error: error, stackTrace: stackTrace);
  }
  static void f(String message, {dynamic error, StackTrace? stackTrace}) {
    _instance.f(message, error: error, stackTrace: stackTrace);
  }
}