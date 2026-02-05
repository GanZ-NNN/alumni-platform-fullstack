import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint; // เพิ่ม debugPrint
import 'dart:io' show Platform; 
import '../models/user_model.dart';

class AuthService { 
  
  String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080'; 
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080'; 
    } else {
      return 'http://localhost:8080'; 
    }
  }

  Future<UserModel?> login(String email, String password) async {
    try {
      final url = Uri.parse('$baseUrl/login');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromMap(data); 
      } else {
        // เปลี่ยนจาก print เป็น debugPrint เพื่อลบคำเตือนสีฟ้า
        debugPrint('Login Failed: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error: $e');
      return null;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String major,
    required String graduationYear,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password, 
          'firstName': firstName,
          'lastName': lastName,
          'major': major,
          'graduationYear': graduationYear,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Register Error: $e');
      return false;
    }
  }

  Future<bool> updateProfile(UserModel user) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/${user.id}'),
        headers: {'Content-Type': 'application/json'},
        // ใช้การ map ข้อมูลเองแบบนี้ หายห่วงเรื่อง Error user.toJson() แน่นอน
        body: jsonEncode({
          'firstName': user.firstName,
          'lastName': user.lastName,
          'phoneNumber': user.phoneNumber,
          'major': user.major,
          'graduationYear': user.graduationYear,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Update Error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500)); 
  }
}