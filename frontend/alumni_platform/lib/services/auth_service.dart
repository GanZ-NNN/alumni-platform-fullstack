import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'api_client.dart';
import 'api_config.dart';
import 'token_storage.dart';

class AuthService {
  AuthService({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<UserModel?> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        '/auth/login',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        final data =
            payload['data'] is Map<String, dynamic>
                ? payload['data'] as Map<String, dynamic>
                : payload;
        final accessToken = data['accessToken']?.toString();
        final refreshToken = data['refreshToken']?.toString();
        if (accessToken != null &&
            accessToken.isNotEmpty &&
            refreshToken != null &&
            refreshToken.isNotEmpty) {
          await _tokenStorage.saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
          );
        }
        final userData =
            data['user'] is Map<String, dynamic>
                ? data['user'] as Map<String, dynamic>
                : data;
        return UserModel.fromMap(userData);
      }
    } catch (e) {
      print('Login Error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String gender,
    required String dob,
    required String studentId,
    required String role,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/register',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'gender': gender,
          'dob': dob,
          'studentId': studentId,
          'role': role,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('Register Error: $e');
    }
    return null;
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(
        '/auth/update-profile',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
        withAuth: true,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Update Error: $e');
    }
    return false;
  }

  Future<String?> uploadImage(List<int> bytes, String fileName) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/upload'),
      );
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );
      request.fields['category'] = 'profile';

      var response = await request.send();
      if (response.statusCode == 200) {
        final resBody = await response.stream.bytesToString();
        return jsonDecode(resBody)['url'];
      }
    } catch (e) {
      print('Upload error: $e');
    }
    return null;
  }

  Future<void> updateAvatar(int userId, String url) async {
    await _apiClient.put(
      '/users/$userId/avatar',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'profileImageUrl': url}),
      withAuth: true,
    );
  }

  Future<void> logout() async {
    await _tokenStorage.clearTokens();
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      final response = await _apiClient.post(
        '/auth/change-password',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
        withAuth: true,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Change Password Error: $e');
    }
    return false;
  }

  Future<bool> forgotPassword(String email) async {
    try {
      final response = await _apiClient.post(
        '/auth/forgot-password',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Forgot Password Error: $e');
    }
    return false;
  }

  Future<bool> resetPassword(String email, String code, String newPassword) async {
    try {
      final response = await _apiClient.post(
        '/auth/reset-password',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
          'newPassword': newPassword,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Reset Password Error: $e');
    }
    return false;
  }
}
