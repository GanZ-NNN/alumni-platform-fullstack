import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:io'; // ✅ ຢ່າລືມ import ອັນນີ້
import '../models/notification_model.dart';

class NotificationService {
// ໃນ notification_service.dart
String get baseUrl {
  if (kIsWeb) return 'http://localhost:8080';
  // 🛑 ຖ້າ Run ໃສ່ Windows ຕ້ອງໃຊ້ localhost 🛑
  if (Platform.isWindows || Platform.isMacOS) return 'http://localhost:8080'; 
  return 'http://10.0.2.2:8080'; // ສຳລັບ Android Emulator
}

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/notifications'));
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
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error sendNotification: $e');
      return false;
    }
  }
}