import 'package:shelf/shelf.dart';
import '../http/api_response.dart';

class _RateLimitBucket {
  _RateLimitBucket({required this.windowStartedAt, required this.requestCount});

  DateTime windowStartedAt;
  int requestCount;
}

Middleware rateLimitMiddleware({
  required int maxRequests,
  required Duration window,
}) {
  final buckets = <String, _RateLimitBucket>{};

  return (Handler innerHandler) {
    return (Request request) async {
      final now = DateTime.now().toUtc();
      final key =
          request.headers['x-forwarded-for'] ??
          request.context['shelf.io.connection_info']?.toString() ??
          'anonymous';

      final bucket = buckets.putIfAbsent(
        key,
        () => _RateLimitBucket(windowStartedAt: now, requestCount: 0),
      );

      final elapsed = now.difference(bucket.windowStartedAt);
      if (elapsed >= window) {
        bucket.windowStartedAt = now;
        bucket.requestCount = 0;
      }

      bucket.requestCount += 1;
      if (bucket.requestCount > maxRequests) {
        return ApiResponse.error(
          429,
          code: 'RATE_LIMIT_EXCEEDED',
          message: 'Too many requests. Please retry later.',
          headers: {'Retry-After': window.inSeconds.toString()},
        );
      }

      return innerHandler(request);
    };
  };
}
