import 'dart:convert';
import 'dart:typed_data'; // ສໍາລັບ Uint8List
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'dart:io' show Platform; 
import '../models/user_model.dart';

class AuthService { 
  
  String get baseUrl {
    if (kIsWeb) return 'http://localhost:8081'; 
    if (Platform.isAndroid) return 'http://10.0.2.2:8081'; 
    return 'http://localhost:8081'; 
  }

  // --- 1. ເຂົ້າສູ່ລະບົບ ---
  Future<UserModel?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

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
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Register Error: $e');
      return false;
    }
  }

  // --- 3. ອັບເດດຂໍ້ມູນທົ່ວໄປ (ລວມເບີໂທ) ---
  Future<bool> updateProfile(UserModel user) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/${user.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': user.firstName,
          'lastName': user.lastName,
          'phoneNumber': user.phoneNumber, // ✅ ບັນທຶກເບີໂທ
          'major': user.major,
          'graduationYear': user.graduationYear,
        }),
      );
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
      
      // ເພີ່ມຂໍ້ມູນ category ບອກວ່າແມ່ນຮູບ profile
      request.fields['category'] = 'profile';

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url']; // ສົ່ງ URL ທີ່ໄດ້ຈາກ Server ກັບໄປ
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
          // 🛑 ສົ່ງ Key ຊື່ 'profileImageUrl' ໃຫ້ກົງກັບ Backend 🛑
          'profileImageUrl': imageUrl, 
        }),
      );
      
      if (response.statusCode == 200) {
        debugPrint('✅ Avatar updated in DB');
        return true;
      }
      debugPrint('❌ Avatar DB Update Failed: ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Update Avatar Error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500)); 
  }
}