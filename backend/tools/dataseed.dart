import 'dart:io';
import 'dart:math';
import 'package:postgres/postgres.dart';
import 'package:dbcrypt/dbcrypt.dart';

final _rand = Random();

String _pick(List<String> items) => items[_rand.nextInt(items.length)];

String _email(String first, String last, int idx) =>
    '${first.toLowerCase()}.${last.toLowerCase()}$idx@example.com';

String _phone() => '555-${1000 + _rand.nextInt(9000)}';

List<String> _majors = [
  'Computer Science',
  'Business',
  'Economics',
  'Electrical Engineering',
  'Mechanical Engineering',
  'Biology',
  'Mathematics',
  'Design',
];

List<String> _firstNames = [
  'Alice',
  'Bob',
  'Carol',
  'David',
  'Eve',
  'Frank',
  'Grace',
  'Hank',
  'Ivy',
  'Jack',
  'Karen',
  'Leo',
  'Mona',
  'Nate',
  'Olivia',
  'Paul',
  'Quinn',
  'Rita',
];

List<String> _lastNames = [
  'Anderson',
  'Brown',
  'Clark',
  'Diaz',
  'Evans',
  'Foster',
  'Garcia',
  'Harris',
  'Ivanov',
  'Johnson',
  'Khan',
  'Lee',
  'Martinez',
  'Nguyen',
  'Olsen',
];

