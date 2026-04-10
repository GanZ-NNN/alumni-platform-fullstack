import 'package:shelf/shelf.dart';

Middleware loggerMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final startTime = DateTime.now();
      final response = await innerHandler(request);
      final duration = DateTime.now().difference(startTime);

      print('[${DateTime.now().toIso8601String()}] ${request.method} ${request.requestedUri.path} '
          '(${response.statusCode}) took ${duration.inMilliseconds}ms');

      return response;
    };
  };
}
