import 'package:shelf/shelf.dart';
import '../error/failure.dart';
import '../http/api_response.dart';

Middleware errorHandlerMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      try {
        return await innerHandler(request);
      } catch (e, stackTrace) {
        print('🚨 Global Error Handler Caught: $e');
        print(stackTrace);

        if (e is Failure) {
          return ApiResponse.json(e.statusCode, {
            'success': false,
            'error': {'code': 'REQUEST_FAILED', 'message': e.message},
          });
        }

        return ApiResponse.error(
          500,
          code: 'INTERNAL_SERVER_ERROR',
          message: 'An internal server error occurred.',
        );
      }
    };
  };
}
