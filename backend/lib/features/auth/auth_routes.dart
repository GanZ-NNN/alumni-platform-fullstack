import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:dbcrypt/dbcrypt.dart';
import 'package:postgres/postgres.dart';
import '../../config/database.dart';
import '../../core/auth/jwt_service.dart';
import '../../core/middleware/auth_middleware.dart';

class AuthRoutes {
  Router get router {
    final router = Router();

    router.post('/register', (Request request) async {
      try {
        final body = jsonDecode(await request.readAsString());
        final String email = body['email'];
        final String password = body['password'];

        final hashed = DBCrypt().hashpw(password, DBCrypt().gensalt());

        await DatabaseConfig.connection.execute(
          Sql.named('INSERT INTO users (email, password, first_name, last_name, role) VALUES (@email, @pass, @f, @l, @r)'),
          parameters: {
            'email': email,
            'pass': hashed,
            'f': body['firstName'] ?? '',
            'l': body['lastName'] ?? '',
            'r': body['role'] ?? 'alumni',
          },
        );

        return Response.ok(jsonEncode({'message': 'Registered successfully'}));
      } catch (e) {
        return Response.internalServerError(body: jsonEncode({'error': 'Registration failed: $e'}));
      }
    });

    router.post('/login', (Request request) async {
      try {
        final body = jsonDecode(await request.readAsString());
        final String email = body['email'];
        final String password = body['password'];

        final result = await DatabaseConfig.connection.execute(
          Sql.named('SELECT id, email, password, role FROM users WHERE email ILIKE @email'),
          parameters: {'email': email},
        );

        if (result.isEmpty) {
          return Response.forbidden(jsonEncode({'error': 'User not found'}));
        }

        final row = result.first;
        final hashed = row[2].toString();

        if (!DBCrypt().checkpw(password, hashed)) {
          return Response.forbidden(jsonEncode({'error': 'Invalid credentials'}));
        }

        final userId = row[0].toString();
        final role = row[3].toString();

        final accessToken = JwtService.generateToken({'userId': userId, 'role': role});
        final refreshToken = JwtService.generateRefreshToken(userId);

        return Response.ok(jsonEncode({
          'accessToken': accessToken,
          'refreshToken': refreshToken,
          'user': {
            'id': row[0],
            'email': row[1],
            'role': row[3],
          }
        }), headers: {'Content-Type': 'application/json'});
      } catch (e) {
        return Response.internalServerError(body: jsonEncode({'error': 'Login error: $e'}));
      }
    });

    router.post('/refresh', (Request request) async {
      try {
        final body = jsonDecode(await request.readAsString());
        final String refreshToken = body['refreshToken'];
        
        final accessToken = JwtService.refreshAccessToken(refreshToken);
        if (accessToken != null) {
          return Response.ok(jsonEncode({'accessToken': accessToken}));
        }

        return Response.forbidden(jsonEncode({'error': 'Invalid refresh token'}));
      } catch (e) {
        return Response.forbidden(jsonEncode({'error': 'Token refresh failed'}));
      }
    });

    router.get('/me', Pipeline().addMiddleware(authMiddleware()).addHandler((Request request) async {
      final user = request.context['user'] as Map<String, dynamic>;
      final result = await DatabaseConfig.connection.execute(
        Sql.named('SELECT id, email, first_name, last_name, role FROM users WHERE id = @id'),
        parameters: {'id': int.parse(user['userId'])},
      );

      if (result.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'User not found'}));
      }

      final row = result.first;
      return Response.ok(jsonEncode({
        'id': row[0],
        'email': row[1],
        'firstName': row[2],
        'lastName': row[3],
        'role': row[4],
      }), headers: {'Content-Type': 'application/json'});
    }));

    return router;
  }
}
