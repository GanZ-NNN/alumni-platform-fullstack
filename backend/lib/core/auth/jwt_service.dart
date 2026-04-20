import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../../config/app_config.dart';

class JwtService {
  static final String _secret = AppConfig.jwtSecret;

  static String generateToken(Map<String, dynamic> payload) {
    final jwt = JWT(payload);
    return jwt.sign(
      SecretKey(_secret),
      expiresIn: Duration(seconds: AppConfig.jwtExpiration),
    );
  }

  static String generateRefreshToken(String userId) {
    final jwt = JWT({'userId': userId, 'tokenType': 'refresh'});
    return jwt.sign(
      SecretKey(_secret),
      expiresIn: Duration(seconds: AppConfig.refreshTokenExpiration),
    );
  }

  static Map<String, dynamic>? verifyToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_secret));
      return jwt.payload as Map<String, dynamic>;
    } on JWTExpiredException {
      print('JWT Token expired');
      rethrow;
    } on JWTException catch (ex) {
      print('JWT Token verification failed: ${ex.message}');
      return null;
    }
  }

  static String? refreshAccessToken(String refreshToken) {
    final payload = verifyToken(refreshToken);
    if (payload != null &&
        payload.containsKey('userId') &&
        payload['tokenType']?.toString() == 'refresh') {
      return payload['userId']?.toString();
    }
    return null;
  }
}
