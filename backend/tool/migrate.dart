import 'package:backend/config/database.dart';

Future<void> main() async {
  try {
    await DatabaseConfig.connect();
    print('Migration bootstrap completed successfully.');
  } finally {
    await DatabaseConfig.close();
  }
}
