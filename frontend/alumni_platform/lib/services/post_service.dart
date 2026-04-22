import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import 'api_client.dart';

class PostService {
  PostService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<PostModel>> getAdminPosts() async {
    try {
      final response = await _apiClient
          .get('/admin/posts', withAuth: true)
          .timeout(const Duration(seconds: 10));

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
      final response = await _apiClient
          .get('/posts')
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
      final response = await _apiClient
          .post(
            '/admin/posts',
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'authorId': authorId,
              'title': title,
              'content': content,
              'type': type,
              'imageUrl': imageUrl ?? '',
            }),
            withAuth: true,
          )
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error createPost: $e');
      return false;
    }
  }

  Future<bool> deletePost(int id) async {
    try {
      final response = await _apiClient
          .delete('/admin/posts/$id', withAuth: true)
          .timeout(const Duration(seconds: 10));
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
      final response = await _apiClient
          .put(
            '/admin/posts/$id',
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'title': title,
              'content': content,
              'type': type,
              'imageUrl': imageUrl ?? '',
            }),
            withAuth: true,
          )
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updatePost: $e');
      return false;
    }
  }
}
