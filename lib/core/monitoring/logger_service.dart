library;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kReleaseMode, kIsWeb;
import 'package:logger/logger.dart';
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  static LoggerService get instance => _instance;
  late final Logger _logger;
  late final _DedupFilter _filter;
  LoggerService._internal() {
    final bool isProd = kReleaseMode;
    _filter = _DedupFilter(
      minLevel: isProd ? Level.info : Level.debug,
      dedupSeconds: isProd ? 10 : 2,
    );
    _logger = Logger(
      filter: _filter,
      printer: isProd ? _ProductionPrinter() : _DevelopmentPrinter(),
      level: Level.trace,
    );
  }
  void info(String message, {String? tag, Map<String, dynamic>? extra}) {
    _log(Level.info, message, tag: tag, extra: extra);
  }
  void debug(String message, {String? tag, Map<String, dynamic>? extra}) {
    _log(Level.debug, message, tag: tag, extra: extra);
  }
  void warning(String message, {String? tag, Map<String, dynamic>? extra}) {
    _log(Level.warning, message, tag: tag, extra: extra);
  }
  void warn(String message, {String? tag, Map<String, dynamic>? extra}) {
    warning(message, tag: tag, extra: extra);
  }
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(Level.error, message, error: error, stackTrace: stackTrace);
  }
  void _log(
    Level level,
    String message, {
    String? tag,
    Map<String, dynamic>? extra,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.log(
      level,
      _LogPayload(message: message, tag: tag, extra: extra),
      time: DateTime.now(),
      error: error,
      stackTrace: stackTrace,
    );
  }
}
class _LogPayload {
  const _LogPayload({
    required this.message,
    this.tag,
    this.extra,
  });
  final String message;
  final String? tag;
  final Map<String, dynamic>? extra;
  @override
  String toString() => message;
}
class _DedupFilter extends LogFilter {
  _DedupFilter({required Level minLevel, required int dedupSeconds})
      : _minLevel = minLevel,
        _dedupDuration = Duration(seconds: dedupSeconds);
  final Level _minLevel;
  final Duration _dedupDuration;
  final Map<int, DateTime> _lastSeen = {};
  @override
  bool shouldLog(LogEvent event) {
    if (event.level.index < _minLevel.index) return false;
    final key = _computeKey(event);
    final now = DateTime.now();
    final lastTime = _lastSeen[key];
    if (lastTime != null && now.difference(lastTime) < _dedupDuration) {
      return false;
    }
    _lastSeen[key] = now;
    if (_lastSeen.length > 1000) {
      _lastSeen.removeWhere(
        (_, time) => now.difference(time) > const Duration(minutes: 5),
      );
    }
    return true;
  }
  int _computeKey(LogEvent event) {
    final message = event.message is _LogPayload
        ? (event.message as _LogPayload).message
        : event.message.toString();
    return Object.hash(event.level.index, message);
  }
}
class _DevelopmentPrinter extends LogPrinter {
  static final Stopwatch _uptime = Stopwatch()..start();
  @override
  List<String> log(LogEvent event) {
    final now = event.time;
    final time = '${_pad(now.hour)}:${_pad(now.minute)}:${_pad(now.second)}';
    final elapsed = '+${_uptime.elapsedMilliseconds}ms';
    final payload = event.message is _LogPayload
        ? event.message as _LogPayload
        : _LogPayload(message: event.message.toString());
    final level = _levelBadge(event.level);
    final tag = payload.tag ?? 'APP';
    final message = payload.message;
    final lines = <String>[];
    lines.add('┌─────────────────────────────────────────────');
    lines.add('│ $level $time $elapsed [$tag]');
    lines.add('│ $message');
    if (payload.extra != null && payload.extra!.isNotEmpty) {
      lines.add('│ Extra: ${_formatMap(payload.extra!)}');
    }
    if (event.error != null) {
      lines.add('│ ✖ Error: ${event.error}');
    }
    if (event.stackTrace != null) {
      final stack = _filterStack(event.stackTrace.toString(), 3);
      if (stack.isNotEmpty) {
        lines.add('│ Stack:');
        for (final line in stack) {
          lines.add('│   $line');
        }
      }
    }
    lines.add('└─────────────────────────────────────────────');
    return lines;
  }
  String _levelBadge(Level level) {
    return switch (level) {
      Level.debug => '[DBG]',
      Level.info => '[INF]',
      Level.warning => '[WRN]',
      Level.error => '[ERR]',
      _ => '[LOG]',
    };
  }
  String _pad(int n) => n.toString().padLeft(2, '0');
  String _formatMap(Map<String, dynamic> map) {
    return map.entries.map((e) => '${e.key}=${e.value}').join(', ');
  }
  List<String> _filterStack(String stack, int limit) {
    return stack
        .split('\n')
        .where((line) =>
            line.trim().isNotEmpty &&
            !line.contains('package:logger/') &&
            !line.contains('logger_service.dart'))
        .take(limit)
        .toList();
  }
}
class _ProductionPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final payload = event.message is _LogPayload
        ? event.message as _LogPayload
        : _LogPayload(message: event.message.toString());
    final data = {
      'timestamp': event.time.toIso8601String(),
      'level': _levelName(event.level),
      'message': payload.message,
      if (payload.tag != null) 'tag': payload.tag,
      if (payload.extra != null) 'extra': payload.extra,
      if (event.error != null) 'error': event.error.toString(),
      if (event.stackTrace != null) 'stack': event.stackTrace.toString(),
      'platform': kIsWeb ? 'web' : 'mobile',
    };
    return [jsonEncode(data)];
  }
  String _levelName(Level level) {
    return switch (level) {
      Level.debug => 'DEBUG',
      Level.info => 'INFO',
      Level.warning => 'WARN',
      Level.error => 'ERROR',
      _ => 'LOG',
    };
  }
}