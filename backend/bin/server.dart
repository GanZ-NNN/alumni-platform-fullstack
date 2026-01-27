import 'dart:io';
import 'dart:convert'; // 1. ເພີ່ມ import ນີ້ເພື່ອແປງ JSON
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';

late Connection connection;

// 2. Middleware ສຳລັບແກ້ບັນຫາ CORS (ໃຫ້ Web Browser ຍິງ API ໄດ້)
Middleware corsHeaders() {
  return createMiddleware(
    requestHandler: (request) {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type',
        });
      }
      return null;
    },
    responseHandler: (response) {
      return response.change(headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type',
      });
    },
  );
}

void main(List<String> args) async {
  // ເຊື່ອມຕໍ່ Database
  try {
    connection = await Connection.open(
      Endpoint(
        host: 'localhost',
        port: 5434,
        database: 'alumni_db',
        username: 'admin',
        password: 'password123',
      ),
      settings: ConnectionSettings(sslMode: SslMode.disable),
    );
    print('✅ Database Connected!');
  } catch (e) {
    print('❌ DB Error: $e');
    exit(1);
  }

  final router = Router();

  router.get('/', (Request req) => Response.ok('Alumni API is Ready!'));

  // --- API ສຳລັບ Login (ໃຊ້ງານຈິງ) ---
  router.post('/login', (Request req) async {
    try {
      // ອ່ານຂໍ້ມູນທີ່ສົ່ງມາຈາກ Flutter
      final payload = await req.readAsString();
      final body = jsonDecode(payload);
      final email = body['email'];
      final password = body['password'];

      // ກວດສອບໃນ Database
      final result = await connection.execute(
        Sql.named('SELECT id, email, first_name, role FROM users WHERE email = @email AND password = @password'),
        parameters: {'email': email, 'password': password},
      );

      if (result.isEmpty) {
        return Response.forbidden(jsonEncode({'error': 'Invalid email or password'}));
      }

      // ຖ້າຖືກຕ້ອງ, ສົ່ງຂໍ້ມູນ User ກັບໄປ
      final row = result.first;
      final userData = {
        'id': row[0].toString(), // ແປງເປັນ String ໃຫ້ໃຊ້ງ່າຍ
        'email': row[1],
        'firstName': row[2],
        'role': row[3],
      };

      return Response.ok(
        jsonEncode(userData), // ສົ່ງເປັນ JSON ແທ້ໆ
        headers: {'Content-Type': 'application/json'},
      );

    } catch (e) {
      print(e);
      return Response.internalServerError(body: 'Login Error');
    }
  });

  // --- API ດຶງ Users (ຕົວຢ່າງ) ---
  router.get('/users', (Request req) async {
    final result = await connection.execute('SELECT id, email, first_name, role FROM users');
    final users = result.map((row) => {
      'id': row[0],
      'email': row[1],
      'firstName': row[2],
      'role': row[3],
    }).toList();

    return Response.ok(
      jsonEncode(users), // ສົ່ງເປັນ JSON ແທ້ໆ
      headers: {'Content-Type': 'application/json'},
    );
  });

  // ເພີ່ມ CORS Middleware
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders()) // ໃສ່ CORS ຢູ່ນີ້
      .addHandler(router);

  // ໃຊ້ Port 8080 ຕາມຮູບເຈົ້າ
  final server = await serve(handler, InternetAddress.anyIPv4, 8080);
  print('🚀 Server listening on port ${server.port}');
}