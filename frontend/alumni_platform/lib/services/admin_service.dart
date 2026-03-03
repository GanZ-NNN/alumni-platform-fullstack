// lib/services/admin_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'dart:io'; // ສຳລັບ Platform.isAndroid


class AdminService {
  // ກຳນົດ URL ໃຫ້ຖືກຕາມ Platform
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

  // --- ສ້າງຕົວແປ Headers ໄວ້ກາງ ເພື່ອຄວາມເປັນລະບຽບ ---
  Map<String, String> get _adminHeaders => {
    'Content-Type': 'application/json',
    'x-user-role': 'admin', // 🔑 ສົ່ງ Header ນີ້ໄປເພື່ອໃຫ້ Middleware ໃນ Backend ຍອມໃຫ້ຜ່ານ
  };

  // 1. ດຶງຂໍ້ມູນ Users ທັງໝົດ
  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/users'), // Path ຕ້ອງກົງກັບ mount('/admin', ...)
        headers: _adminHeaders,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => UserModel.fromMap(json)).toList();
      } else {
        debugPrint('Get Users Failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('AdminService Error: ${e.toString()}'); 
      return [];
    }
  }

  // 2. ອະນຸມັດ User
  Future<bool> approveUser(String id) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/users/$id/approve'),
        headers: _adminHeaders,
      );
      
      if (response.statusCode == 200) {
        debugPrint('✅ User $id Approved successfully');
        return true;
      } else {
        debugPrint('❌ Approve failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Approve Error Exception: $e');
      return false;
    }
  }

  // 3. ລຶບ User
  Future<bool> deleteUser(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/users/$id'),
        headers: _adminHeaders,
      );
      
      if (response.statusCode == 200) {
        debugPrint('✅ User $id Deleted successfully');
        return true;
      } else {
        debugPrint('❌ Delete failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Delete Error Exception: $e');
      return false;
    }
  }

  // ລຶບປະກາດວຽກ (Admin)
  Future<bool> deleteJob(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/jobs/$id'),
        headers: _adminHeaders, // ສົ່ງ Header Admin ໄປນຳ
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Delete Job Error: $e');
      return false;
    }
  }

// ດຶງຂໍ້ມູນສະຖິຕິ
  Future<Map<String, dynamic>?> getDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/stats'),
        headers: _adminHeaders, // ສົ່ງ x-user-role: admin ໄປນຳ
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Stats API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Stats Exception: $e');
      return null;
    }
  }

  Future<List<dynamic>> getActivityLogs() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/logs'),
        headers: _adminHeaders,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('Logs Error: $e');
      return [];
    }
  }

  Future<List<dynamic>> getMajorReports() async {
    final res = await http.get(Uri.parse('$baseUrl/admin/reports/majors'), headers: _adminHeaders);
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  Future<List<dynamic>> getYearReports() async {
    final res = await http.get(Uri.parse('$baseUrl/admin/reports/years'), headers: _adminHeaders);
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  Future<List<dynamic>> getEmploymentReports() async {
    final res = await http.get(Uri.parse('$baseUrl/admin/reports/employment'), headers: _adminHeaders);
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }
}