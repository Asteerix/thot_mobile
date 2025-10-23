class SearchResultDto {
  final String id;
  final String title;
  final String description;
  final String type;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;
  const SearchResultDto({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.imageUrl,
    this.metadata,
  });
  factory SearchResultDto.fromJson(Map<String, dynamic> json) {
    return SearchResultDto(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      imageUrl: json['imageUrl'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'imageUrl': imageUrl,
      'metadata': metadata,
    };
  }
}