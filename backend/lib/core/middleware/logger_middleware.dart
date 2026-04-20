import 'package:shelf/shelf.dart';

Middleware loggerMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final requestId = DateTime.now().microsecondsSinceEpoch.toString();
      final startTime = DateTime.now();
      Response response;
      try {
        response = await innerHandler(request);
      } catch (_) {
        final duration = DateTime.now().difference(startTime);
        print(
          '[${DateTime.now().toIso8601String()}] '
          'request_id=$requestId method=${request.method} '
          'path=${request.requestedUri.path} status=500 duration_ms=${duration.inMilliseconds}',
        );
        rethrow;
      }

      final duration = DateTime.now().difference(startTime);
      print(
        '[${DateTime.now().toIso8601String()}] '
        'request_id=$requestId method=${request.method} '
        'path=${request.requestedUri.path} status=${response.statusCode} '
        'duration_ms=${duration.inMilliseconds}',
      );

      return response.change(headers: {'x-request-id': requestId});
    };
  };
}
