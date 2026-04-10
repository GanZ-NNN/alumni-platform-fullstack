import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../error/failure.dart';

Middleware errorHandlerMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      try {
        return await innerHandler(request);
      } catch (e, stackTrace) {
        print('🚨 Global Error Handler Caught: $e');
        print(stackTrace);

        if (e is Failure) {
          return Response(
            e.statusCode,
            body: jsonEncode({'error': e.message}),
            headers: {'Content-Type': 'application/json'},
          );
        }

        return Response.internalServerError(
          body: jsonEncode({'error': 'An internal server error occurred.'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    };
  };
}
