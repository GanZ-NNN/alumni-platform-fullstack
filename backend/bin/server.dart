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

// 🛑 Configuration for server IP 🛑
// Change this to your computer's local IP address
const String serverIp = '192.168.0.12';
const int serverPort = 8080;

// Helper to replace localhost with serverIp in URLs
String fixUrl(String? url) {
  if (url == null) return '';
  return url.replaceAll('localhost', serverIp);
}

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
  // 3. ADMIN ROUTER (Route ທີ່ຕ້ອງການສິດ Admin)
  // ---------------------------------------------------------
  final adminRouter = Router();

  // --- Reports ---
  adminRouter.get('/reports/majors', (Request req) async {
    final res = await connection.execute("SELECT major, COUNT(*) FROM users WHERE role = 'alumni' GROUP BY major");
    return Response.ok(jsonEncode(res.map((row) => {'major': row[0] ?? 'Unknown', 'count': row[1]}).toList()), headers: {'Content-Type': 'application/json'});
  });

  adminRouter.get('/reports/years', (Request req) async {
    final res = await connection.execute("SELECT graduation_year, COUNT(*) FROM users WHERE role = 'alumni' GROUP BY graduation_year ORDER BY graduation_year DESC");
    return Response.ok(jsonEncode(res.map((row) => {'year': row[0] ?? 'N/A', 'count': row[1]}).toList()), headers: {'Content-Type': 'application/json'});
  });

  adminRouter.get('/reports/employment', (Request req) async {
    final res = await connection.execute("SELECT work_status, COUNT(*) FROM users WHERE role = 'alumni' GROUP BY work_status");
    return Response.ok(jsonEncode(res.map((row) => {'status': row[0] ?? 'Unknown', 'count': row[1]}).toList()), headers: {'Content-Type': 'application/json'});
  });

  // --- Management ---
  adminRouter.get('/users', (Request req) async {
    final result = await connection.execute('SELECT id, email, first_name, last_name, role, status, major, graduation_year, phone_number, profile_image_url, work_status, workplace, job_position, created_at FROM users ORDER BY created_at DESC');
    final users = result.map((row) => {
      'id': row[0], 'email': row[1], 'firstName': row[2], 'lastName': row[3], 'role': row[4],
      'status': row[5], 'major': row[6], 'graduationYear': row[7], 'phoneNumber': row[8],
      'profileImageUrl': fixUrl(row[9] as String?), 'workStatus': row[10], 'workplace': row[11], 'jobPosition': row[12],
      'createdAt': row[13].toString(),
    }).toList();
    return Response.ok(jsonEncode(users), headers: {'Content-Type': 'application/json'});
  });

  adminRouter.get('/logs', (Request req) async {
    final result = await connection.execute('SELECT l.id, u.first_name, l.action, l.details, l.created_at FROM activity_logs l LEFT JOIN users u ON l.user_id = u.id ORDER BY l.created_at DESC LIMIT 100');
    final logs = result.map((row) => {'id': row[0], 'userName': row[1] ?? 'System', 'action': row[2], 'details': row[3], 'createdAt': row[4].toString()}).toList();
    return Response.ok(jsonEncode(logs), headers: {'Content-Type': 'application/json'});
  });

  adminRouter.get('/stats', (Request req) async {
    final u = await connection.execute("SELECT COUNT(*) FROM users WHERE role = 'alumni'");
    final p = await connection.execute("SELECT COUNT(*) FROM users status = 'pending' AND role = 'alumni'");
    final po = await connection.execute("SELECT COUNT(*) FROM posts");
    final j = await connection.execute("SELECT COUNT(*) FROM jobs");
    return Response.ok(jsonEncode({'totalAlumni': u[0][0], 'pendingUsers': p[0][0], 'totalPosts': po[0][0], 'totalJobs': j[0][0]}), headers: {'Content-Type': 'application/json'});
  });

  adminRouter.put('/users/<id>/approve', (Request req, String id) async {
    await connection.execute(Sql.named('UPDATE users SET status = @status WHERE id = @id'), parameters: {'status': 'active', 'id': int.parse(id)});
    await saveLog(null, 'APPROVE_USER', 'Admin approved User ID: $id');
    return Response.ok(jsonEncode({'message': 'Approved'}));
  });

  adminRouter.delete('/users/<id>', (Request req, String id) async {
    await connection.execute(Sql.named('DELETE FROM users WHERE id = @id'), parameters: {'id': int.parse(id)});
    return Response.ok(jsonEncode({'message': 'User deleted'}));
  });

  adminRouter.get('/posts', (Request req) async {
    final result = await connection.execute('SELECT id, title, content, image_url, type, created_at FROM posts ORDER BY created_at DESC');
    return Response.ok(jsonEncode(result.map((row) => {'id': row[0], 'title': row[1], 'content': row[2], 'imageUrl': fixUrl(row[3] as String?), 'type': row[4], 'createdAt': row[5].toString()}).toList()), headers: {'Content-Type': 'application/json'});
  });

  adminRouter.post('/posts', (Request req) async {
    final body = jsonDecode(await req.readAsString());
    await connection.execute(Sql.named('INSERT INTO posts (author_id, title, content, type, image_url) VALUES (@authorId, @title, @content, @type, @imageUrl)'), 
    parameters: {'authorId': body['authorId'], 'title': body['title'], 'content': body['content'], 'type': body['type'], 'imageUrl': body['imageUrl']});
    return Response.ok(jsonEncode({'message': 'Post created'}));
  });

  adminRouter.delete('/posts/<id>', (Request req, String id) async {
    await connection.execute(Sql.named('DELETE FROM posts WHERE id = @id'), parameters: {'id': int.parse(id)});
    await saveLog(null, 'DELETE_POST', 'Admin deleted Post ID: $id');
    return Response.ok(jsonEncode({'message': 'Post deleted'}));
  });

  adminRouter.delete('/jobs/<id>', (Request req, String id) async {
    await connection.execute(Sql.named('DELETE FROM jobs WHERE id = @id'), parameters: {'id': int.parse(id)});
    return Response.ok(jsonEncode({'message': 'Job deleted'}));
  });

  adminRouter.post('/notifications', (Request req) async {
    final body = jsonDecode(await req.readAsString());
    await connection.execute(Sql.named('INSERT INTO notifications (title, message, type) VALUES (@t, @m, @type)'), parameters: {'t': body['title'], 'm': body['message'], 'type': body['type'] ?? 'general'});
    return Response.ok(jsonEncode({'message': 'Notification sent'}));
  });

  adminRouter.get('/reports/workplaces', (Request req) async {
    try {
      final result = await connection.execute(
        "SELECT workplace, COUNT(*) as count FROM users "
        "WHERE role = 'alumni' AND work_status = 'Working' AND workplace IS NOT NULL "
        "GROUP BY workplace ORDER BY count DESC LIMIT 10"
      );
      final stats = result.map((row) => {'workplace': row[0], 'count': row[1]}).toList();
      return Response.ok(jsonEncode(stats), headers: {'Content-Type': 'application/json'});
    } catch (e) { return Response.internalServerError(body: 'Error: $e'); }
  });

  adminRouter.get('/reports/positions', (Request req) async {
    try {
      final result = await connection.execute(
        "SELECT job_position, COUNT(*) as count FROM users "
        "WHERE role = 'alumni' AND work_status = 'Working' AND job_position IS NOT NULL "
        "GROUP BY job_position ORDER BY count DESC LIMIT 10"
      );
      final stats = result.map((row) => {'jobPosition': row[0], 'count': row[1]}).toList();
      return Response.ok(jsonEncode(stats), headers: {'Content-Type': 'application/json'});
    } catch (e) { return Response.internalServerError(body: 'Error: $e'); }
  });

  adminRouter.put('/posts/<id>', (Request req, String id) async {
    try {
      final body = jsonDecode(await req.readAsString());
      await connection.execute(
        Sql.named('UPDATE posts SET title = @title, content = @content, type = @type, image_url = @imageUrl WHERE id = @id'),
        parameters: {'id': int.parse(id), 'title': body['title'], 'content': body['content'], 'type': body['type'], 'imageUrl': body['imageUrl'] ?? ''},
      );
      await saveLog(null, 'UPDATE_POST', 'Admin updated Post ID: $id');
      return Response.ok(jsonEncode({'message': 'Post updated successfully'}));
    } catch (e) { return Response.internalServerError(body: 'Update Error: $e'); }
  });

  final adminHandler = Pipeline().addMiddleware(isAdmin()).addHandler(adminRouter.call);

  // ---------------------------------------------------------
  // 4. MAIN ROUTER (Public & Alumni)
  // ---------------------------------------------------------
  final mainRouter = Router();

  mainRouter.get('/', (Request req) => Response.ok('Alumni API is Ready!'));

  mainRouter.post('/upload', (Request req) async {
    final contentType = req.headers['content-type'];
    if (contentType == null || !contentType.startsWith('multipart/form-data')) return Response.badRequest(body: 'Not a multipart request');
    try {
      final boundary = contentType.split('boundary=')[1];
      final collected = <int>[];
      await for (final chunk in req.read()) collected.addAll(chunk);
      final bodyString = latin1.decode(collected);
      final parts = bodyString.split('--$boundary');
      String category = 'post'; String? savedFileName;
      for (final part in parts) {
        if (part.trim().isEmpty || part == '--') continue;
        final index = part.indexOf('\r\n\r\n'); if (index == -1) continue;
        final headerPart = part.substring(0, index); final bodyPart = part.substring(index + 4);
        if (headerPart.contains('filename=')) {
          final fnMatch = RegExp(r'filename="([^"]+)"').firstMatch(headerPart);
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${fnMatch?.group(1) ?? "file.jpg"}';
          final folder = (category == 'profile') ? 'profiles' : 'posts';
          final file = File(p.join('uploads', folder, fileName));
          await file.writeAsBytes(latin1.encode(bodyPart.replaceAll(RegExp(r"\r\n$"), "")));
          savedFileName = '$folder/$fileName';
        } else if (headerPart.contains('name="category"')) category = bodyPart.trim();
      }
      return Response.ok(jsonEncode({'url': 'http://$serverIp:$serverPort/uploads/$savedFileName'}), headers: {'Content-Type': 'application/json'});
    } catch (e) { return Response.internalServerError(body: 'Upload Error'); }
  });

  mainRouter.post('/login', (Request req) async {
    try {
      final body = jsonDecode(await req.readAsString());
      final res = await connection.execute(Sql.named('SELECT id, email, password, first_name, last_name, role, status, major, graduation_year, phone_number, profile_image_url, work_status, workplace, job_position FROM users WHERE email = @email'), parameters: {'email': body['email']});
      if (res.isEmpty) return Response.forbidden(jsonEncode({'error': 'User not found'}));
      if (!DBCrypt().checkpw(body['password'], res.first[2].toString())) return Response.forbidden(jsonEncode({'error': 'Invalid password'}));
      final row = res.first;
      return Response.ok(jsonEncode({
        'id': row[0], 'email': row[1], 'firstName': row[3], 'lastName': row[4], 'role': row[5], 'status': row[6], 
        'major': row[7], 'graduationYear': row[8], 'phoneNumber': row[9], 'profileImageUrl': fixUrl(row[10] as String?), 
        'workStatus': row[11], 'workplace': row[12], 'jobPosition': row[13]
      }), headers: {'Content-Type': 'application/json'});
    } catch (e) { return Response.internalServerError(body: 'Login Error'); }
  });

  mainRouter.post('/register', (Request req) async {
    final body = jsonDecode(await req.readAsString());
    final hashed = DBCrypt().hashpw(body['password'], DBCrypt().gensalt());
    await connection.execute(Sql.named('INSERT INTO users (email, password, first_name, last_name, major, graduation_year, role) VALUES (@email, @pass, @f, @l, @m, @g, @r)'), 
    parameters: {'email': body['email'], 'pass': hashed, 'f': body['firstName'], 'l': body['lastName'], 'm': body['major'], 'g': body['graduationYear'], 'r': 'alumni'});
    return Response.ok(jsonEncode({'message': 'Registered'}));
  });

  mainRouter.put('/users/<id>', (Request req, String id) async {
    final body = jsonDecode(await req.readAsString());
    await connection.execute(Sql.named('UPDATE users SET first_name = @f, last_name = @l, phone_number = @ph, major = @m, graduation_year = @g, work_status = @ws, workplace = @wp, job_position = @pos WHERE id = @id'),
    parameters: {'id': int.parse(id), 'f': body['firstName'], 'l': body['lastName'], 'ph': body['phoneNumber'], 'm': body['major'], 'g': body['graduationYear'], 'ws': body['workStatus'], 'wp': body['workplace'], 'pos': body['jobPosition']});
    return Response.ok(jsonEncode({'message': 'Updated'}));
  });

  mainRouter.put('/users/<id>/avatar', (Request req, String id) async {
    final body = jsonDecode(await req.readAsString());
    await connection.execute(Sql.named('UPDATE users SET profile_image_url = @url WHERE id = @id'), parameters: {'url': body['profileImageUrl'], 'id': int.parse(id)});
    return Response.ok(jsonEncode({'message': 'Avatar updated'}));
  });

  mainRouter.get('/posts', (Request req) async {
    final res = await connection.execute('SELECT id, title, content, image_url, type, created_at FROM posts ORDER BY created_at DESC');
    return Response.ok(jsonEncode(res.map((r) => {'id': r[0], 'title': r[1], 'content': r[2], 'imageUrl': fixUrl(r[3] as String?), 'type': r[4], 'createdAt': r[5].toString()}).toList()), headers: {'Content-Type': 'application/json'});
  });

  mainRouter.get('/alumni', (Request req) async {
    final q = req.url.queryParameters['q'] ?? '';
    final res = await connection.execute(Sql.named("SELECT id, first_name, last_name, major, graduation_year, profile_image_url FROM users WHERE status = 'active' AND role = 'alumni' AND (first_name ILIKE @q OR major ILIKE @q)"), parameters: {'q': '%$q%'});
    return Response.ok(jsonEncode(res.map((r) => {'id': r[0], 'firstName': r[1], 'lastName': r[2], 'major': r[3], 'graduationYear': r[4], 'profileImageUrl': fixUrl(r[5] as String?)}).toList()), headers: {'Content-Type': 'application/json'});
  });

  mainRouter.get('/jobs', (Request req) async {
    final res = await connection.execute('SELECT j.id, j.company_name, j.job_title, j.description, j.location, j.salary_range, j.contact_email, j.created_at, u.first_name FROM jobs j JOIN users u ON j.posted_by_id = u.id ORDER BY j.created_at DESC');
    return Response.ok(jsonEncode(res.map((r) => {'id': r[0], 'companyName': r[1], 'jobTitle': r[2], 'description': r[3], 'location': r[4], 'salaryRange': r[5], 'contactEmail': r[6], 'createdAt': r[7].toString(), 'postedBy': r[8]}).toList()), headers: {'Content-Type': 'application/json'});
  });

  mainRouter.post('/jobs', (Request req) async {
    final body = jsonDecode(await req.readAsString());
    await connection.execute(Sql.named('INSERT INTO jobs (posted_by_id, company_name, job_title, description, location, salary_range, contact_email) VALUES (@postedBy, @company, @title, @desc, @location, @salary, @email)'), 
    parameters: {'postedBy': body['postedBy'], 'company': body['companyName'], 'title': body['jobTitle'], 'desc': body['description'], 'location': body['location'], 'salary': body['salaryRange'], 'email': body['contactEmail']});
    return Response.ok(jsonEncode({'message': 'Job posted'}));
  });

  mainRouter.get('/notifications', (Request req) async {
    final res = await connection.execute('SELECT id, title, message, type, created_at FROM notifications ORDER BY created_at DESC LIMIT 50');
    return Response.ok(jsonEncode(res.map((r) => {'id': r[0], 'title': r[1], 'message': r[2], 'type': r[3], 'createdAt': r[4].toString()}).toList()), headers: {'Content-Type': 'application/json'});
  });

  mainRouter.mount('/admin', adminHandler);
  mainRouter.mount('/uploads/', staticHandler);

  final handler = Pipeline().addMiddleware(logRequests()).addMiddleware(corsHeaders()).addHandler(mainRouter.call);
  await serve(handler, InternetAddress.anyIPv4, serverPort);
  print('🚀 Server listening on port $serverPort at http://$serverIp:$serverPort');
}

Future<void> saveLog(int? userId, String action, String details) async {
  try {
    await connection.execute(Sql.named('INSERT INTO activity_logs (user_id, action, details) VALUES (@uid, @act, @det)'), parameters: {'uid': userId, 'act': action, 'det': details});
  } catch (e) { print('Log Error: $e'); }
}
