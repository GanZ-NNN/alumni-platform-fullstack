class PostModel {
  final int id;
  final String title;
  final String content;
  final String type; // 'news', 'event'
  final String createdAt;

  PostModel({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.createdAt,
  });

  factory PostModel.fromMap(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? 'news',
      createdAt: json['createdAt'] ?? '',
    );
  }
}