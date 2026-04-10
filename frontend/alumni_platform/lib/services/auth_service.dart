import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'api_config.dart';

class AuthService {
  static String get baseUrl => ApiConfig.baseUrl;

  Future<UserModel?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        return UserModel.fromMap(jsonDecode(response.body));
      }
    } catch (e) { print('Login Error: $e'); }
    return null;
  }

  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String major,
    required String graduationYear,
    required String phoneNumber,
    required String gender,
    required String dob,
    required String studentId,
    required String educationLevel,
    required String industry,
    required String jobTitle,
    required String companyName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        body: jsonEncode({
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'major': major,
          'graduationYear': graduationYear,
          'phoneNumber': phoneNumber,
          'gender': gender,
          'dob': dob,
          'studentId': studentId,
          'educationLevel': educationLevel,
          'industry': industry,
          'jobTitle': jobTitle,
          'companyName': companyName,
        }),
      );
      return response.statusCode == 200;
    } catch (e) { print('Register Error: $e'); }
    return false;
  }

  Future<bool> updateProfile(UserModel user) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/${user.id}'),
        body: jsonEncode(user.toMap()),
      );
      return response.statusCode == 200;
    } catch (e) { print('Update Error: $e'); }
    return false;
  }

  Future<String?> uploadImage(List<int> bytes, String fileName) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
      request.fields['category'] = 'profile';
      
      var response = await request.send();
      if (response.statusCode == 200) {
        final resBody = await response.stream.bytesToString();
        return jsonDecode(resBody)['url'];
      }
    } catch (e) { print('Upload error: $e'); }
    return null;
  }

  Future<void> updateAvatar(int userId, String url) async {
    await http.put(
      Uri.parse('$baseUrl/users/$userId/avatar'),
      body: jsonEncode({'profileImageUrl': url}),
    );
  }
}
