import 'dart:convert';
import 'dart:math';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:dbcrypt/dbcrypt.dart';
import 'package:postgres/postgres.dart';
import '../../config/app_config.dart';
import '../../config/database.dart';
import '../../core/auth/jwt_service.dart';
import '../../core/middleware/rate_limit_middleware.dart';
import '../../core/http/api_response.dart';
import '../../core/utils/email_service.dart';

class AuthRoutes {
  Router get router {
    final router = Router();

    // Helper function to validate email format
    bool isValidEmail(String email) {
      return RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
      ).hasMatch(email);
    }

    router.post('/register', (Request request) async {
      try {
        final content = await request.readAsString();
        print('📝 [Registration] Request body: $content');

        if (content.isEmpty) {
          return ApiResponse.error(
            400,
            code: 'EMPTY_BODY',
            message: 'Request body is empty',
          );
        }

        Map<String, dynamic> body;
        try {
          body = jsonDecode(content);
        } catch (e) {
          return ApiResponse.error(
            400,
            code: 'INVALID_JSON',
            message: 'Invalid JSON format',
          );
        }

        final email = body['email']?.toString().trim();
        final password = body['password']?.toString();

        if (email == null ||
            email.isEmpty ||
            password == null ||
            password.isEmpty) {
          return ApiResponse.error(
            400,
            code: 'MISSING_FIELDS',
            message: 'Email and password are required',
          );
        }

        if (!isValidEmail(email)) {
          return ApiResponse.error(
            400,
            code: 'INVALID_EMAIL',
            message: 'Please provide a valid email address',
          );
        }

        print('🔍 [Registration] Checking if user exists: $email');
        final existingUser = await DatabaseConfig.connection.execute(
          Sql.named('SELECT id FROM users WHERE email = @email'),
          parameters: {'email': email},
        );

        if (existingUser.isNotEmpty) {
          return ApiResponse.error(
            409,
            code: 'EMAIL_ALREADY_EXISTS',
            message: 'This email is already registered.',
          );
        }

        final firstName = body['firstName']?.toString() ?? '';
        final lastName = body['lastName']?.toString() ?? '';
        final gender = body['gender']?.toString();
        final dobString = body['dob']?.toString();
        final studentId = body['studentId']?.toString();
        final phone = body['phone']?.toString() ?? '';

        String role = 'guest';
        String status = 'active';

        if (studentId != null && studentId.isNotEmpty) {
          print('🎓 [Registration] Checking graduated status for: $studentId');
          try {
            final graduatedResult = await DatabaseConfig.connection.execute(
              Sql.named(
                'SELECT 1 FROM graduated_students WHERE student_id = @sid LIMIT 1',
              ),
              parameters: {'sid': studentId},
            );

            if (graduatedResult.isNotEmpty) {
              role = 'alumni';
              status = 'pending';
              print(
                '✅ [Registration] Found in graduated list. Role: alumni, Status: pending',
              );
            } else {
              print(
                'ℹ️ [Registration] Not in graduated list. Keeping as guest/active',
              );
            }
          } catch (e) {
            print('⚠️ [Registration] Error checking graduated_students: $e');
            // Continue as guest if check fails
          }
        }

        final hashed = DBCrypt().hashpw(password, DBCrypt().gensalt());

        DateTime? dob;
        if (dobString != null && dobString.isNotEmpty) {
          try {
            dob = DateTime.parse(dobString);
          } catch (e) {
            print('⚠️ [Registration] Invalid DOB format: $dobString');
          }
        }

        print('🔨 [Registration] Final step: Inserting user into DB...');

        await DatabaseConfig.connection.execute(
          Sql.named(
            'INSERT INTO users (email, password, first_name, last_name, gender, dob, student_id, phone, role, status, created_at) '
            'VALUES (@email, @pass, @f, @l, @gender, @dob, @studentId, @phone, @role, @status, NOW())',
          ),
          parameters: {
            'email': email,
            'pass': hashed,
            'f': firstName,
            'l': lastName,
            'gender': gender,
            'dob': dob,
            'studentId': studentId,
            'phone': phone,
            'role': role,
            'status': status,
          },
        );

        print('✨ [Registration] Successfully registered: $email');

        return ApiResponse.success(
          200,
          data: {
            'message': status == 'active'
                ? 'Registration successful'
                : 'Registration submitted. Waiting for admin approval.',
            'status': status,
            'role': role,
          },
        );
      } catch (e, stackTrace) {
        print('❌ [Registration] UNHANDLED ERROR: $e');
        print(stackTrace);
        return ApiResponse.error(
          500,
          code: 'AUTH_REGISTER_FAILED',
          message: 'Registration failed internal server error.',
          details: {'reason': e.toString()},
        );
      }
    });

