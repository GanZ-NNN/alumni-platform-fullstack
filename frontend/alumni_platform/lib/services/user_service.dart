import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:io';
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
}