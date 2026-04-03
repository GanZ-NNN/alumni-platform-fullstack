import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import 'api_config.dart';

class PostService {
  String get baseUrl => ApiConfig.baseUrl;

  // Header ສໍາລັບ Admin (ເພາະຕ້ອງຜ່ານ Middleware isAdmin)
  Map<String, String> get _adminHeaders => {
    'Content-Type': 'application/json',
    'x-user-role': 'admin',
  };

  Future<List<PostModel>> getAdminPosts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/posts'), 
        headers: _adminHeaders,
      ).timeout(const Duration(seconds: 10));
      
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

  Future<List<PostModel>> getPosts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/posts'))
          .timeout(const Duration(seconds: 10));
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

  Future<bool> createPost({
    required int authorId,
    required String title,
    required String content,
    required String type,
    String? imageUrl,
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
          'imageUrl': imageUrl ?? '',
        }),
      ).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error createPost: $e');
      return false;
    }
  }

  Future<bool> deletePost(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/posts/$id'), 
        headers: _adminHeaders,
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deletePost: $e');
      return false;
    }
  }

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
      ).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updatePost: $e');
      return false;
    }
  }
}
