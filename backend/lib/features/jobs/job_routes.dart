import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';
import '../../config/database.dart';
import '../../core/http/api_response.dart';

class JobRoutes {
  Router get router {
    final router = Router();

    // 1. ດຶງລາຍການວຽກທັງໝົດ (Guest ແລະ Alumni ເຫັນໄດ້ໝົດ)
    router.get('/', (Request request) async {
      try {
        final result = await DatabaseConfig.connection.execute(
          Sql.named(
            'SELECT j.id, j.title, j.company_name, j.open_date, j.close_date, '
            'u.first_name, u.last_name, u.job_title as author_position '
            'FROM jobs j '
            'JOIN users u ON j.posted_by_id = u.id '
            'ORDER BY j.created_at DESC',
          ),
        );

        final jobs = result.map((row) => {
          'id': row[0],
          'title': row[1],
          'companyName': row[2],
          'openDate': row[3]?.toString(),
          'closeDate': row[4]?.toString(),
          'postedBy': '${row[5]} ${row[6]}',
          'authorPosition': row[7],
        }).toList();

        return ApiResponse.success(200, data: jobs);
      } catch (e) {
        return ApiResponse.error(500, message: 'Failed to fetch jobs', details: {'reason': e.toString()});
      }
    });

    // 2. ດຶງລາຍລະອຽດວຽກ (ລວມເຖິງເບີ WhatsApp ເພື່ອ Apply)
    router.get('/<id>', (Request request, String id) async {
      try {
        final result = await DatabaseConfig.connection.execute(
          Sql.named(
            'SELECT j.*, u.first_name, u.last_name, u.phone '
            'FROM jobs j '
            'JOIN users u ON j.posted_by_id = u.id '
            'WHERE j.id = @id',
          ),
          parameters: {'id': int.parse(id)},
        );

        if (result.isEmpty) {
          return ApiResponse.error(404, message: 'Job not found');
        }

        final row = result.first;
        // ສ້າງ WhatsApp Link ອັດຕະໂນມັດ ຖ້າໃນ DB ບໍ່ມີ
        final phone = row[11]; // ຈາກ u.phone
        final waLink = "https://wa.me/$phone?text=ສະບາຍດີ, ຂ້ອຍສົນໃຈສະໝັກວຽກຕຳແໜ່ງ ${row[1]}";

        return ApiResponse.success(200, data: {
          'id': row[0],
          'title': row[1],
          'companyName': row[2],
          'description': row[3],
          'openDate': row[5]?.toString(),
          'closeDate': row[6]?.toString(),
          'postedBy': '${row[9]} ${row[10]}',
          'applyWhatsapp': waLink,
        });
      } catch (e) {
        return ApiResponse.error(500, message: 'Error fetching job details');
      }
    });

    // 3. ໂພສວຽກໃໝ່ (ສະເພາະ Alumni ແລະ Admin)
    router.post('/create', (Request request) async {
      final role = request.context['role'];
      final userId = request.context['userId'];

      if (role != 'alumni' && role != 'admin') {
        return ApiResponse.error(403, message: 'Only Alumni can post jobs');
      }

      try {
        final body = jsonDecode(await request.readAsString());
        
        await DatabaseConfig.connection.execute(
          Sql.named(
            'INSERT INTO jobs (title, company_name, description, posted_by_id, close_date) '
            'VALUES (@title, @company, @desc, @userId, @closeDate)',
          ),
          parameters: {
            'title': body['title'],
            'company': body['companyName'],
            'desc': body['description'],
            'userId': userId,
            'closeDate': body['closeDate'],
          },
        );

        return ApiResponse.success(201, message: 'Job posted successfully');
      } catch (e) {
        return ApiResponse.error(500, message: 'Failed to create job post');
      }
    });

    return router;
  }
}