    router.post('/login', (Request request) async {
      try {
        final content = await request.readAsString();
        final body = jsonDecode(content);
        final String? email = body['email'];
        final String? password = body['password'];

        if (email == null || password == null) {
          return ApiResponse.error(
            400,
            code: 'MISSING_FIELDS',
            message: 'Email and password are required',
          );
        }

        // ຄົ້ນຫາ User ໂດຍບໍ່ສົນໃຈໂຕພິມນ້ອຍ-ໃຫຍ່
        final result = await DatabaseConfig.connection.execute(
          Sql.named(
            'SELECT id, email, password, role, first_name, last_name, status FROM users WHERE email ILIKE @email',
          ),
          parameters: {'email': email},
        );

        if (result.isEmpty) {
          return ApiResponse.error(
            401,
            code: 'INVALID_CREDENTIALS',
            message: 'Invalid credentials.',
          );
        }

        final row = result.first;
        final hashed = row[2].toString();

        if (!DBCrypt().checkpw(password, hashed)) {
          return ApiResponse.error(
            401,
            code: 'INVALID_CREDENTIALS',
            message: 'Invalid credentials.',
          );
        }

        final userId = row[0].toString();
        final role = row[3].toString();
        final status = row[6]?.toString() ?? 'pending';
        final String fullName = '${row[4] ?? ''} ${row[5] ?? ''}'.trim();

        if (status != 'active' && role != 'admin') {
          return ApiResponse.error(
            403,
            code: 'ACCOUNT_PENDING',
            message: 'Your account is pending approval.',
          );
        }

        final accessToken = JwtService.generateToken({
          'userId': userId,
          'role': role,
        });
        final refreshToken = JwtService.generateRefreshToken(userId);

        return ApiResponse.success(
          200,
          data: {
            'accessToken': accessToken,
            'refreshToken': refreshToken,
            'user': {
              'id': row[0],
              'email': row[1],
              'role': role,
              'firstName': row[4] ?? '',
              'lastName': row[5] ?? '',
              'fullName': fullName,
              'status': status,
            },
          },
        );
      } catch (e) {
        return ApiResponse.error(
          500,
          code: 'LOGIN_FAILED',
          message: 'Error during login process.',
          details: {'reason': e.toString()},
        );
      }
    });

    // Public Stats for Dashboard (Accessible by all logged-in users)
    router.get('/public-stats', (Request request) async {
      try {
        final usersCount = await DatabaseConfig.connection.execute(
          'SELECT COUNT(*) FROM users',
        );
        final postsCount = await DatabaseConfig.connection.execute(
          'SELECT COUNT(*) FROM posts',
        );
        final jobsCount = await DatabaseConfig.connection.execute(
          'SELECT COUNT(*) FROM jobs',
        );

        return ApiResponse.success(
          200,
          data: {
            'totalAlumni': (usersCount.first[0] as int?) ?? 0,
            'totalPosts': (postsCount.first[0] as int?) ?? 0,
            'totalJobs': (jobsCount.first[0] as int?) ?? 0,
          },
        );
      } catch (e) {
        return ApiResponse.error(
          500,
          code: 'STATS_ERROR',
          message: 'Failed to fetch public stats',
        );
      }
    });

    // --- ສ່ວນທີ່ເພີ່ມໃໝ່: Profile & Admin Logic ---

    // 1. ດຶງຂໍ້ມູນ Profile ຂອງຕົນເອງ
    router.get('/me', (Request request) async {
      final userId = request.context['userId'];

      final result = await DatabaseConfig.connection.execute(
        Sql.named(
          'SELECT id, email, first_name, last_name, gender, dob, student_id, phone, role, status, '
          'graduation_year, education_level, job_title, company_name, industry '
          'FROM users WHERE id = @id',
        ),
        parameters: {'id': userId},
      );

      if (result.isEmpty) {
        return ApiResponse.error(
          404,
          code: 'USER_NOT_FOUND',
          message: 'User not found',
        );
      }

      final row = result.first;
      return ApiResponse.success(
        200,
        data: {
          'id': row[0],
          'email': row[1],
          'firstName': row[2],
          'lastName': row[3],
          'gender': row[4],
          'dob': row[5]?.toString(),
          'studentId': row[6],
          'phone': row[7],
          'role': row[8],
          'status': row[9],
          'alumniDetails': {
            'graduationYear': row[10],
            'educationLevel': row[11],
            'jobTitle': row[12],
            'companyName': row[13],
            'industry': row[14],
          },
        },
      );
    });

