class NumberFormatter {
  static String format(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
  static String formatCompact(int number) {
    if (number >= 1000000) {
      final value = number / 1000000;
      return value % 1 == 0 ? '${value.toInt()}M' : '${value.toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      final value = number / 1000;
      return value % 1 == 0 ? '${value.toInt()}K' : '${value.toStringAsFixed(1)}K';
    }
    return number.toString();
  }
  static String formatFrench(int number) {
    if (number >= 1000000) {
      final formatted = (number / 1000000).toStringAsFixed(1);
      return '${formatted.replaceAll('.', ',')}M';
    } else if (number >= 1000) {
      final formatted = (number / 1000).toStringAsFixed(1);
      return '${formatted.replaceAll('.', ',')}k';
    }
    return number.toString();
  }
  static String formatWithSpaces(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }
}