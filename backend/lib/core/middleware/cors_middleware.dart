import 'package:shelf/shelf.dart';
import '../../config/app_config.dart';

Middleware corsMiddleware() {
  return createMiddleware(
    requestHandler: (request) {
      if (request.method == 'OPTIONS') {
        final origin = request.headers['Origin'];
        final allowedOrigins = AppConfig.allowedOrigins;

        if (allowedOrigins.contains('*') || allowedOrigins.contains(origin)) {
          return Response.ok('', headers: {
            'Access-Control-Allow-Origin': origin ?? '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Origin, Content-Type, x-user-role, Authorization',
          });
        }
        return Response.forbidden('CORS policy: Invalid origin');
      }
      return null;
    },
    responseHandler: (response) {
      // In a real strict environment, you should only set this to the requesting origin if it is allowed.
      // For now, we will use the same origin if present, or '*'
      return response.change(headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type, x-user-role, Authorization',
      });
    },
  );
}
