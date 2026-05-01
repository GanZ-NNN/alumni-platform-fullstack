import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';
import '../../config/database.dart';
import '../../core/http/api_response.dart';
import '../../core/middleware/auth_middleware.dart';

class PostRoutes {
  Router get router {
    final router = Router();

    // 1. Get all posts (Public)
    router.get('/', (Request request) async {
      try {
        final result = await DatabaseConfig.connection.execute(Sql.named('''
          SELECT id, title, content, type, image_url, created_at, author_id
          FROM posts
          ORDER BY created_at DESC, id DESC
        '''));

        final posts = result.map((r) {
          final createdAt = r[5];
          return {
            'id': r[0],
            'title': r[1],
            'content': r[2],
            'type': r[3] ?? 'news',
            'imageUrl': r[4],
            'createdAt': createdAt is DateTime ? createdAt.toIso8601String() : '$createdAt',
            'authorId': r[6],
          };
        }).toList();

        return Response.ok(
          jsonEncode(posts),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return ApiResponse.error(500, code: 'FETCH_POSTS_FAILED', message: 'Failed to fetch posts');
      }
    });

    // 2. Create post (Alumni & Admin)
    final createHandler = (Request request) async {
      final user = request.context['user'] as Map<String, dynamic>?;
      final role = user?['role'];
      final authorId = int.tryParse(user?['userId']?.toString() ?? '');

      if (role != 'alumni' && role != 'admin') {
        return ApiResponse.error(403, code: 'UNAUTHORIZED_ROLE', message: 'Unauthorized to create posts');
      }

      if (authorId == null) {
        return ApiResponse.error(401, code: 'UNAUTHORIZED', message: 'User ID not found');
      }

      try {
        final body = jsonDecode(await request.readAsString());
        final title = body['title']?.toString();
        final content = body['content']?.toString();
        final type = body['type']?.toString() ?? 'news';
        final imageUrl = body['imageUrl']?.toString();

        if (title == null || title.isEmpty || content == null || content.isEmpty) {
          return ApiResponse.error(400, code: 'INVALID_INPUT', message: 'Title and content are required');
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
            'imageUrl': imageUrl,
          },
        );

        return ApiResponse.success(201, message: 'Post created successfully');
      } catch (e) {
        return ApiResponse.error(500, code: 'CREATE_POST_FAILED', message: 'Failed to create post');
      }
    };

    router.post('/', Pipeline().addMiddleware(authMiddleware()).addHandler(createHandler));
    router.post('/create', Pipeline().addMiddleware(authMiddleware()).addHandler(createHandler));

    return router;
  }
}
