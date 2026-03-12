
class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String createdAt;

  NotificationModel({required this.id, required this.title, required this.message, required this.createdAt});

  factory NotificationModel.fromMap(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }
}