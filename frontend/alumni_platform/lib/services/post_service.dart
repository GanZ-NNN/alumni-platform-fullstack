// lib/services/post_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import 'dart:io'; // ສຳລັບ Platform.isAndroid


class PostService {
  String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080'; // Web
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080'; // Android Emulator
    } else {
      // 🔥 ສຳລັບ Windows, macOS, iOS (Simulator) ຕ້ອງໃຊ້ localhost 🔥
      return 'http://localhost:8080'; 
    }
  }

  // Header ສໍາລັບ Admin (ເພາະຕ້ອງຜ່ານ Middleware isAdmin)
  Map<String, String> get _adminHeaders => {
    'Content-Type': 'application/json',
    'x-user-role': 'admin',
  };

  // --- 🛑 ຟັງຊັນທີ່ເຈົ້າຂາດໄປ (ເພີ່ມບ່ອນນີ້) 🛑 ---
  Future<List<PostModel>> getAdminPosts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/posts'), 
        headers: _adminHeaders,
      );
      
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((item) => PostModel.fromMap(item)).toList();
      } else {
        debugPrint('Failed to load admin posts: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error getAdminPosts: $e');
      return [];
    }
  }

  // ຟັງຊັນດຶງຂ່າວທົ່ວໄປ (ສໍາລັບ Alumni - ບໍ່ໃຊ້ admin header)
  Future<List<PostModel>> getPosts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/posts'));
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((item) => PostModel.fromMap(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getPosts: $e');
      return [];
    }
  }

  // ຟັງຊັນສ້າງໂພສໃໝ່ (Admin)
// ✅ ແກ້ໄຂຟັງຊັນ createPost ໃຫ້ຮັບ imageUrl
  Future<bool> createPost({
    required int authorId,
    required String title,
    required String content,
    required String type,
    String? imageUrl, // 🛑 ເພີ່ມແຖວນີ້ເພື່ອຮັບ URL ຮູບ 🛑
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/posts'),
        headers: _adminHeaders,
        body: jsonEncode({
          'authorId': authorId,
          'title': title,
          'content': content,
          'type': type,
          'imageUrl': imageUrl ?? '', // 🛑 ສົ່ງ URL ນີ້ໄປຫາ Backend 🛑
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error createPost: $e');
      return false;
    }
  }

  // ຟັງຊັນລຶບໂພສ (Admin)
  Future<bool> deletePost(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/posts/$id'), 
        headers: _adminHeaders,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deletePost: $e');
      return false;
    }
  }

  // ແກ້ໄຂໂພສ (Admin)
  Future<bool> updatePost({
    required int id,
    required String title,
    required String content,
    required String type,
    String? imageUrl,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/posts/$id'),
        headers: _adminHeaders,
        body: jsonEncode({
          'title': title,
          'content': content,
          'type': type,
          'imageUrl': imageUrl ?? '',
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updatePost: $e');
      return false;
    }
  }
}