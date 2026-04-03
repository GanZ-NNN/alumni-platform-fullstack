import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/user_model.dart';
import 'api_config.dart';

class AuthService {
  String get baseUrl => ApiConfig.baseUrl;

  // --- 1. ເຂົ້າສູ່ລະບົບ ---
  Future<UserModel?> login(String email, String password) async {
    try {
      final url = Uri.parse('$baseUrl/login');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromMap(data);
      }
      debugPrint('Login Failed: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Error Login: $e');
      return null;
    }
  }

  // --- 2. ລົງທະບຽນ ---
  Future<bool> register({
    required String email, required String password,
    required String firstName, required String lastName,
    required String major, required String graduationYear,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email, 'password': password,
          'firstName': firstName, 'lastName': lastName,
          'major': major, 'graduationYear': graduationYear,
        }),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Register Error: $e');
      return false;
    }
  }

  // --- 3. ອັບເດດຂໍ້ມູນໂປຣໄຟລ໌ ---
  Future<bool> updateProfile(UserModel user) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/${user.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': user.firstName,
          'lastName': user.lastName,
          'phoneNumber': user.phoneNumber,
          'major': user.major,
          'graduationYear': user.graduationYear,
          'workStatus': user.workStatus,
          'workplace': user.workplace,
          'jobPosition': user.jobPosition,
        }),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Update Profile Error: $e');
      return false;
    }
  }

  // --- 4. ອັບໂຫລດໄຟລ໌ຮູບໄປທີ່ Server ---
  Future<String?> uploadImage(Uint8List fileBytes, String fileName) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
      request.fields['category'] = 'profile';

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ));

      var streamedResponse = await request.send().timeout(const Duration(seconds: 20));
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'];
      }
      return null;
    } catch (e) {
      debugPrint('Upload Image Error: $e');
      return null;
    }
  }

  // --- 5. ອັບເດດ URL ຂອງຮູບລົງໃນ Database ---
  Future<bool> updateAvatar(int userId, String imageUrl) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/avatar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'profileImageUrl': imageUrl,
        }),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Update Avatar Error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
