import 'package:postgres/postgres.dart';
import 'package:dbcrypt/dbcrypt.dart';
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
      await _ensureSchema();
      await _ensureDefaultAdmin();
      print('✅ PostgreSQL Connection pool established!');
    } catch (e) {
      print('❌ DB Error: $e');
      rethrow;
    }
  }

  static Future<void> close() async {
    await _connection.close();
  }

  static Future<void> _ensureSchema() async {
    // Keep startup resilient for fresh databases (local/dev).
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        first_name TEXT DEFAULT '',
        last_name TEXT DEFAULT '',
        role TEXT NOT NULL DEFAULT 'alumni',
        status TEXT NOT NULL DEFAULT 'pending',
        major TEXT,
        graduation_year INT,
        phone_number TEXT,
        profile_image_url TEXT,
        created_at TIMESTAMP DEFAULT NOW()
      )
    ''');

    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS posts (
        id SERIAL PRIMARY KEY,
        author_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        type TEXT DEFAULT 'news',
        image_url TEXT,
        created_at TIMESTAMP DEFAULT NOW()
      )
    ''');

    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS jobs (
        id SERIAL PRIMARY KEY,
        company_name TEXT NOT NULL,
        job_title TEXT NOT NULL,
        description TEXT NOT NULL,
        location TEXT,
        salary_range TEXT,
        contact_email TEXT,
        posted_by_id INT REFERENCES users(id) ON DELETE SET NULL,
        created_at TIMESTAMP DEFAULT NOW()
      )
    ''');

    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS activity_logs (
        id SERIAL PRIMARY KEY,
        user_id INT REFERENCES users(id) ON DELETE SET NULL,
        action TEXT NOT NULL,
        details TEXT,
        created_at TIMESTAMP DEFAULT NOW()
      )
    ''');
  }

  static Future<void> _ensureDefaultAdmin() async {
    final existing = await _connection.execute(
      Sql.named('SELECT id FROM users WHERE email = @email LIMIT 1'),
      parameters: {'email': 'admin@example.com'},
    );
    if (existing.isNotEmpty) return;

    final hashed = DBCrypt().hashpw('adminpass', DBCrypt().gensalt());
    await _connection.execute(
      Sql.named('''
        INSERT INTO users (email, password, first_name, last_name, role, status)
        VALUES (@email, @password, @firstName, @lastName, @role, @status)
      '''),
      parameters: {
        'email': 'admin@example.com',
        'password': hashed,
        'firstName': 'Default',
        'lastName': 'Admin',
        'role': 'admin',
        'status': 'active',
      },
    );
    print('✅ Default admin created: admin@example.com');
  }
}
