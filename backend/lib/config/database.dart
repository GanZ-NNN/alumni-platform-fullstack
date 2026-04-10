import 'package:postgres/postgres.dart';
import 'app_config.dart';

class DatabaseConfig {
  static late Connection _connection;

  static Connection get connection => _connection;

  static Future<void> connect() async {
    try {
      _connection = await Connection.open(
        Endpoint(
          host: AppConfig.dbHost,
          port: AppConfig.dbPort,
          database: AppConfig.dbName,
          username: AppConfig.dbUser,
          password: AppConfig.dbPassword,
        ),
        settings: ConnectionSettings(sslMode: SslMode.disable),
      );
      print('✅ PostgreSQL Connection pool established!');
    } catch (e) {
      print('❌ DB Error: $e');
      rethrow;
    }
  }

  static Future<void> close() async {
    await _connection.close();
  }
}
