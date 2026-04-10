import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../auth/jwt_service.dart';

Middleware authMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['Authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response.forbidden(
          jsonEncode({'error': 'Unauthorized: Missing or invalid token'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final token = authHeader.substring(7);
      try {
        final payload = JwtService.verifyToken(token);
        if (payload == null) {
          return Response.forbidden(
            jsonEncode({'error': 'Unauthorized: Invalid token'}),
            headers: {'Content-Type': 'application/json'},
          );
        }

        // Attach user info to the request context
        final updatedRequest = request.change(context: {'user': payload});
        return await innerHandler(updatedRequest);
      } catch (e) {
        return Response.forbidden(
          jsonEncode({'error': 'Unauthorized: $e'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    };
  };
}

Middleware isAdmin() {
  return createMiddleware(
    requestHandler: (Request request) {
      final user = request.context['user'] as Map<String, dynamic>?;
      final role = user?['role']?.toString().toLowerCase();

      if (role != 'admin') {
        return Response.forbidden(
          jsonEncode({'error': 'Access Denied: Admin only'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      return null;
    },
  );
}