    // 2. ອັບເດດຂໍ້ມູນ Profile (Alumni ມາຕື່ມຂໍ້ມູນທີຫຼັງ)
    router.put('/update-profile', (Request request) async {
      try {
        final userId = request.context['userId'];
        final body = jsonDecode(await request.readAsString());

        await DatabaseConfig.connection.execute(
          Sql.named(
            'UPDATE users SET '
            'first_name = COALESCE(@f, first_name), '
            'last_name = COALESCE(@l, last_name), '
            'phone = COALESCE(@phone, phone), '
            'graduation_year = COALESCE(@gradYear, graduation_year), '
            'education_level = COALESCE(@eduLevel, education_level), '
            'job_title = COALESCE(@job, job_title), '
            'company_name = COALESCE(@company, company_name), '
            'industry = COALESCE(@industry, industry) '
            'WHERE id = @id',
          ),
          parameters: {
            'id': userId,
            'f': body['firstName'],
            'l': body['lastName'],
            'phone': body['phone'],
            'gradYear': body['graduationYear'],
            'eduLevel': body['educationLevel'],
            'job': body['jobTitle'],
            'company': body['companyName'],
            'industry': body['industry'],
          },
        );

        return ApiResponse.success(
          200,
          message: 'Profile updated successfully',
        );
      } catch (e) {
        return ApiResponse.error(
          500,
          code: 'UPDATE_PROFILE_FAILED',
          message: 'Update failed',
          details: {'reason': e.toString()},
        );
      }
    });

    // 3. Admin ອະນຸມັດສິດເກົ່າ (Alumni Approval)
    router.post('/admin/approve/<id>', (Request request, String id) async {
      final adminRole = request.context['role'];
      if (adminRole != 'admin') {
        return ApiResponse.error(
          403,
          code: 'FORBIDDEN',
          message: 'Only admins can perform this action',
        );
      }

      try {
        final result = await DatabaseConfig.connection.execute(
          Sql.named(
            'UPDATE users SET status = @status WHERE id = @id RETURNING email, first_name',
          ),
          parameters: {'status': 'active', 'id': id},
        );

        if (result.isEmpty) {
          return ApiResponse.error(
            404,
            code: 'USER_NOT_FOUND',
            message: 'User not found',
          );
        }

        final userEmail = result.first[0].toString();
        final userName = result.first[1].toString();
        await EmailService.sendApprovalNotification(userEmail, userName);

        return ApiResponse.success(200, message: 'User approved successfully');
      } catch (e) {
        return ApiResponse.error(
          500,
          code: 'APPROVAL_FAILED',
          message: 'Approval failed',
        );
      }
    });

    // 4. Change Password (Logged-in user)
    router.post('/change-password', (Request request) async {
      try {
        final userId = request.context['userId'];
        final body = jsonDecode(await request.readAsString());
        final String? oldPassword = body['oldPassword'];
        final String? newPassword = body['newPassword'];

        if (oldPassword == null ||
            newPassword == null ||
            newPassword.length < 6) {
          return ApiResponse.error(
            400,
            code: 'INVALID_INPUT',
            message: 'Old and valid new password are required',
          );
        }

        // Check old password
        final result = await DatabaseConfig.connection.execute(
          Sql.named('SELECT password FROM users WHERE id = @id'),
          parameters: {'id': userId},
        );

        if (result.isEmpty) {
          return ApiResponse.error(
            404,
            code: 'USER_NOT_FOUND',
            message: 'User not found',
          );
        }

        final hashed = result.first[0].toString();
        if (!DBCrypt().checkpw(oldPassword, hashed)) {
          return ApiResponse.error(
            401,
            code: 'INVALID_CREDENTIALS',
            message: 'Invalid old password',
          );
        }

        // Update to new password
        final newHashed = DBCrypt().hashpw(newPassword, DBCrypt().gensalt());
        await DatabaseConfig.connection.execute(
          Sql.named('UPDATE users SET password = @password WHERE id = @id'),
          parameters: {'password': newHashed, 'id': userId},
        );

        return ApiResponse.success(
          200,
          message: 'Password changed successfully',
        );
      } catch (e) {
        return ApiResponse.error(
          500,
          code: 'CHANGE_PASSWORD_FAILED',
          message: 'Error changing password',
        );
      }
    });

