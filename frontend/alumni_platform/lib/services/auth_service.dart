import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb; // ເຊັກວ່າເປັນ Web ບໍ່
import 'dart:io' show Platform; // ເຊັກວ່າເປັນ Android ບໍ່
import '..\\model/models/user_model.dart';

class AuthService { // ລຶບຄຳວ່າ Mock ອອກ
  
  // ກຳນົດ URL ຂອງ API
  String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080'; // ສຳລັບ Web Browser
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080'; // ສຳລັບ Android Emulator (Localhost ຂອງ Android)
    } else {
      return 'http://localhost:8080'; // ສຳລັບ iOS / Desktop
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
        // Login ສຳເລັດ! ແປງ JSON ເປັນ UserModel
        final data = jsonDecode(response.body);
        return UserModel(
          id: data['id'],
          email: data['email'],
          firstName: data['firstName'],
          role: data['role'],
        );
      } else {
        print('Login Failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }
}