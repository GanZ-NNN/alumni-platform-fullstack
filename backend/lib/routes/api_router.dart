import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf.dart';
import 'dart:convert';
import 'package:postgres/postgres.dart';
import '../core/middleware/auth_middleware.dart';
import '../config/database.dart';
import '../core/http/api_response.dart';
import '../features/auth/auth_routes.dart';
import '../features/admin/admin_routes.dart';
import '../features/jobs/job_routes.dart';
import '../features/posts/post_routes.dart';

class ApiRouter {
  Router get router {
    final router = Router();

    // Health check route
    router.get('/', (Request req) => Response.ok('Alumni API is Healthy!'));

    // Example Route
    router.get('/health', (Request req) async {
      try {
        await DatabaseConfig.connection.execute('SELECT 1');
        return ApiResponse.success(
          200,
          data: {
            'status': 'healthy',
            'database': 'up',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      } catch (e) {
        return ApiResponse.error(
          503,
          code: 'HEALTH_CHECK_FAILED',
          message: 'Database ping failed.',
          details: {'reason': e.toString()},
        );
      }
    });

    // Mount Auth routes
    final authHandler = AuthRoutes().router.call;
    router.mount('/auth', authHandler);
    router.mount('/', authHandler);

    // Mount Job routes (Public GET, Authenticated POST)
    router.mount('/jobs', JobRoutes().router.call);

    // Mount Post routes (Public GET, Authenticated POST)
    router.mount('/posts', PostRoutes().router.call);

    router.get('/alumni', (Request request) async {
      final params = request.url.queryParameters;
      final name = params['name'] ?? '';
      final major = params['major'] ?? '';
      final year = params['year'] ?? '';

      final result = await DatabaseConfig.connection.execute(
        Sql.named('''
        SELECT id, email, first_name, last_name, role, status, major, graduation_year, phone_number, profile_image_url, job_position, workplace, work_status
        FROM users
        WHERE role = 'alumni' AND status = 'active'
        AND (first_name ILIKE @name OR last_name ILIKE @name)
        AND (major ILIKE @major OR @major = '')
        AND (graduation_year::text ILIKE @year OR @year = '')
        ORDER BY first_name ASC
      '''),
        parameters: {'name': '%$name%', 'major': major, 'year': year},
      );

      final alumni = result.map((r) {
        return {
          'id': r[0],
          'email': r[1],
          'firstName': r[2],
          'lastName': r[3],
          'role': r[4],
          'status': r[5],
          'major': r[6],
          'graduationYear': r[7],
          'phoneNumber': r[8],
          'profileImageUrl': r[9],
          'jobPosition': r[10],
          'workplace': r[11],
          'workStatus': r[12] ?? 'Unemployed',
        };
      }).toList();

      return Response.ok(
        jsonEncode(alumni),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // Admin-specific routes mount with auth middleware
    final adminRouter = AdminRoutes().router;

    router.mount(
      '/admin',
      Pipeline()
          .addMiddleware(authMiddleware()) // Must be authenticated
          .addMiddleware(isAdmin()) // Must be admin
          .addHandler(adminRouter.call),
    );

    return router;
  }
}
