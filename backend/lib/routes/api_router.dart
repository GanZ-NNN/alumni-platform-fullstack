import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf.dart';
import 'dart:convert';
import '../core/middleware/auth_middleware.dart';
import '../features/auth/auth_routes.dart';

class ApiRouter {
  Router get router {
    final router = Router();

    // Health check route
    router.get('/', (Request req) => Response.ok('Alumni API is Healthy!'));

    // Example Route
    router.get('/health', (Request req) => Response.ok(
      jsonEncode({'status': 'healthy', 'timestamp': DateTime.now().toIso8601String()}),
      headers: {'Content-Type': 'application/json'}
    ));

    // Mount Auth routes
    router.mount('/auth', AuthRoutes().router.call);

    // Admin-specific routes mount with auth middleware
    final adminRouter = Router();
    
    // adminRouter.get('/users', ...); // Placeholder for real admin controller logic

    router.mount('/admin', Pipeline()
        .addMiddleware(authMiddleware()) // Must be authenticated
        .addMiddleware(isAdmin())         // Must be admin
        .addHandler(adminRouter.call));

    return router;
  }
}
