import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/job_model.dart';

class JobService {
  String get baseUrl {
    if (kIsWeb) return 'http://localhost:8080';
    if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    return 'http://localhost:8080';
  }

  // ດຶງວຽກທັງໝົດ
  Future<List<JobModel>> getJobs() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/jobs'));
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((item) => JobModel.fromMap(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getJobs: $e');
      return [];
    }
  }

  // ໂພສວຽກ
  Future<bool> postJob({
    required int postedBy,
    required String companyName,
    required String jobTitle,
    required String description,
    required String location,
    required String salaryRange,
    required String contactEmail,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/jobs'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'postedBy': postedBy,
          'companyName': companyName,
          'jobTitle': jobTitle,
          'description': description,
          'location': location,
          'salaryRange': salaryRange,
          'contactEmail': contactEmail,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error postJob: $e');
      return false;
    }
  }
}