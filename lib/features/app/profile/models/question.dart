class Question {
  final String id;
  final String title;
  final String? content;
  final DateTime createdAt;
  Question({
    required this.id,
    required this.title,
    this.content,
    required this.createdAt,
  });
}