import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class AdminService {
  AdminService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Map<String, String> get _adminHeaders => {
    'Content-Type': 'application/json',
    'x-user-role': 'admin',
  };

  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _apiClient
          .get('/admin/users', headers: _adminHeaders, withAuth: true)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
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
          .put(
            '/admin/users/$id/approve',
            headers: _adminHeaders,
            withAuth: true,
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    try {
      final response = await _apiClient
          .delete('/admin/users/$id', headers: _adminHeaders, withAuth: true)
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteJob(int id) async {
    try {
      final response = await _apiClient
          .delete('/admin/jobs/$id', headers: _adminHeaders, withAuth: true)
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getDashboardStats() async {
    try {
      final response = await _apiClient
          .get('/admin/stats', headers: _adminHeaders, withAuth: true)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return jsonDecode(response.body);
      debugPrint('❌ Stats Error: ${response.statusCode}');
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>> getActivityLogs() async {
    try {
      final response = await _apiClient
          .get('/admin/logs', headers: _adminHeaders, withAuth: true)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getMajorReports() async {
    try {
      final res = await _apiClient
          .get('/admin/reports/majors', headers: _adminHeaders, withAuth: true)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
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
          .get('/admin/reports/years', headers: _adminHeaders, withAuth: true)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
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
          .get(
            '/admin/reports/employment',
            headers: _adminHeaders,
            withAuth: true,
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return jsonDecode(res.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getWorkplaceReports() async {
    try {
      final res = await _apiClient
          .get(
            '/admin/reports/workplaces',
            headers: _adminHeaders,
            withAuth: true,
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200 ? jsonDecode(res.body) : [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getPositionReports() async {
    try {
      final res = await _apiClient
          .get(
            '/admin/reports/positions',
            headers: _adminHeaders,
            withAuth: true,
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200 ? jsonDecode(res.body) : [];
    } catch (e) {
      return [];
    }
  }
}
