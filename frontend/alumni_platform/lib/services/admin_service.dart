import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'api_config.dart';

class AdminService {
  String get baseUrl => ApiConfig.baseUrl;

  Map<String, String> get _adminHeaders => {
    'Content-Type': 'application/json',
    'x-user-role': 'admin',
  };

  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/users'), headers: _adminHeaders)
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
      final response = await http.put(Uri.parse('$baseUrl/admin/users/$id/approve'), headers: _adminHeaders)
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<bool> deleteUser(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/admin/users/$id'), headers: _adminHeaders)
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<bool> deleteJob(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/admin/jobs/$id'), headers: _adminHeaders)
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<Map<String, dynamic>?> getDashboardStats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/stats'), headers: _adminHeaders)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return jsonDecode(response.body);
      debugPrint('❌ Stats Error: ${response.statusCode}');
      return null;
    } catch (e) { return null; }
  }

  Future<List<dynamic>> getActivityLogs() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/logs'), headers: _adminHeaders)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) { return []; }
  }

  Future<List<dynamic>> getMajorReports() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/admin/reports/majors'), headers: _adminHeaders)
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
      final res = await http.get(Uri.parse('$baseUrl/admin/reports/years'), headers: _adminHeaders)
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
      final res = await http.get(Uri.parse('$baseUrl/admin/reports/employment'), headers: _adminHeaders)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return jsonDecode(res.body);
      return [];
    } catch (e) { return []; }
  }

  Future<List<dynamic>> getWorkplaceReports() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/admin/reports/workplaces'), headers: _adminHeaders)
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200 ? jsonDecode(res.body) : [];
    } catch (e) { return []; }
  }

  Future<List<dynamic>> getPositionReports() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/admin/reports/positions'), headers: _adminHeaders)
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200 ? jsonDecode(res.body) : [];
    } catch (e) { return []; }
  }
}
