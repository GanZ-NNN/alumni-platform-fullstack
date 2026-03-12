// lib/services/admin_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'dart:io'; 

class AdminService {
  String get baseUrl {
    if (kIsWeb) return 'http://localhost:8080';
    if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    return 'http://localhost:8080'; 
  }

  Map<String, String> get _adminHeaders => {
    'Content-Type': 'application/json',
    'x-user-role': 'admin', // 🔑 ສົ່ງ Header ນີ້ເພື່ອໃຫ້ Middleware ຍອມໃຫ້ຜ່ານ
  };

  // --- 1. ຈັດການຜູ້ໃຊ້ ---
  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/users'), headers: _adminHeaders);
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
      final response = await http.put(Uri.parse('$baseUrl/admin/users/$id/approve'), headers: _adminHeaders);
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<bool> deleteUser(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/admin/users/$id'), headers: _adminHeaders);
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  // --- 2. ຈັດການວຽກ ---
  Future<bool> deleteJob(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/admin/jobs/$id'), headers: _adminHeaders);
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  // --- 3. ສະຖິຕິ Dashboard ---
  Future<Map<String, dynamic>?> getDashboardStats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/stats'), headers: _adminHeaders);
      if (response.statusCode == 200) return jsonDecode(response.body);
      debugPrint('❌ Stats Error: ${response.statusCode}');
      return null;
    } catch (e) { return null; }
  }

  // --- 4. ປະຫວັດການໃຊ້ງານ ---
  Future<List<dynamic>> getActivityLogs() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/logs'), headers: _adminHeaders);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) { return []; }
  }

  // --- 5. ລະບົບລາຍງານ (Reports) ---
  
  // ✅ ດຶງລາຍງານຕາມສາຂາ
  Future<List<dynamic>> getMajorReports() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/admin/reports/majors'), headers: _adminHeaders);
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

  // ✅ ດຶງລາຍງານຕາມປີຈົບ
  Future<List<dynamic>> getYearReports() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/admin/reports/years'), headers: _adminHeaders);
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

  // ✅ ດຶງລາຍງານການມີວຽກເຮັດ
  Future<List<dynamic>> getEmploymentReports() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/admin/reports/employment'), headers: _adminHeaders);
      if (res.statusCode == 200) return jsonDecode(res.body);
      return [];
    } catch (e) { return []; }
  }

  Future<List<dynamic>> getWorkplaceReports() async {
    final res = await http.get(Uri.parse('$baseUrl/admin/reports/workplaces'), headers: _adminHeaders);
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  Future<List<dynamic>> getPositionReports() async {
    final res = await http.get(Uri.parse('$baseUrl/admin/reports/positions'), headers: _adminHeaders);
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }
}