import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'token_storage.dart';

class ApiClient {
  ApiClient({http.Client? client, TokenStorage? tokenStorage})
    : _client = client ?? http.Client(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final http.Client _client;
  final TokenStorage _tokenStorage;

  Uri _uri(String path, [Map<String, String>? queryParameters]) {
    return Uri.parse(
      '${ApiConfig.baseUrl}$path',
    ).replace(queryParameters: queryParameters);
  }

  Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
    bool withAuth = false,
    Map<String, String>? queryParameters,
  }) {
    return _request(
      path: path,
      method: 'GET',
      headers: headers,
      withAuth: withAuth,
      queryParameters: queryParameters,
    );
  }

  Future<http.Response> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
    bool withAuth = false,
  }) {
    return _request(
      path: path,
      method: 'POST',
      headers: headers,
      withAuth: withAuth,
      body: body,
    );
  }

  Future<http.Response> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
    bool withAuth = false,
  }) {
    return _request(
      path: path,
      method: 'PUT',
      headers: headers,
      withAuth: withAuth,
      body: body,
    );
  }

  Future<http.Response> delete(
    String path, {
    Map<String, String>? headers,
    bool withAuth = false,
  }) {
    return _request(
      path: path,
      method: 'DELETE',
      headers: headers,
      withAuth: withAuth,
    );
  }

  Future<http.Response> _request({
    required String path,
    required String method,
    Map<String, String>? headers,
    required bool withAuth,
    Object? body,
    Map<String, String>? queryParameters,
  }) async {
    final builtHeaders = <String, String>{
      ...(headers ?? const <String, String>{}),
    };
    if (withAuth) {
      final token = await _tokenStorage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        builtHeaders['Authorization'] = 'Bearer $token';
      }
    }

    final initialResponse = await _send(
      method: method,
      path: path,
      headers: builtHeaders,
      body: body,
      queryParameters: queryParameters,
    );
    if (!withAuth || initialResponse.statusCode != 401) return initialResponse;

    final refreshed = await _refreshAccessToken();
    if (!refreshed) return initialResponse;

    final retryHeaders = <String, String>{...builtHeaders};
    final retriedToken = await _tokenStorage.readAccessToken();
    if (retriedToken != null && retriedToken.isNotEmpty) {
      retryHeaders['Authorization'] = 'Bearer $retriedToken';
    }
    return _send(
      method: method,
      path: path,
      headers: retryHeaders,
      body: body,
      queryParameters: queryParameters,
    );
  }

  Future<http.Response> _send({
    required String method,
    required String path,
    required Map<String, String> headers,
    Object? body,
    Map<String, String>? queryParameters,
  }) {
    final uri = _uri(path, queryParameters);
    switch (method) {
      case 'GET':
        return _client.get(uri, headers: headers);
      case 'POST':
        return _client.post(uri, headers: headers, body: body);
      case 'PUT':
        return _client.put(uri, headers: headers, body: body);
      case 'DELETE':
        return _client.delete(uri, headers: headers);
      default:
        throw ArgumentError('Unsupported method: $method');
    }
  }

  Future<bool> _refreshAccessToken() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    final response = await _client.post(
      _uri('/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    if (response.statusCode != 200) {
      await _tokenStorage.clearTokens();
      return false;
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final data =
        payload['data'] is Map<String, dynamic>
            ? payload['data'] as Map<String, dynamic>
            : payload;
    final accessToken = data['accessToken']?.toString();
    if (accessToken == null || accessToken.isEmpty) return false;
    await _tokenStorage.saveAccessToken(accessToken);
    return true;
  }
}
