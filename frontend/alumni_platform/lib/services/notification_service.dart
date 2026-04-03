import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'api_config.dart';

class NotificationService {
  String get baseUrl => ApiConfig.baseUrl;

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/notifications'))
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
      final res = await http.post(
        Uri.parse('$baseUrl/admin/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'x-user-role': 'admin'
        },
        body: jsonEncode({'title': title, 'message': message}),
      ).timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error sendNotification: $e');
      return false;
    }
  }
}
