import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/job_model.dart';
import 'api_config.dart';

class JobService {
  String get baseUrl => ApiConfig.baseUrl;

  Future<List<JobModel>> getJobs() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/jobs'))
          .timeout(const Duration(seconds: 10));
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
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error postJob: $e');
      return false;
    }
  }
}
