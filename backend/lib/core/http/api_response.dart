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
    String? message,
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) {
    return json(statusCode, {
      'success': true,
      if (message != null) 'message': message,
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
    print('🚨 [ApiResponse.error] status=$statusCode code=$code message=$message details=$details');
    return json(statusCode, {
      'success': false,
      'error': {
        'code': code,
        'message': message,
        if (details != null) ...{'details': details},
      },
    }, headers: headers);
  }
}
