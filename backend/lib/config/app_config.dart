import 'package:dotenv/dotenv.dart';

class AppConfig {
  static final DotEnv _env = DotEnv(includePlatformEnvironment: true)
    ..load(['.env']);

  static String get appEnv =>
      (_env['APP_ENV'] ?? 'development').trim().toLowerCase();
  static bool get isProduction => appEnv == 'production';

  static String get host => (_env['HOST'] ?? '0.0.0.0').trim();
  static String get port => _env['PORT'] ?? '8080';
  static String get dbHost => _env['DB_HOST'] ?? 'localhost';
  static int get dbPort => int.tryParse(_env['DB_PORT'] ?? '5434') ?? 5434;
  static String get dbName => _env['DB_NAME'] ?? 'alumni_db';
  static String get dbUser => _env['DB_USER'] ?? 'admin';
  static String get dbPassword => _env['DB_PASSWORD'] ?? 'password123';
  static String get jwtSecret =>
      _env['JWT_SECRET'] ?? 'your_super_secret_key_change_in_production';
  static int get jwtExpiration =>
      int.tryParse(_env['JWT_EXPIRATION'] ?? '86400') ?? 86400;
  static int get refreshTokenExpiration =>
      int.tryParse(_env['REFRESH_TOKEN_EXPIRATION'] ?? '2592000') ?? 2592000;
  static int get authRateLimitWindowSeconds =>
      int.tryParse(_env['AUTH_RATE_LIMIT_WINDOW_SECONDS'] ?? '60') ?? 60;
  static int get authRateLimitMaxRequests =>
      int.tryParse(_env['AUTH_RATE_LIMIT_MAX_REQUESTS'] ?? '15') ?? 15;
  static List<String> get allowedOrigins =>
      (_env['ALLOWED_ORIGINS'] ?? 'http://localhost:3000,http://localhost:8080')
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

  static String get databaseUrl =>
      'postgresql://$dbUser:$dbPassword@$dbHost:$dbPort/$dbName';

  static String get emailUsername => _env['EMAIL_USERNAME'] ?? '';
  static String get emailPassword => _env['EMAIL_PASSWORD'] ?? '';

  static void validate() {
    final rawJwtSecret = (_env['JWT_SECRET'] ?? '').trim();
    final isDefaultJwtSecret =
        rawJwtSecret.isEmpty ||
        rawJwtSecret == 'your_super_secret_key_change_in_production';
    if (isProduction && isDefaultJwtSecret) {
      throw StateError(
        'JWT_SECRET must be set to a strong value when APP_ENV=production.',
      );
    }

    if (!isProduction && isDefaultJwtSecret) {
      print(
        '⚠️  Development mode: using default JWT secret. Set JWT_SECRET in .env for safety.',
      );
    }
  }
}
