import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';
import 'package:dbcrypt/dbcrypt.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:path/path.dart' as p;

late Connection connection;

// --- [Middleware: CORS] ---
Middleware corsHeaders() {
  return createMiddleware(
    requestHandler: (request) {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, x-user-role, Authorization',
        });
      }
      return null;
    },
    responseHandler: (response) {
      return response.change(headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type, x-user-role, Authorization',
      });
    },
  );
}

// --- [Middleware: Admin Check] ---
Middleware isAdmin() {
  return createMiddleware(
    requestHandler: (Request request) {
      final role = request.headers['x-user-role']?.toLowerCase();
      if (role != 'admin') {
        return Response.forbidden(
          jsonEncode({'error': 'Access Denied: Admin only'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      return null;
    },
  );
}

void main(List<String> args) async {
  // 1. Database Connection
  try {
    connection = await Connection.open(
      Endpoint(host: 'localhost', port: 5434, database: 'alumni_db', username: 'admin', password: 'password123'),
      settings: ConnectionSettings(sslMode: SslMode.disable),
    );
    print('✅ Database Connected successfully!');
  } catch (e) {
    print('❌ DB Error: $e');
    exit(1);
  }

  if (!Directory('uploads').existsSync()) Directory('uploads').createSync();
  if (!Directory('uploads/profiles').existsSync()) Directory('uploads/profiles').createSync();
  if (!Directory('uploads/posts').existsSync()) Directory('uploads/posts').createSync();

  final staticHandler = createStaticHandler('uploads', defaultDocument: 'index.html');

  // ---------------------------------------------------------
  // 3. ADMIN ROUTER
  // ---------------------------------------------------------
  final adminRouter = Router();

  adminRouter.get('/users', (Request req) async {
    final result = await connection.execute('SELECT id, email, first_name, last_name, role, status, major, graduation_year, phone_number, profile_image_url, created_at FROM users ORDER BY created_at DESC');
    final users = result.map((row) => {
      // Correct column indexes for the SELECT above (0..10)
      'id': row[0],
      'email': row[1],
      'firstName': row[2],
      'lastName': row[3],
      'role': row[4],
      'status': row[5],
      'major': row[6],
      'graduationYear': row[7],
      'phoneNumber': row[8],
      'profileImageUrl': row[9],
      'createdAt': row[10].toString(),
    }).toList();
    return Response.ok(jsonEncode(users), headers: {'Content-Type': 'application/json'});
  });

  adminRouter.get('/logs', (Request req) async {
    final result = await connection.execute('SELECT l.id, u.first_name, l.action, l.details, l.created_at FROM activity_logs l LEFT JOIN users u ON l.user_id = u.id ORDER BY l.created_at DESC LIMIT 100');
    final logs = result.map((row) => {'id': row[0], 'userName': row[1] ?? 'System/Admin', 'action': row[2], 'details': row[3], 'createdAt': row[4].toString()}).toList();
    return Response.ok(jsonEncode(logs), headers: {'Content-Type': 'application/json'});
  });

  adminRouter.put('/users/<id>/approve', (Request req, String id) async {
    await connection.execute(Sql.named('UPDATE users SET status = @status WHERE id = @id'), parameters: {'status': 'active', 'id': int.parse(id)});
    await saveLog(null, 'APPROVE_USER', 'Admin approved User ID: $id');
    return Response.ok(jsonEncode({'message': 'User approved'}));
  });

  adminRouter.delete('/users/<id>', (Request req, String id) async {
    await connection.execute(Sql.named('DELETE FROM users WHERE id = @id'), parameters: {'id': int.parse(id)});
    return Response.ok(jsonEncode({'message': 'User deleted'}));
  });

  adminRouter.post('/posts', (Request req) async {
    final body = jsonDecode(await req.readAsString());
    await connection.execute(Sql.named('INSERT INTO posts (author_id, title, content, type, image_url) VALUES (@authorId, @title, @content, @type, @imageUrl)'), 
    parameters: {'authorId': body['authorId'], 'title': body['title'], 'content': body['content'], 'type': body['type'], 'imageUrl': body['imageUrl']});
    return Response.ok(jsonEncode({'message': 'Post created'}));
  });

  adminRouter.get('/stats', (Request req) async {
    try {
      final u = await connection.execute("SELECT COUNT(*) FROM users WHERE role = 'alumni'");
      final p = await connection.execute("SELECT COUNT(*) FROM users WHERE status = 'pending' AND role = 'alumni'");
      final po = await connection.execute("SELECT COUNT(*) FROM posts");
      final j = await connection.execute("SELECT COUNT(*) FROM jobs");
      return Response.ok(jsonEncode({'totalAlumni': u[0][0], 'pendingUsers': p[0][0], 'totalPosts': po[0][0], 'totalJobs': j[0][0]}), headers: {'Content-Type': 'application/json'});
    } catch (e) { return Response.internalServerError(body: 'Stats Error'); }
  });

  final adminHandler = Pipeline().addMiddleware(isAdmin()).addHandler(adminRouter.call);

  // ---------------------------------------------------------
  // 4. MAIN ROUTER
  // ---------------------------------------------------------
  final mainRouter = Router();

  mainRouter.get('/', (Request req) => Response.ok('Alumni API is Ready!'));

  // API Upload ຮູບ
  mainRouter.post('/upload', (Request req) async {
    final contentType = req.headers['content-type'];
    if (contentType == null || !contentType.startsWith('multipart/form-data')) {
      return Response.badRequest(body: jsonEncode({'error': 'Not a multipart request'}), headers: {'Content-Type': 'application/json'});
    }

    try {
      final boundary = contentType.split('boundary=')[1];
      final collected = <int>[];
      await for (final chunk in req.read()) { collected.addAll(chunk); }
      final bodyString = latin1.decode(collected);
      final parts = bodyString.split('--$boundary');

      String category = 'post'; 
      String? savedFileName;

      for (final part in parts) {
        if (part.trim().isEmpty || part == '--') continue;
        final index = part.indexOf('\r\n\r\n');
        if (index == -1) continue;
        final headerPart = part.substring(0, index);
        final bodyPart = part.substring(index + 4);

        if (headerPart.contains('filename=')) {
          final fnMatch = RegExp(r'filename="([^"]+)"').firstMatch(headerPart);
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${fnMatch?.group(1) ?? "file.jpg"}';
          final folder = (category == 'profile') ? 'profiles' : 'posts';
          final file = File(p.join('uploads', folder, fileName));
          await file.writeAsBytes(latin1.encode(bodyPart.replaceAll(RegExp(r"\r\n$"), "")));
          savedFileName = '$folder/$fileName';
        } else if (headerPart.contains('name="category"')) {
          category = bodyPart.trim();
        }
      }

      if (savedFileName == null) return Response.badRequest(body: 'Upload failed');
      return Response.ok(jsonEncode({'url': 'http://localhost:8081/uploads/$savedFileName'}), headers: {'Content-Type': 'application/json'});
    } catch (e) { return Response.internalServerError(body: 'Upload Error: $e'); }
  });

mainRouter.post('/login', (Request req) async {
    try {
      final payload = await req.readAsString();
      final body = jsonDecode(payload);
      final email = body['email'];
      final password = body['password'];

      print('🔑 Login Attempt for: $email');

      // 1. SELECT ຂໍ້ມູນໃຫ້ຄົບທຸກ Column (ທັງໝົດ 11 Columns)
      // Index: 0:id, 1:email, 2:password, 3:f_name, 4:l_name, 5:role, 6:status, 7:major, 8:grad_year, 9:phone, 10:profile_url
      final res = await connection.execute(
        Sql.named(
          'SELECT id, email, password, first_name, last_name, role, status, major, graduation_year, phone_number, profile_image_url '
          'FROM users WHERE email = @email'
        ), 
        parameters: {'email': email}
      );

      // 2. ກວດສອບວ່າມີ User ນີ້ຫຼືບໍ່
      if (res.isEmpty) {
        print('❌ Login Failed: User not found');
        return Response.forbidden(jsonEncode({'error': 'User not found'}));
      }

      final row = res.first;

      // 3. ກວດສອບລະຫັດຜ່ານດ້ວຍ BCrypt
      final hashedPasswordInDB = row[2].toString();
      if (!DBCrypt().checkpw(password, hashedPasswordInDB)) {
        print('❌ Login Failed: Invalid password');
        return Response.forbidden(jsonEncode({'error': 'Invalid password'}));
      }

      print('✅ Login Success for: ${row[3]}');

      // 4. ບັນທຶກ Activity Log
      await saveLog(row[0] as int, 'LOGIN', 'User logged into the system');

      // 5. ສົ່ງ JSON ກັບໄປຫາ Frontend (ຕ້ອງໃຊ້ Key ໃຫ້ກົງກັບ UserModel.fromMap)
      return Response.ok(
        jsonEncode({
          'id': row[0],
          'email': row[1],
          'firstName': row[3],
          'lastName': row[4],
          'role': row[5],
          'status': row[6],
          'major': row[7],
          'graduationYear': row[8],
          'phoneNumber': row[9],      // ✅ Index 9
          'profileImageUrl': row[10], // ✅ Index 10
        }), 
        headers: {'Content-Type': 'application/json'}
      );

    } catch (e) { 
      print('❌ Server Error during login: $e');
      return Response.internalServerError(body: jsonEncode({'error': 'Login Error', 'details': e.toString()})); 
    }
  });

  mainRouter.post('/register', (Request req) async {
    try {
      final body = jsonDecode(await req.readAsString());
      final hashed = DBCrypt().hashpw(body['password'], DBCrypt().gensalt());
      await connection.execute(Sql.named('INSERT INTO users (email, password, first_name, last_name, major, graduation_year, role) VALUES (@email, @pass, @f, @l, @m, @g, @r)'), 
      parameters: {'email': body['email'], 'pass': hashed, 'f': body['firstName'], 'l': body['lastName'], 'm': body['major'], 'g': body['graduationYear'], 'r': 'alumni'});
      return Response.ok(jsonEncode({'message': 'Registered'}));
    } catch (e) { return Response.internalServerError(body: 'Register Error'); }
  });

// --- API ອັບເດດຮູບໂປຣໄຟລ໌ (Update Avatar) ---
  mainRouter.put('/users/<id>/avatar', (Request req, String id) async {
    try {
      final payload = await req.readAsString();
      final body = jsonDecode(payload);
      final imageUrl = body['profileImageUrl']; // ຮັບ URL ທີ່ໄດ້ຈາກ API /upload

      print('📸 Request Update Avatar - ID: $id, URL: $imageUrl');

      if (imageUrl == null || imageUrl.toString().isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'profileImageUrl is required'}),
          headers: {'Content-Type': 'application/json'}
        );
      }

      // 🛑 ທຳການ UPDATE ລົງ Database (ໝັ້ນໃຈວ່າຊື່ Column ແມ່ນ profile_image_url)
      await connection.execute(
        Sql.named('UPDATE users SET profile_image_url = @url WHERE id = @id'),
        parameters: {
          'url': imageUrl,
          'id': int.parse(id),
        },
      );

      print('✅ Database Updated for User ID: $id');
      
      // ບັນທຶກ Log
      await saveLog(int.parse(id), 'UPDATE_AVATAR', 'User updated profile picture');

      return Response.ok(
        jsonEncode({'message': 'Avatar updated successfully', 'url': imageUrl}),
        headers: {'Content-Type': 'application/json'}
      );
    } catch (e) {
      print('❌ Update Avatar Error: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Server Error', 'details': e.toString()}),
        headers: {'Content-Type': 'application/json'}
      );
    }
  });

  mainRouter.put('/users/<id>', (Request req, String id) async {
    final body = jsonDecode(await req.readAsString());
    await connection.execute(
      Sql.named('UPDATE users SET first_name = @firstName, last_name = @lastName, phone_number = @phoneNumber, major = @major, graduation_year = @gradYear WHERE id = @id'),
      parameters: {
        'id': int.parse(id),
        'firstName': body['firstName'],
        'lastName': body['lastName'],
        'phoneNumber': body['phoneNumber'], 
        'major': body['major'],
        'gradYear': body['graduationYear']
      }
    );
    return Response.ok(jsonEncode({'message': 'Updated'}));
  });

  mainRouter.get('/posts', (Request req) async {
    final res = await connection.execute('SELECT id, title, content, type, created_at FROM posts ORDER BY created_at DESC');
    return Response.ok(jsonEncode(res.map((row) => {'id': row[0], 'title': row[1], 'content': row[2], 'type': row[3], 'createdAt': row[4].toString()}).toList()), headers: {'Content-Type': 'application/json'});
  });

  mainRouter.get('/jobs', (Request req) async {
    final res = await connection.execute('SELECT j.id, j.company_name, j.job_title, j.description, j.location, j.salary_range, j.contact_email, j.created_at, u.first_name FROM jobs j JOIN users u ON j.posted_by_id = u.id ORDER BY j.created_at DESC');
    return Response.ok(jsonEncode(res.map((r) => {'id': r[0], 'companyName': r[1], 'jobTitle': r[2], 'description': r[3], 'location': r[4], 'salaryRange': r[5], 'contactEmail': r[6], 'createdAt': r[7].toString(), 'postedBy': r[8]}).toList()), headers: {'Content-Type': 'application/json'});
  });

  mainRouter.mount('/admin', adminHandler);
  mainRouter.mount('/uploads/', staticHandler);

  final handler = Pipeline().addMiddleware(logRequests()).addMiddleware(corsHeaders()).addHandler(mainRouter.call);
  await serve(handler, InternetAddress.anyIPv4, 8080);
  print('🚀 Server listening on port 8080');
}

Future<void> saveLog(int? userId, String action, String details) async {
  try {
    await connection.execute(Sql.named('INSERT INTO activity_logs (user_id, action, details) VALUES (@uid, @act, @det)'), parameters: {'uid': userId, 'act': action, 'det': details});
  } catch (e) { print('Log Error: $e'); }
}