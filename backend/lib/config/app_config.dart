import 'dart:io';
import 'package:dotenv/dotenv.dart';

class AppConfig {
  static final DotEnv _env = DotEnv(includePlatformEnvironment: true)..load(['.env']);

  static String get port => _env['PORT'] ?? '8080';
  static String get dbHost => _env['DB_HOST'] ?? 'localhost';
  static int get dbPort => int.parse(_env['DB_PORT'] ?? '5434');
  static String get dbName => _env['DB_NAME'] ?? 'alumni_db';
  static String get dbUser => _env['DB_USER'] ?? 'admin';
  static String get dbPassword => _env['DB_PASSWORD'] ?? 'password123';
  static String get jwtSecret => _env['JWT_SECRET'] ?? 'your_super_secret_key_change_in_production';
  static int get jwtExpiration => int.parse(_env['JWT_EXPIRATION'] ?? '86400');
  static int get refreshTokenExpiration => int.parse(_env['REFRESH_TOKEN_EXPIRATION'] ?? '2592000');
  static List<String> get allowedOrigins => (_env['ALLOWED_ORIGINS'] ?? '*').split(',');
  static String get serverIp => _env['SERVER_IP'] ?? 'localhost';

  static void validate() {
    if (_env['JWT_SECRET'] == null) {
      print('Warning: JWT_SECRET not found in .env, using default.');
    }
  }
}
