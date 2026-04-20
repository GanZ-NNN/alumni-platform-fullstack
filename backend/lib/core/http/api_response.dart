import 'dart:convert';
import 'package:shelf/shelf.dart';

class ApiResponse {
  static Response json(
    int statusCode,
    Map<String, dynamic> payload, {
    Map<String, String>? headers,
  }) {
    return Response(
      statusCode,
      body: jsonEncode(payload),
      headers: {
        'Content-Type': 'application/json',
        if (headers != null) ...headers,
      },
    );
  }

  static Response success(
    int statusCode, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) {
    return json(statusCode, {
      'success': true,
      'data': data ?? <String, dynamic>{},
    }, headers: headers);
  }

  static Response error(
    int statusCode, {
    required String code,
    required String message,
    Map<String, dynamic>? details,
    Map<String, String>? headers,
  }) {
    return json(statusCode, {
      'success': false,
      'error': {'code': code, 'message': message, 'details': ?details},
    }, headers: headers);
  }
}
