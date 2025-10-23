class ApiResponseHelper {
  static List<T> extractList<T>(
    Map<String, dynamic> response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final data = response['data'];
    if (data == null || data is! List) return <T>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map((item) => fromJson(item))
        .toList();
  }
  static T? extractData<T>(Map<String, dynamic> response) {
    return response['data'] as T?;
  }
}