    // --- Password Reset Flow ---

    // 1. Request Reset Code
    router.post('/forgot-password', (Request request) async {
      try {
        final body = jsonDecode(await request.readAsString());
        final email = body['email']?.toString().trim();

        if (email == null || email.isEmpty) {
          return ApiResponse.error(
            400,
            code: 'INVALID_INPUT',
            message: 'Email is required',
          );
        }

        // Check if user exists
        final userResult = await DatabaseConfig.connection.execute(
          Sql.named('SELECT id FROM users WHERE email = @email'),
          parameters: {'email': email},
        );

        if (userResult.isEmpty) {
          return ApiResponse.error(
            404,
            code: 'USER_NOT_FOUND',
            message: 'User with this email not found',
          );
        }

        // Generate 4-digit code (Requested by user)
        final code = (Random().nextInt(9000) + 1000).toString();
        final expiresAt = DateTime.now().add(const Duration(minutes: 15));

        // Save to database (Upsert)
        await DatabaseConfig.connection.execute(
          Sql.named('''
            INSERT INTO password_resets (email, code, expires_at)
            VALUES (@email, @code, @expiresAt)
            ON CONFLICT (email) DO UPDATE SET code = @code, expires_at = @expiresAt
          '''),
          parameters: {'email': email, 'code': code, 'expiresAt': expiresAt},
        );

        // Send Email
        final sent = await EmailService.sendPasswordResetCode(email, code);
        if (!sent) {
          return ApiResponse.error(
            500,
            code: 'EMAIL_FAILED',
            message: 'Failed to send reset code',
          );
        }

        return ApiResponse.success(
          200,
          message: 'Reset code sent to your email',
        );
      } catch (e) {
        return ApiResponse.error(
          500,
          code: 'FORGOT_PASSWORD_FAILED',
          message: 'Error processing request',
        );
      }
    });

    // 2. Verify Code and Reset Password
    router.post('/reset-password', (Request request) async {
      try {
        final body = jsonDecode(await request.readAsString());
        final email = body['email']?.toString().trim();
        final code = body['code']?.toString().trim();
        final newPassword = body['newPassword']?.toString();

        if (email == null ||
            code == null ||
            newPassword == null ||
            newPassword.length < 6) {
          return ApiResponse.error(
            400,
            code: 'INVALID_INPUT',
            message: 'Email, code, and valid new password are required',
          );
        }

        // Verify code
        final resetResult = await DatabaseConfig.connection.execute(
          Sql.named(
            'SELECT code, expires_at FROM password_resets WHERE email = @email',
          ),
          parameters: {'email': email},
        );

        if (resetResult.isEmpty) {
          return ApiResponse.error(
            400,
            code: 'INVALID_CODE',
            message: 'Invalid reset code or email',
          );
        }

        final dbCode = resetResult.first[0].toString();
        final expiresAt = resetResult.first[1] as DateTime;

        if (dbCode != code) {
          return ApiResponse.error(
            400,
            code: 'INVALID_CODE',
            message: 'Invalid reset code',
          );
        }

        if (DateTime.now().isAfter(expiresAt)) {
          return ApiResponse.error(
            400,
            code: 'CODE_EXPIRED',
            message: 'Reset code has expired',
          );
        }

        // Update User Password
        final hashed = DBCrypt().hashpw(newPassword, DBCrypt().gensalt());
        await DatabaseConfig.connection.execute(
          Sql.named(
            'UPDATE users SET password = @password WHERE email = @email',
          ),
          parameters: {'password': hashed, 'email': email},
        );

        // Clean up reset code
        await DatabaseConfig.connection.execute(
          Sql.named('DELETE FROM password_resets WHERE email = @email'),
          parameters: {'email': email},
        );

        return ApiResponse.success(
          200,
          message: 'Password has been reset successfully',
        );
      } catch (e) {
        return ApiResponse.error(
          500,
          code: 'RESET_PASSWORD_FAILED',
          message: 'Error resetting password',
        );
      }
    });

    final pipeline = Pipeline().addMiddleware(
      rateLimitMiddleware(
        maxRequests: AppConfig.authRateLimitMaxRequests,
        window: Duration(seconds: AppConfig.authRateLimitWindowSeconds),
      ),
    );

    return Router()..mount('/', pipeline.addHandler(router.call));
  }
}
