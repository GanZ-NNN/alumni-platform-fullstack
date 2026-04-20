import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf.dart';
import '../core/middleware/auth_middleware.dart';
import '../config/database.dart';
import '../core/http/api_response.dart';
import '../features/auth/auth_routes.dart';

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

    // Mount Auth routes (primary + backward-compatible legacy paths)
    final authHandler = AuthRoutes().router.call;
    router.mount('/auth', authHandler);
    router.mount('/', authHandler);

    // Admin-specific routes mount with auth middleware
    final adminRouter = Router();

    // adminRouter.get('/users', ...); // Placeholder for real admin controller logic

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
