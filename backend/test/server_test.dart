import 'package:test/test.dart';
import 'package:backend/core/auth/jwt_service.dart';

void main() {
  test('Refresh token payload uses refresh token type', () {
    final refreshToken = JwtService.generateRefreshToken('123');
    final refreshUserId = JwtService.refreshAccessToken(refreshToken);

    expect(refreshUserId, '123');
  });
}
