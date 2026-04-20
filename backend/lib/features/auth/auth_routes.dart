import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:dbcrypt/dbcrypt.dart';
import 'package:postgres/postgres.dart';
import '../../config/app_config.dart';
import '../../config/database.dart';
import '../../core/auth/jwt_service.dart';
import '../../core/middleware/auth_middleware.dart';
import '../../core/middleware/rate_limit_middleware.dart';
import '../../core/http/api_response.dart';

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
          Sql.named(
            'INSERT INTO users (email, password, first_name, last_name, role) VALUES (@email, @pass, @f, @l, @r)',
          ),
          parameters: {
            'email': email,
            'pass': hashed,
            'f': body['firstName'] ?? '',
            'l': body['lastName'] ?? '',
            'r': body['role'] ?? 'alumni',
          },
        );

        return ApiResponse.success(
          200,
          data: {'message': 'Registered successfully'},
        );
      } catch (e) {
        return ApiResponse.error(
          500,
          code: 'AUTH_REGISTER_FAILED',
          message: 'Registration failed.',
          details: {'reason': e.toString()},
        );
      }
    });

    router.post('/login', (Request request) async {
      try {
        final body = jsonDecode(await request.readAsString());
        final String email = body['email'];
        final String password = body['password'];

        bool selectedStatusColumn = true;
        dynamic result;
        try {
          result = await DatabaseConfig.connection.execute(
            Sql.named(
              'SELECT id, email, password, role, first_name, last_name, status FROM users WHERE email ILIKE @email',
            ),
            parameters: {'email': email},
          );
        } catch (_) {
          // Backward-compatible fallback for older schemas without `status`.
          selectedStatusColumn = false;
          result = await DatabaseConfig.connection.execute(
            Sql.named(
              'SELECT id, email, password, role, first_name, last_name FROM users WHERE email ILIKE @email',
            ),
            parameters: {'email': email},
          );
        }

        if (result.isEmpty) {
          print('Login denied: user not found for email=$email');
          return ApiResponse.error(
            401,
            code: 'AUTH_INVALID_CREDENTIALS',
            message: 'Invalid credentials.',
          );
        }

        final row = result.first;
        final hashed = row[2].toString();

        if (!DBCrypt().checkpw(password, hashed)) {
          print('Login denied: invalid password for email=$email');
          return ApiResponse.error(
            401,
            code: 'AUTH_INVALID_CREDENTIALS',
            message: 'Invalid credentials.',
          );
        }

        final userId = row[0].toString();
        final role = row[3].toString();

        final accessToken = JwtService.generateToken({
          'userId': userId,
          'role': role,
        });
        final refreshToken = JwtService.generateRefreshToken(userId);

        return ApiResponse.success(
          200,
          data: {
            'accessToken': accessToken,
            'refreshToken': refreshToken,
            'user': {
              'id': row[0],
              'email': row[1],
              'role': row[3],
              'firstName': row[4] ?? '',
              'lastName': row[5] ?? '',
              'status': selectedStatusColumn ? (row[6] ?? 'pending') : 'active',
            },
          },
        );
      } catch (e) {
        print('Login error: $e');
        return ApiResponse.error(
          500,
          code: 'AUTH_LOGIN_FAILED',
          message: 'Login failed.',
          details: {'reason': e.toString()},
        );
      }
    });

    router.post('/refresh', (Request request) async {
      try {
        final body = jsonDecode(await request.readAsString());
        final String refreshToken = body['refreshToken'];

        final userId = JwtService.refreshAccessToken(refreshToken);
        if (userId != null) {
          final result = await DatabaseConfig.connection.execute(
            Sql.named(
              'SELECT id, role, status FROM users WHERE id = @id LIMIT 1',
            ),
            parameters: {'id': int.parse(userId)},
          );

          if (result.isEmpty) {
            return ApiResponse.error(
              401,
              code: 'AUTH_REFRESH_FAILED',
              message: 'Invalid refresh token.',
            );
          }

          final row = result.first;
          final status = row[2]?.toString().toLowerCase() ?? 'pending';
          if (status != 'active') {
            return ApiResponse.error(
              403,
              code: 'AUTH_ACCOUNT_INACTIVE',
              message: 'Account is not active.',
            );
          }

          final accessToken = JwtService.generateToken({
            'userId': row[0].toString(),
            'role': row[1].toString(),
          });

          return ApiResponse.success(200, data: {'accessToken': accessToken});
        }

        return ApiResponse.error(
          401,
          code: 'AUTH_REFRESH_FAILED',
          message: 'Invalid refresh token.',
        );
      } catch (e) {
        return ApiResponse.error(
          401,
          code: 'AUTH_REFRESH_FAILED',
          message: 'Token refresh failed.',
        );
      }
    });

    router.get(
      '/me',
      Pipeline().addMiddleware(authMiddleware()).addHandler((
        Request request,
      ) async {
        final user = request.context['user'] as Map<String, dynamic>;
        final result = await DatabaseConfig.connection.execute(
          Sql.named(
            'SELECT id, email, first_name, last_name, role FROM users WHERE id = @id',
          ),
          parameters: {'id': int.parse(user['userId'])},
        );

        if (result.isEmpty) {
          return ApiResponse.error(
            404,
            code: 'USER_NOT_FOUND',
            message: 'User not found.',
          );
        }

        final row = result.first;
        return ApiResponse.success(
          200,
          data: {
            'id': row[0],
            'email': row[1],
            'firstName': row[2],
            'lastName': row[3],
            'role': row[4],
          },
        );
      }),
    );

    return Router()..mount(
      '/',
      Pipeline()
          .addMiddleware(
            rateLimitMiddleware(
              maxRequests: AppConfig.authRateLimitMaxRequests,
              window: Duration(seconds: AppConfig.authRateLimitWindowSeconds),
            ),
          )
          .addHandler(router.call),
    );
  }
}
