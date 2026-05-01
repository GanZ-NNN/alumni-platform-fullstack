import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';
import '../../config/database.dart';
import '../../core/http/api_response.dart';
import '../../core/middleware/auth_middleware.dart';

class JobRoutes {
  Router get router {
    final router = Router();

    // 1. ດຶງລາຍການວຽກທັງໝົດ (Guest ແລະ Alumni ເຫັນໄດ້ໝົດ)
    router.get('/', (Request request) async {
      try {
        final result = await DatabaseConfig.connection.execute(
          Sql.named(
            'SELECT '
            '  j.id, '
            '  j.company_name, '
            '  j.job_title, '
            '  j.description, '
            '  j.location, '
            '  j.salary_range, '
            '  j.contact_email, '
            '  COALESCE(u.first_name || \' \' || u.last_name, u.first_name, u.email, \'Unknown\') AS posted_by, '
            '  j.created_at, '
            '  COALESCE(u.phone, u.phone_number) AS phone '
            'FROM jobs j '
            'LEFT JOIN users u ON j.posted_by_id = u.id '
            'ORDER BY j.created_at DESC',
          ),
        );

        final jobs = result.map((row) {
          final createdAt = row[8];
          return {
            'id': row[0],
            'companyName': row[1] ?? '',
            'jobTitle': row[2] ?? '',
            'description': row[3] ?? '',
            'location': row[4] ?? '',
            'salaryRange': row[5] ?? '',
            'contactEmail': row[6] ?? '',
            'postedBy': row[7],
            'createdAt': createdAt is DateTime
                ? createdAt.toIso8601String()
                : '$createdAt',
            'phoneNumber': row[9],
          };
        }).toList();

        return Response.ok(
          jsonEncode(jobs),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return ApiResponse.error(
          500,
          code: 'FETCH_JOBS_FAILED',
          message: 'Failed to fetch jobs',
          details: {'reason': e.toString()},
        );
      }
    });

    // 2. ດຶງລາຍລະອຽດວຽກ
    router.get('/<id>', (Request request, String id) async {
      try {
        final jobId = int.tryParse(id);
        if (jobId == null) {
          return ApiResponse.error(
            400,
            code: 'INVALID_ID',
            message: 'Invalid job ID',
          );
        }

        final result = await DatabaseConfig.connection.execute(
          Sql.named(
            'SELECT '
            '  j.id, '
            '  j.job_title, '
            '  j.company_name, '
            '  j.description, '
            '  j.location, '
            '  j.salary_range, '
            '  j.contact_email, '
            '  j.created_at, '
            '  u.first_name, '
            '  u.last_name, '
            '  COALESCE(u.phone, u.phone_number) AS phone '
            'FROM jobs j '
            'LEFT JOIN users u ON j.posted_by_id = u.id '
            'WHERE j.id = @id',
          ),
          parameters: {'id': jobId},
        );

        if (result.isEmpty) {
          return ApiResponse.error(
            404,
            code: 'JOB_NOT_FOUND',
            message: 'Job not found',
          );
        }

        final row = result.first;
        final rawPhone = row[10]?.toString() ?? '';
        final cleanPhone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');

        String? waLink;
        if (cleanPhone.isNotEmpty) {
          final message = Uri.encodeComponent(
            'ສະບາຍດີ, ຂ້ອຍສົນໃຈສະໝັກວຽກຕຳແໜ່ງ ${row[1]}',
          );
          waLink = "https://wa.me/$cleanPhone?text=$message";
        }

        return ApiResponse.success(
          200,
          data: {
            'id': row[0],
            'jobTitle': row[1],
            'companyName': row[2],
            'description': row[3],
            'location': row[4],
            'salaryRange': row[5],
            'contactEmail': row[6],
            'createdAt': row[7] is DateTime
                ? (row[7] as DateTime).toIso8601String()
                : row[7]?.toString(),
            'postedBy': '${row[8] ?? ''} ${row[9] ?? ''}'.trim().isEmpty
                ? 'Unknown'
                : '${row[8] ?? ''} ${row[9] ?? ''}'.trim(),
            'applyWhatsapp': waLink,
            'phoneNumber': rawPhone,
          },
        );
      } catch (e) {
        return ApiResponse.error(
          500,
          code: 'FETCH_JOB_DETAILS_FAILED',
          message: 'Error fetching job details',
          details: {'reason': e.toString()},
        );
      }
    });

    // 3. ໂພສວຽກໃໝ່ (ສະເພາະ Alumni ແລະ Admin)
    Future<Response> createHandler(Request request) async {
      final user = request.context['user'] as Map<String, dynamic>?;
      final role = user?['role'];
      final userId = int.tryParse(user?['userId']?.toString() ?? '');

      if (role != 'alumni' && role != 'admin') {
        return ApiResponse.error(
          403,
          code: 'UNAUTHORIZED_ROLE',
          message: 'Only Alumni can post jobs',
        );
      }

      if (userId == null) {
        return ApiResponse.error(
          401,
          code: 'UNAUTHORIZED',
          message: 'User ID not found in token',
        );
      }

      try {
        final content = await request.readAsString();
        if (content.isEmpty) {
          return ApiResponse.error(
            400,
            code: 'EMPTY_BODY',
            message: 'Request body is empty',
          );
        }

        final body = jsonDecode(content);

        await DatabaseConfig.connection.execute(
          Sql.named(
            'INSERT INTO jobs (job_title, company_name, description, location, salary_range, contact_email, posted_by_id) '
            'VALUES (@title, @company, @desc, @location, @salary, @email, @userId)',
          ),
          parameters: {
            'title': body['jobTitle'] ?? '',
            'company': body['companyName'] ?? '',
            'desc': body['description'] ?? '',
            'location': body['location'] ?? '',
            'salary': body['salaryRange'] ?? '',
            'email': body['contactEmail'] ?? '',
            'userId': userId,
          },
        );

        return ApiResponse.success(201, message: 'Job posted successfully');
      } catch (e) {
        return ApiResponse.error(
          500,
          code: 'CREATE_JOB_FAILED',
          message: 'Failed to create job post',
          details: {'reason': e.toString()},
        );
      }
    }

    router.post(
      '/create',
      Pipeline().addMiddleware(authMiddleware()).addHandler(createHandler),
    );
    // Also support POST / for backward compatibility if needed, but /create is clearer.
    router.post(
      '/',
      Pipeline().addMiddleware(authMiddleware()).addHandler(createHandler),
    );

    return router;
  }
}
