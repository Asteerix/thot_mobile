// Helper function to convert map to readable string
String _debugMap(String prefix, Map<String, dynamic> data) {
  return '$prefix ${data.entries.map((e) => '${e.key}: ${e.value}').join(', ')}';
}
