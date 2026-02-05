import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';

late Connection connection;

Middleware corsHeaders() {
  return createMiddleware(
    requestHandler: (request) {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, x-user-role',
        });
      }
      return null;
    },
    responseHandler: (response) {
      return response.change(headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type, x-user-role',
      });
    },
  );
}

Middleware isAdmin() {
  return createMiddleware(
    requestHandler: (Request request) {
      final role = request.headers['x-user-role']?.toLowerCase();
      if (role != 'admin') {
        return Response.forbidden(jsonEncode({'error': 'Access Denied: Admin only'}), headers: {'Content-Type': 'application/json'});
      }
      return null;
    },
  );
}

void main(List<String> args) async {
  try {
    connection = await Connection.open(
      Endpoint(
        host: 'localhost',
        port: 5434, // 🛑 ຖ້າ DB ບໍ່ຕິດ ໃຫ້ລອງປ່ຽນເປັນ 5433 🛑
        database: 'alumni_db',
        username: 'admin',
        password: 'password123',
      ),
      settings: ConnectionSettings(sslMode: SslMode.disable),
    );
    print('✅ Database Connected successfully!');
  } catch (e) {
    print('❌ DB Error: $e');
    exit(1);
  }

  final adminRouter = Router();

  adminRouter.get('/users', (Request req) async {
    final result = await connection.execute('SELECT id, email, first_name, last_name, role, status, major, graduation_year, phone_number, created_at FROM users ORDER BY created_at DESC');
    final users = result.map((row) => {'id': row[0], 'email': row[1], 'firstName': row[2], 'lastName': row[3], 'role': row[4], 'status': row[5], 'major': row[6], 'graduationYear': row[7], 'phoneNumber': row[8], 'createdAt': row[9].toString()}).toList();
    return Response.ok(jsonEncode(users), headers: {'Content-Type': 'application/json'});
  });

  adminRouter.put('/users/<id>/approve', (Request req, String id) async {
    await connection.execute(Sql.named('UPDATE users SET status = @status WHERE id = @id'), parameters: {'status': 'active', 'id': int.parse(id)});
    return Response.ok(jsonEncode({'message': 'User approved'}), headers: {'Content-Type': 'application/json'});
  });

  adminRouter.delete('/users/<id>', (Request req, String id) async {
    await connection.execute(Sql.named('DELETE FROM users WHERE id = @id'), parameters: {'id': int.parse(id)});
    return Response.ok(jsonEncode({'message': 'User deleted'}), headers: {'Content-Type': 'application/json'});
  });

  adminRouter.post('/posts', (Request req) async {
    final body = jsonDecode(await req.readAsString());
    await connection.execute(Sql.named('INSERT INTO posts (author_id, title, content, type, image_url) VALUES (@authorId, @title, @content, @type, @imageUrl)'), 
    parameters: {'authorId': body['authorId'], 'title': body['title'], 'content': body['content'], 'type': body['type'], 'imageUrl': body['imageUrl']});
    return Response.ok(jsonEncode({'message': 'Post created'}), headers: {'Content-Type': 'application/json'});
  });

  adminRouter.get('/posts', (Request req) async {
    final result = await connection.execute('SELECT id, title, content, type, created_at FROM posts ORDER BY created_at DESC');
    final posts = result.map((row) => {'id': row[0], 'title': row[1], 'content': row[2], 'type': row[3], 'createdAt': row[4].toString()}).toList();
    return Response.ok(jsonEncode(posts), headers: {'Content-Type': 'application/json'});
  });

  adminRouter.delete('/posts/<id>', (Request req, String id) async {
    await connection.execute(Sql.named('DELETE FROM posts WHERE id = @id'), parameters: {'id': int.parse(id)});
    return Response.ok(jsonEncode({'message': 'Post deleted'}), headers: {'Content-Type': 'application/json'});
  });

  adminRouter.delete('/jobs/<id>', (Request req, String id) async {
    await connection.execute(Sql.named('DELETE FROM jobs WHERE id = @id'), parameters: {'id': int.parse(id)});
    return Response.ok(jsonEncode({'message': 'Job deleted'}), headers: {'Content-Type': 'application/json'});
  });

  // --- API ດຶງສະຖິຕິລວມ (Admin Dashboard) ---
  adminRouter.get('/stats', (Request req) async {
    try {
      // ນັບຈຳນວນຈາກ Table ຕ່າງໆ
      final usersCount = await connection.execute("SELECT COUNT(*) FROM users WHERE role = 'alumni'");
      final pendingCount = await connection.execute("SELECT COUNT(*) FROM users WHERE status = 'pending'");
      final postsCount = await connection.execute("SELECT COUNT(*) FROM posts");
      final jobsCount = await connection.execute("SELECT COUNT(*) FROM jobs");

      final stats = {
        'totalAlumni': usersCount.first[0],
        'pendingUsers': pendingCount.first[0],
        'totalPosts': postsCount.first[0],
        'totalJobs': jobsCount.first[0],
      };

      return Response.ok(jsonEncode(stats), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: 'Error fetching stats: $e');
    }
  });

  // --- API ດຶງສະຖິຕິລວມ (Dashboard Stats) ---
  adminRouter.get('/stats', (Request req) async {
    try {
      // 1. ນັບຈຳນວນ Alumni ທັງໝົດ
      final alumniRes = await connection.execute("SELECT COUNT(*) FROM users WHERE role = 'alumni'");
      // 2. ນັບຈຳນວນຄົນທີ່ລໍຖ້າອະນຸມັດ
      final pendingRes = await connection.execute("SELECT COUNT(*) FROM users WHERE status = 'pending' AND role = 'alumni'");
      // 3. ນັບຈຳນວນຂ່າວ
      final postsRes = await connection.execute("SELECT COUNT(*) FROM posts");
      // 4. ນັບຈຳນວນວຽກ
      final jobsRes = await connection.execute("SELECT COUNT(*) FROM jobs");

      // ແປງຜົນຮັບ (postgres v3 ສົ່ງມາເປັນ List ຂອງ Rows)
      final stats = {
        'totalAlumni': alumniRes[0][0],
        'pendingUsers': pendingRes[0][0],
        'totalPosts': postsRes[0][0],
        'totalJobs': jobsRes[0][0],
      };

      return Response.ok(jsonEncode(stats), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      print('Stats Error: $e');
      return Response.internalServerError(body: 'Error fetching stats');
    }
  });

  final adminHandler = Pipeline().addMiddleware(isAdmin()).addHandler(adminRouter.call);

  final mainRouter = Router();

  mainRouter.get('/', (Request req) => Response.ok('Alumni API is Ready!'));

  mainRouter.post('/login', (Request req) async {
    final body = jsonDecode(await req.readAsString());
    final result = await connection.execute(Sql.named('SELECT id, email, first_name, last_name, role, status, major, graduation_year, phone_number FROM users WHERE email = @email AND password = @password'), parameters: {'email': body['email'], 'password': body['password']});
    if (result.isEmpty) return Response.forbidden(jsonEncode({'error': 'Invalid login'}));
    final row = result.first;
    return Response.ok(jsonEncode({'id': row[0], 'email': row[1], 'firstName': row[2], 'lastName': row[3], 'role': row[4], 'status': row[5], 'major': row[6], 'graduationYear': row[7], 'phoneNumber': row[8]}), headers: {'Content-Type': 'application/json'});
  });

  mainRouter.post('/register', (Request req) async {
    final body = jsonDecode(await req.readAsString());
    await connection.execute(Sql.named('INSERT INTO users (email, password, first_name, last_name, major, graduation_year, role) VALUES (@email, @password, @firstName, @lastName, @major, @gradYear, @role)'), parameters: {'email': body['email'], 'password': body['password'], 'firstName': body['firstName'], 'lastName': body['lastName'], 'major': body['major'], 'gradYear': body['graduationYear'], 'role': 'alumni'});
    return Response.ok(jsonEncode({'message': 'Registered'}), headers: {'Content-Type': 'application/json'});
  });

  mainRouter.put('/users/<id>', (Request req, String id) async {
    final body = jsonDecode(await req.readAsString());
    await connection.execute(Sql.named('UPDATE users SET first_name = @firstName, last_name = @lastName, phone_number = @phoneNumber, major = @major, graduation_year = @gradYear WHERE id = @id'), parameters: {'id': int.parse(id), 'firstName': body['firstName'], 'lastName': body['lastName'], 'phoneNumber': body['phoneNumber'], 'major': body['major'], 'gradYear': body['graduationYear']});
    return Response.ok(jsonEncode({'message': 'Updated'}), headers: {'Content-Type': 'application/json'});
  });

  mainRouter.get('/posts', (Request req) async {
    final result = await connection.execute('SELECT id, title, content, type, created_at FROM posts ORDER BY created_at DESC');
    final posts = result.map((row) => {'id': row[0], 'title': row[1], 'content': row[2], 'type': row[3], 'createdAt': row[4].toString()}).toList();
    return Response.ok(jsonEncode(posts), headers: {'Content-Type': 'application/json'});
  });

// --- API ຄົ້ນຫາສິດເກົ່າແບບລະອຽດ (Advanced Search) ---
  mainRouter.get('/alumni', (Request req) async {
    try {
      // ຮັບ Parameter ຈາກ URL (ເຊັ່ນ: /alumni?name=...&major=...&year=...)
      final params = req.url.queryParameters;
      final name = params['name'] ?? '';
      final major = params['major'] ?? '';
      final year = params['year'] ?? '';

      // ສ້າງ SQL ແບບ Dynamic (ກອງຂໍ້ມູນສະເພາະຄົນທີ່ Active ແລະ ເປັນ Alumni)
      final sql = "SELECT id, first_name, last_name, major, graduation_year, phone_number "
                  "FROM users "
                  "WHERE status = 'active' AND role = 'alumni' "
                  "AND (first_name ILIKE @name OR last_name ILIKE @name) "
                  "AND (major ILIKE @major) "
                  "AND (graduation_year ILIKE @year) "
                  "ORDER BY first_name ASC";

      final result = await connection.execute(
        Sql.named(sql),
        parameters: {
          'name': '%$name%',
          'major': '%$major%',
          'year': '%$year%',
        },
      );

      final alumni = result.map((row) => {
        'id': row[0],
        'firstName': row[1],
        'lastName': row[2],
        'major': row[3],
        'graduationYear': row[4],
        'phoneNumber': row[5],
      }).toList();

      return Response.ok(jsonEncode(alumni), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: 'Error: $e');
    }
  });

  // --- 💡 CAREER HUB (PUBLIC) ---
  mainRouter.get('/jobs', (Request req) async {
    print('📥 GET /jobs called');
    final result = await connection.execute('SELECT j.id, j.company_name, j.job_title, j.description, j.location, j.salary_range, j.contact_email, j.created_at, u.first_name FROM jobs j JOIN users u ON j.posted_by_id = u.id ORDER BY j.created_at DESC');
    final jobs = result.map((row) => {'id': row[0], 'companyName': row[1], 'jobTitle': row[2], 'description': row[3], 'location': row[4], 'salaryRange': row[5], 'contactEmail': row[6], 'createdAt': row[7].toString(), 'postedBy': row[8]}).toList();
    return Response.ok(jsonEncode(jobs), headers: {'Content-Type': 'application/json'});
  });

  mainRouter.post('/jobs', (Request req) async {
    print('📥 POST /jobs called');
    final body = jsonDecode(await req.readAsString());
    await connection.execute(Sql.named('INSERT INTO jobs (posted_by_id, company_name, job_title, description, location, salary_range, contact_email) VALUES (@postedBy, @company, @title, @desc, @location, @salary, @email)'), 
    parameters: {'postedBy': body['postedBy'], 'company': body['companyName'], 'title': body['jobTitle'], 'desc': body['description'], 'location': body['location'], 'salary': body['salaryRange'], 'email': body['contactEmail']});
    return Response.ok(jsonEncode({'message': 'Job posted'}), headers: {'Content-Type': 'application/json'});
  });

  mainRouter.mount('/admin', adminHandler);

  final handler = Pipeline().addMiddleware(logRequests()).addMiddleware(corsHeaders()).addHandler(mainRouter.call);
  final server = await serve(handler, InternetAddress.anyIPv4, 8080);
  print('🚀 Server listening on port ${server.port}');
}