Future<void> main() async {
  final connection = await Connection.open(
    Endpoint(
      host: 'localhost',
      port: 5434,
      database: 'alumni_db',
      username: 'admin',
      password: 'password123',
    ),
    settings: ConnectionSettings(sslMode: SslMode.disable),
  );
  print('✅ Connected to database');

  // Ensure uploads directories exist
  final uploadsDir = Directory('uploads');
  final profilesDir = Directory('uploads/profiles');
  final postsDir = Directory('uploads/posts');
  if (!uploadsDir.existsSync()) uploadsDir.createSync(recursive: true);
  if (!profilesDir.existsSync()) profilesDir.createSync(recursive: true);
  if (!postsDir.existsSync()) postsDir.createSync(recursive: true);

  // create some placeholder files
  for (var i = 1; i <= 6; i++) {
    File('uploads/profiles/profile_$i.jpg').writeAsStringSync('placeholder');
  }
  for (var i = 1; i <= 8; i++) {
    File('uploads/posts/post_$i.jpg').writeAsStringSync('placeholder');
  }

  final hasher = DBCrypt();

  // Insert a realistic set of users (mix of admins, alumni, pending)
  final inserted = <Map<String, dynamic>>[];
  // Add a known admin (or reuse existing)
  final adminEmail = 'admin@example.com';
  final adminCheck = await connection.execute(
    Sql.named('SELECT id FROM users WHERE email = @email'),
    parameters: {'email': adminEmail},
  );
  int adminId;
  if (adminCheck.isNotEmpty) {
    adminId = adminCheck[0][0] as int;
    inserted.add({'id': adminId, 'role': 'admin'});
    print('Reusing existing admin id=$adminId');
  } else {
    final adminHash = hasher.hashpw('adminpass', DBCrypt().gensalt());
    final adminRes = await connection.execute(
      Sql.named(
        'INSERT INTO users (email, password, first_name, last_name, role, status, major, graduation_year, phone_number, profile_image_url) VALUES (@email, @pass, @first, @last, @role, @status, @major, @grad, @phone, @profile) RETURNING id',
      ),
      parameters: {
        'email': adminEmail,
        'pass': adminHash,
        'first': 'Site',
        'last': 'Admin',
        'role': 'admin',
        'status': 'active',
        'major': 'Information Technology',
        'grad': 2009,
        'phone': '555-0000',
        'profile': null,
      },
    );
    adminId = adminRes[0][0] as int;
    inserted.add({'id': adminId, 'role': 'admin'});
    print('Inserted admin id=$adminId');
  }

  // Create ~20 alumni/pending users
  for (var i = 0; i < 20; i++) {
    final first = _pick(_firstNames);
    final last = _pick(_lastNames);
    final email = _email(first, last, i + 1);
    final pwd = 'password${i + 1}';
    final hash = hasher.hashpw(pwd, DBCrypt().gensalt());
    final role = 'alumni';
    final status = (i % 6 == 0) ? 'pending' : 'active';
    final major = _pick(_majors);
    final grad = 2005 + _rand.nextInt(18); // 2005 - 2022
    final phone = _phone();
    final useProfile = i % 3 == 0;
    final profileUrl = useProfile
        ? 'http://localhost:8080/uploads/profiles/profile_${(i % 6) + 1}.jpg'
        : null;

    // skip insert if email exists
    final exists = await connection.execute(
      Sql.named('SELECT id FROM users WHERE email = @email'),
      parameters: {'email': email},
    );
    if (exists.isNotEmpty) {
      final existingId = exists[0][0] as int;
      inserted.add({'id': existingId, 'role': role, 'email': email});
      print('User already exists: $email (id=$existingId)');
    } else {
      final r = await connection.execute(
        Sql.named(
          'INSERT INTO users (email, password, first_name, last_name, role, status, major, graduation_year, phone_number, profile_image_url) VALUES (@email, @pass, @first, @last, @role, @status, @major, @grad, @phone, @profile) RETURNING id',
        ),
        parameters: {
          'email': email,
          'pass': hash,
          'first': first,
          'last': last,
          'role': role,
          'status': status,
          'major': major,
          'grad': grad,
          'phone': phone,
          'profile': profileUrl,
        },
      );
      inserted.add({'id': r[0][0] as int, 'role': role, 'email': email});
      print('Inserted user $email');
    }
  }

  // Insert posts authored by active alumni
  final alumniIds = inserted
      .where((e) => e['role'] == 'alumni')
      .map((e) => e['id'] as int)
      .toList();
  final postTypes = ['news', 'event', 'update'];
  final sampleContents = [
    'Reunion meetup at the main campus next month. Join us!',
    'New mentoring program launched connecting alumni and students.',
    'Alumni spotlight: career journey from intern to manager.',
    'Volunteer opportunity: give a talk to current students.',
  ];

  for (var i = 0; i < 12; i++) {
    final author = alumniIds[_rand.nextInt(alumniIds.length)];
    await connection.execute(
      Sql.named(
        'INSERT INTO posts (author_id, title, content, type, image_url) VALUES (@a, @t, @c, @ty, @img)',
      ),
      parameters: {
        'a': author,
        't':
            '${_pick(['Campus Reunion', 'Mentorship Launch', 'Alumni News', 'Career Tips', 'Volunteer Call'])} #${i + 1}',
        'c': _pick(sampleContents),
        'ty': _pick(postTypes),
        'img': 'http://localhost:8081/uploads/posts/post_${(i % 8) + 1}.jpg',
      },
    );
  }
  print('Inserted sample posts');

  // Insert jobs posted by alumni
  final companies = [
    'Acme Corp',
    'Globex',
    'Innotech',
    'Stellar Labs',
    'Brightside',
  ];
  final jobs = [
    {'title': 'Software Engineer', 'loc': 'Remote', 'salary': '60k-90k'},
    {'title': 'Product Manager', 'loc': 'New York, NY', 'salary': '80k-120k'},
    {'title': 'UX Designer', 'loc': 'San Francisco, CA', 'salary': '70k-100k'},
    {'title': 'Data Analyst', 'loc': 'Remote', 'salary': '50k-75k'},
  ];

  for (var i = 0; i < 6; i++) {
    final comp = _pick(companies);
    final job = jobs[_rand.nextInt(jobs.length)];
    final poster = alumniIds[_rand.nextInt(alumniIds.length)];
    await connection.execute(
      Sql.named(
        'INSERT INTO jobs (company_name, job_title, description, location, salary_range, contact_email, posted_by_id) VALUES (@c, @j, @d, @l, @s, @e, @p)',
      ),
      parameters: {
        'c': comp,
        'j': job['title'],
        'd': 'We are hiring: ${job['title']} at $comp. Apply now.',
        'l': job['loc'],
        's': job['salary'],
        'e': 'jobs@${comp.toLowerCase().replaceAll(' ', '')}.com',
        'p': poster,
      },
    );
  }
  print('Inserted sample jobs');

  // Insert activity logs for some users
  for (var i = 0; i < 10; i++) {
    final user = inserted[_rand.nextInt(inserted.length)]['id'] as int;
    final action = _pick([
      'LOGIN',
      'UPDATE_PROFILE',
      'CREATE_POST',
      'APPLY_JOB',
    ]);
    await connection.execute(
      Sql.named(
        'INSERT INTO activity_logs (user_id, action, details) VALUES (@u, @a, @d)',
      ),
      parameters: {'u': user, 'a': action, 'd': 'Seeded action $action'},
    );
  }
  print('Inserted activity logs');

  await connection.close();
  print('✅ Realistic data seeding complete');
}
