import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class AdminService {
  AdminService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Map<String, dynamic>? _decodeMap(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) return data;
      return decoded;
    }
    return null;
  }

  List<dynamic> _decodeList(String body) {
    final decoded = jsonDecode(body);
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is List) return data;
    }
    return const [];
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _apiClient
          .get('/admin/users', withAuth: true)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = _decodeList(response.body);
        return data.map((json) => UserModel.fromMap(json)).toList();
      }
      debugPrint('❌ Get Users Failed: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('AdminService Error: $e');
      return [];
    }
  }

  Future<bool> approveUser(String id) async {
    try {
      final response = await _apiClient
          .put('/admin/users/$id/approve', withAuth: true)
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    try {
      final response = await _apiClient
          .delete('/admin/users/$id', withAuth: true)
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteJob(int id) async {
    try {
      final response = await _apiClient
          .delete('/admin/jobs/$id', withAuth: true)
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getDashboardStats() async {
    try {
      final response = await _apiClient
          .get('/admin/stats', withAuth: true)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final raw = _decodeMap(response.body);
        if (raw == null) return null;

        // Normalize keys across backend versions.
        final totalAlumni = raw['totalAlumni'] ?? raw['totalUsers'] ?? 0;
        return {
          'totalAlumni': totalAlumni,
          'pendingUsers': raw['pendingUsers'] ?? raw['pending'] ?? 0,
          'totalPosts': raw['totalPosts'] ?? raw['posts'] ?? 0,
          'totalJobs': raw['totalJobs'] ?? raw['jobs'] ?? 0,
        };
      }
      debugPrint('❌ Stats Error: ${response.statusCode}');
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getPublicStats() async {
    try {
      final response = await _apiClient
          .get('/auth/public-stats', withAuth: true)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final raw = _decodeMap(response.body);
        if (raw == null) return null;
        return {
          'totalAlumni': raw['totalAlumni'] ?? 0,
          'totalPosts': raw['totalPosts'] ?? 0,
          'totalJobs': raw['totalJobs'] ?? 0,
        };
      }
      debugPrint('❌ Public Stats Error: ${response.statusCode}');
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>> getActivityLogs() async {
    try {
      final response = await _apiClient
          .get('/admin/logs', withAuth: true)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return _decodeList(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getMajorReports() async {
    try {
      final res = await _apiClient
          .get('/admin/reports/majors', withAuth: true)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return _decodeList(res.body);
      } else {
        debugPrint('❌ Major Report Failed: ${res.statusCode} ${res.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Major Report Exception: $e');
      return [];
    }
  }

  Future<List<dynamic>> getYearReports() async {
    try {
      final res = await _apiClient
          .get('/admin/reports/years', withAuth: true)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return _decodeList(res.body);
      } else {
        debugPrint('❌ Year Report Failed: ${res.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Year Report Exception: $e');
      return [];
    }
  }

  Future<List<dynamic>> getEmploymentReports() async {
    try {
      final res = await _apiClient
          .get('/admin/reports/employment', withAuth: true)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return _decodeList(res.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getWorkplaceReports() async {
    try {
      final res = await _apiClient
          .get('/admin/reports/workplaces', withAuth: true)
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200 ? _decodeList(res.body) : [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getPositionReports() async {
    try {
      final res = await _apiClient
          .get('/admin/reports/positions', withAuth: true)
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200 ? _decodeList(res.body) : [];
    } catch (e) {
      return [];
    }
  }
}
