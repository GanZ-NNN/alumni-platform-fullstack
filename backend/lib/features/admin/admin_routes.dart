import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../config/database.dart';

class AdminRoutes {
  Router get router {
    final router = Router();

    // Users
    router.get('/users', (Request request) async {
      final result = await DatabaseConfig.connection.execute(
        Sql.named('''
        SELECT
          id,
          email,
          first_name,
          last_name,
          role,
          status,
          major,
          graduation_year,
          phone_number,
          profile_image_url,
          created_at
        FROM users
        ORDER BY created_at DESC, id DESC
      '''),
      );

      final users = result.map((r) {
        return {
          'id': r[0],
          'email': r[1],
          'firstName': r[2] ?? '',
          'lastName': r[3],
          'role': r[4] ?? 'alumni',
          'status': r[5] ?? 'pending',
          'major': r[6],
          'graduationYear': r[7],
          'phoneNumber': r[8],
          'profileImageUrl': r[9],
          // Fields not yet in schema; keep frontend defaults working.
          'workStatus': 'Unemployed',
          'workplace': null,
          'jobPosition': null,
          'gender': null,
          'dob': null,
          'studentId': null,
          'educationLevel': null,
          'industry': null,
        };
      }).toList();

      return Response.ok(
        jsonEncode(users),
        headers: {'Content-Type': 'application/json'},
      );
    });

    router.put('/users/<id>/approve', (Request request, String id) async {
      final userId = int.tryParse(id);
      if (userId == null) {
        return Response(
          400,
          body: jsonEncode({'message': 'Invalid user id'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      await DatabaseConfig.connection.execute(
        Sql.named('UPDATE users SET status = @status WHERE id = @id'),
        parameters: {'status': 'active', 'id': userId},
      );

      await _log(request, action: 'ADMIN_APPROVE_USER', details: 'userId=$id');

      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'Content-Type': 'application/json'},
      );
    });

    router.delete('/users/<id>', (Request request, String id) async {
      final userId = int.tryParse(id);
      if (userId == null) {
        return Response(
          400,
          body: jsonEncode({'message': 'Invalid user id'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      await DatabaseConfig.connection.execute(
        Sql.named('DELETE FROM users WHERE id = @id'),
        parameters: {'id': userId},
      );
      await _log(request, action: 'ADMIN_DELETE_USER', details: 'userId=$id');

      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // Dashboard
    router.get('/stats', (Request request) async {
      final usersCount = await DatabaseConfig.connection.execute(
        'SELECT COUNT(*) FROM users',
      );
      final pendingUsersCount = await DatabaseConfig.connection.execute(
        Sql.named("SELECT COUNT(*) FROM users WHERE status = @s"),
        parameters: {'s': 'pending'},
      );
      final postsCount = await DatabaseConfig.connection.execute(
        'SELECT COUNT(*) FROM posts',
      );
      final jobsCount = await DatabaseConfig.connection.execute(
        'SELECT COUNT(*) FROM jobs',
      );

      final payload = {
        // Keep frontend compatibility (dashboard expects totalAlumni).
        'totalAlumni': (usersCount.first[0] as int?) ?? 0,
        'pendingUsers': (pendingUsersCount.first[0] as int?) ?? 0,
        'totalPosts': (postsCount.first[0] as int?) ?? 0,
        'totalJobs': (jobsCount.first[0] as int?) ?? 0,
      };

      return Response.ok(
        jsonEncode(payload),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // Activity logs
    router.get('/logs', (Request request) async {
      final result = await DatabaseConfig.connection.execute(
        Sql.named('''
        SELECT
          l.id,
          l.action,
          l.details,
          l.created_at,
          u.id,
          u.email
        FROM activity_logs l
        LEFT JOIN users u ON u.id = l.user_id
        ORDER BY l.created_at DESC, l.id DESC
        LIMIT 200
      '''),
      );

      final logs = result.map((r) {
        final createdAt = r[3];
        return {
          'id': r[0],
          'action': r[1],
          'details': r[2],
          'createdAt': createdAt is DateTime
              ? createdAt.toIso8601String()
              : '$createdAt',
          'userId': r[4],
          'userEmail': r[5],
        };
      }).toList();

      return Response.ok(
        jsonEncode(logs),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // Reports
    router.get('/reports/majors', (Request request) async {
      final result = await DatabaseConfig.connection.execute(
        Sql.named('''
        SELECT COALESCE(major, 'Unknown') AS major, COUNT(*) AS total
        FROM users
        GROUP BY COALESCE(major, 'Unknown')
        ORDER BY total DESC, major ASC
      '''),
      );

      final rows = result.map((r) => {'major': r[0], 'count': r[1]}).toList();

      return Response.ok(
        jsonEncode(rows),
        headers: {'Content-Type': 'application/json'},
      );
    });

    router.get('/reports/years', (Request request) async {
      final result = await DatabaseConfig.connection.execute(
        Sql.named('''
        SELECT COALESCE(graduation_year, 0) AS year, COUNT(*) AS total
        FROM users
        GROUP BY COALESCE(graduation_year, 0)
        ORDER BY year ASC
      '''),
      );

      final rows = result.map((r) => {'year': r[0], 'count': r[1]}).toList();

      return Response.ok(
        jsonEncode(rows),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // Posts (admin)
    router.get('/posts', (Request request) async {
      final result = await DatabaseConfig.connection.execute(
        Sql.named('''
        SELECT p.id, p.title, p.content, p.type, p.image_url, p.created_at
        FROM posts p
        ORDER BY p.created_at DESC, p.id DESC
      '''),
      );

      final posts = result.map((r) {
        final createdAt = r[5];
        return {
          'id': r[0],
          'title': r[1],
          'content': r[2],
          'type': r[3] ?? 'news',
          'imageUrl': r[4],
          'createdAt': createdAt is DateTime
              ? createdAt.toIso8601String()
              : '$createdAt',
        };
      }).toList();

      return Response.ok(
        jsonEncode(posts),
        headers: {'Content-Type': 'application/json'},
      );
    });

    router.post('/posts', (Request request) async {
      final body = await request.readAsString();
      final jsonBody = body.isEmpty ? <String, dynamic>{} : jsonDecode(body);

      final authorId = (jsonBody['authorId'] as int?) ?? 0;
      final title = (jsonBody['title'] ?? '').toString();
      final content = (jsonBody['content'] ?? '').toString();
      final type = (jsonBody['type'] ?? 'news').toString();
      final imageUrl = (jsonBody['imageUrl'] ?? '').toString();

      if (authorId <= 0 || title.isEmpty || content.isEmpty) {
        return Response(
          400,
          body: jsonEncode({'message': 'Missing required fields'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      await DatabaseConfig.connection.execute(
        Sql.named('''
          INSERT INTO posts (author_id, title, content, type, image_url)
          VALUES (@authorId, @title, @content, @type, @imageUrl)
        '''),
        parameters: {
          'authorId': authorId,
          'title': title,
          'content': content,
          'type': type,
          'imageUrl': imageUrl.isEmpty ? null : imageUrl,
        },
      );

      await _log(request, action: 'ADMIN_CREATE_POST', details: 'title=$title');

      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'Content-Type': 'application/json'},
      );
    });

    router.put('/posts/<id>', (Request request, String id) async {
      final postId = int.tryParse(id);
      if (postId == null) {
        return Response(
          400,
          body: jsonEncode({'message': 'Invalid post id'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = await request.readAsString();
      final jsonBody = body.isEmpty ? <String, dynamic>{} : jsonDecode(body);

      final title = (jsonBody['title'] ?? '').toString();
      final content = (jsonBody['content'] ?? '').toString();
      final type = (jsonBody['type'] ?? 'news').toString();
      final imageUrl = (jsonBody['imageUrl'] ?? '').toString();

      await DatabaseConfig.connection.execute(
        Sql.named('''
          UPDATE posts
          SET title=@title, content=@content, type=@type, image_url=@imageUrl
          WHERE id=@id
        '''),
        parameters: {
          'title': title,
          'content': content,
          'type': type,
          'imageUrl': imageUrl.isEmpty ? null : imageUrl,
          'id': postId,
        },
      );

      await _log(request, action: 'ADMIN_UPDATE_POST', details: 'postId=$id');

      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'Content-Type': 'application/json'},
      );
    });

    router.delete('/posts/<id>', (Request request, String id) async {
      final postId = int.tryParse(id);
      if (postId == null) {
        return Response(
          400,
          body: jsonEncode({'message': 'Invalid post id'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      await DatabaseConfig.connection.execute(
        Sql.named('DELETE FROM posts WHERE id = @id'),
        parameters: {'id': postId},
      );

      await _log(request, action: 'ADMIN_DELETE_POST', details: 'postId=$id');

      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // Jobs (admin delete)
    router.delete('/jobs/<id>', (Request request, String id) async {
      final jobId = int.tryParse(id);
      if (jobId == null) {
        return Response(
          400,
          body: jsonEncode({'message': 'Invalid job id'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      await DatabaseConfig.connection.execute(
        Sql.named('DELETE FROM jobs WHERE id = @id'),
        parameters: {'id': jobId},
      );
      await _log(request, action: 'ADMIN_DELETE_JOB', details: 'jobId=$id');

      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'Content-Type': 'application/json'},
      );
    });

    return router;
  }

  Future<void> _log(
    Request request, {
    required String action,
    String? details,
  }) async {
    final user = request.context['user'] as Map<String, dynamic>?;
    final userId = int.tryParse(user?['userId']?.toString() ?? '');

    await DatabaseConfig.connection.execute(
      Sql.named('''
        INSERT INTO activity_logs (user_id, action, details)
        VALUES (@userId, @action, @details)
      '''),
      parameters: {'userId': userId, 'action': action, 'details': details},
    );
  }
}
