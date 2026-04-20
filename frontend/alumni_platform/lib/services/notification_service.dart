import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'api_client.dart';

class NotificationService {
  NotificationService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final res = await _apiClient
          .get('/notifications')
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        List data = jsonDecode(res.body);
        return data.map((item) => NotificationModel.fromMap(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getNotifications: $e');
      return [];
    }
  }

  Future<bool> sendNotification(String title, String message) async {
    try {
      final res = await _apiClient
          .post(
            '/admin/notifications',
            headers: {
              'Content-Type': 'application/json',
              'x-user-role': 'admin',
            },
            body: jsonEncode({'title': title, 'message': message}),
            withAuth: true,
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error sendNotification: $e');
      return false;
    }
  }
}
