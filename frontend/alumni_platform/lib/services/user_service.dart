import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import '../models/user_model.dart';

class UserService {
  String get baseUrl {
    if (kIsWeb) return 'http://localhost:8080';
    if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    return 'http://localhost:8080';
  }

  // ດຶງລາຍຊື່ສິດເກົ່າ (ຮອງຮັບການຄົ້ນຫາ)
// ດຶງລາຍຊື່ສິດເກົ່າ ພ້ອມລະບົບ Filter
  Future<List<UserModel>> searchAlumni({String name = '', String major = '', String year = ''}) async {
    try {
      // ສ້າງ URL ທີ່ມີ Query Parameters
      final uri = Uri.parse('$baseUrl/alumni').replace(queryParameters: {
        'name': name,
        'major': major,
        'year': year,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((item) => UserModel.fromMap(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error: $e');
      return [];
    }
  }

  // Upload image file to server (/upload) and return public URL or null
  Future<String?> uploadImage(File imageFile) async {
    try {
      final uri = Uri.parse('$baseUrl/upload');
      final request = http.MultipartRequest('POST', uri);
      request.fields['category'] = 'profile';

      final ext = imageFile.path.split('.').last.toLowerCase();
      String mime = 'image/jpeg';
      if (ext == 'png') mime = 'image/png';
      if (ext == 'gif') mime = 'image/gif';
      if (ext == 'webp') mime = 'image/webp';

      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType(mime.split('/')[0], mime.split('/')[1]),
      );
      request.files.add(multipartFile);

      final streamed = await request.send();
      final respStr = await streamed.stream.bytesToString();
      if (streamed.statusCode == 200) {
        final data = jsonDecode(respStr);
        return data['url'] as String?;
      }
      debugPrint('Upload failed: ${streamed.statusCode} $respStr');
      return null;
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  // Set avatar URL for user
  Future<bool> setAvatar(int userId, String imageUrl) async {
    try {
      final uri = Uri.parse('$baseUrl/users/$userId/avatar');
      final resp = await http.put(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'profileImageUrl': imageUrl}));
      return resp.statusCode == 200;
    } catch (e) {
      debugPrint('Set avatar error: $e');
      return false;
    }
  }

  // Upload file and assign to user's avatar (returns updated URL or null)
  Future<String?> uploadAndSetAvatar(File imageFile, int userId) async {
    final url = await uploadImage(imageFile);
    if (url == null) return null;
    final ok = await setAvatar(userId, url);
    return ok ? url : null;
  }
}