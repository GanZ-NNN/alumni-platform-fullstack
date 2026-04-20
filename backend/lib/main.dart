import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';
import 'config/app_config.dart';
import 'config/database.dart';
import 'core/middleware/logger_middleware.dart';
import 'core/middleware/cors_middleware.dart';
import 'core/middleware/error_handler_middleware.dart';
import 'routes/api_router.dart';

Future<void> main() async {
  // Load configuration and validate
  AppConfig.validate();

  // Initialize Database connection
  await DatabaseConfig.connect();

  // Setup upload directories if they don't exist
  _setupDirectories();

  // Static file handler for uploads folder
  final staticHandler = createStaticHandler(
    'uploads',
    defaultDocument: 'index.html',
  );

  // Main Router instance
  final apiRouter = ApiRouter().router;

  // Mount API and static file routes
  final cascade = Cascade().add(apiRouter.call).add(staticHandler);

  // Global Pipeline: middleware applied in reverse order of addition
  final handler = Pipeline()
      .addMiddleware(loggerMiddleware())
      .addMiddleware(corsMiddleware())
      .addMiddleware(errorHandlerMiddleware())
      .addHandler(cascade.handler);

  // Start Server
  final bindAddress =
      InternetAddress.tryParse(AppConfig.host) ?? InternetAddress.anyIPv4;
  final server = await io.serve(
    handler,
    bindAddress,
    int.parse(AppConfig.port),
  );

  print(
    '🚀 Server listening at http://${server.address.address}:${server.port}',
  );
}

void _setupDirectories() {
  if (!Directory('uploads').existsSync()) {
    Directory('uploads').createSync();
  }
  if (!Directory('uploads/profiles').existsSync()) {
    Directory('uploads/profiles').createSync();
  }
  if (!Directory('uploads/posts').existsSync()) {
    Directory('uploads/posts').createSync();
  }
}
