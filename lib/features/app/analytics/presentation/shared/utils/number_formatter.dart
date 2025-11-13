extension NumberFormatter on num {
  String toCompactFr() {
    final n = toDouble();
    if (n >= 1000000) {
      final v = (n / 1000000);
      return '${v.toStringAsFixed(v < 10 ? 1 : 0)} M';
    }
    if (n >= 1000) {
      final v = (n / 1000);
      return '${v.toStringAsFixed(v < 10 ? 1 : 0)} k';
    }
    if (this is int) return toString();
    return toStringAsFixed(0);
  }
}
class DateFormatter {
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Aujourd\'hui';
    if (diff == 1) return 'Hier';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}