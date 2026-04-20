import 'package:shelf/shelf.dart';
import '../../config/app_config.dart';
import '../http/api_response.dart';

Middleware corsMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final origin = request.headers['origin'];
      final allowedOrigins = AppConfig.allowedOrigins;

      if (request.method == 'OPTIONS') {
        if (_isOriginAllowed(origin, allowedOrigins)) {
          return Response.ok(
            '',
            headers: {
              'Access-Control-Allow-Origin': origin!,
              'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
              'Access-Control-Allow-Headers':
                  'Origin, Content-Type, x-user-role, Authorization',
              'Vary': 'Origin',
            },
          );
        }
        return ApiResponse.error(
          403,
          code: 'CORS_ORIGIN_DENIED',
          message: 'CORS policy: Invalid origin',
        );
      }

      final response = await innerHandler(request);
      if (!_isOriginAllowed(origin, allowedOrigins)) {
        return response;
      }

      return response.change(
        headers: {
          'Access-Control-Allow-Origin': origin!,
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers':
              'Origin, Content-Type, x-user-role, Authorization',
          'Vary': 'Origin',
        },
      );
    };
  };
}

bool _isOriginAllowed(String? origin, List<String> allowedOrigins) {
  if (allowedOrigins.contains('*')) return true;
  if (origin == null || origin.isEmpty) return false;
  if (allowedOrigins.contains(origin)) return true;

  final originUri = Uri.tryParse(origin);
  if (originUri == null) return false;

  final isLocalhostOrigin =
      originUri.host == 'localhost' || originUri.host == '127.0.0.1';
  if (isLocalhostOrigin) {
    // Flutter web on Chrome typically runs on a random localhost port.
    return allowedOrigins.any((entry) {
      if (entry == 'localhost:*' || entry == '127.0.0.1:*') return true;
      final entryUri = Uri.tryParse(entry);
      if (entryUri == null) return false;
      return entryUri.host == originUri.host;
    });
  }

  return false;
}
