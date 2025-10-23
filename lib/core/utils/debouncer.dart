import 'dart:async';
typedef VoidAction = void Function();
class Debouncer {
  final int milliseconds;
  Timer? _timer;
  VoidAction? _pendingAction;
  bool _disposed = false;
  Debouncer({required this.milliseconds});
  bool get isActive => _timer?.isActive ?? false;
  void run(VoidAction action) {
    if (_disposed) return;
    _pendingAction = action;
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), () {
      final toRun = _pendingAction;
      _clearTimerState();
      toRun?.call();
    });
  }
  void cancel() => _clearTimerState();
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _clearTimerState();
  }
  void _clearTimerState() {
    _timer?.cancel();
    _timer = null;
    _pendingAction = null;
  }
}
class ActionDebouncer {
  final Map<String, Timer> _timers = {};
  final Map<String, VoidAction> _pending = {};
  final int defaultDelay;
  bool _disposed = false;
  ActionDebouncer({this.defaultDelay = 300});
  void debounce(String key, VoidAction action, {int? delay}) {
    if (_disposed) return;
    _pending[key] = action;
    _timers[key]?.cancel();
    _timers[key] = Timer(
      Duration(milliseconds: delay ?? defaultDelay),
      () {
        final toRun = _pending.remove(key);
        _timers.remove(key);
        toRun?.call();
      },
    );
  }
  bool isDebouncing(String key) => _timers[key]?.isActive ?? false;
  void flush(String key) {
    if (_disposed) return;
    final toRun = _pending.remove(key);
    _timers.remove(key)?.cancel();
    toRun?.call();
  }
  void flushAll() {
    final pendingKeys = List<String>.from(_pending.keys);
    for (final key in pendingKeys) {
      flush(key);
    }
  }
  void cancel(String key) {
    _timers.remove(key)?.cancel();
    _pending.remove(key);
  }
  void cancelAll() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _pending.clear();
  }
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    cancelAll();
  }
}