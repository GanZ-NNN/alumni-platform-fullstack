import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../../config/app_config.dart';

class EmailService {
  static final String _username = AppConfig.emailUsername; // e.g., 'your-email@gmail.com'
  static final String _password = AppConfig.emailPassword; // e.g., 'your-app-password'

  static final _smtpServer = gmail(_username, _password);

  static Future<bool> sendPasswordResetCode(String email, String code) async {
    final message = Message()
      ..from = Address(_username, 'Alumni Platform')
      ..recipients.add(email)
      ..subject = 'Password Reset Code'
      ..text = 'Your password reset code is: $code\n\nThis code will expire in 15 minutes.';

    try {
      await send(message, _smtpServer);
      return true;
    } catch (e) {
      print('Email sending failed: $e');
      return false;
    }
  }

  static Future<bool> sendApprovalNotification(String email, String name) async {
    final message = Message()
      ..from = Address(_username, 'Alumni Platform')
      ..recipients.add(email)
      ..subject = 'Account Approved'
      ..text = 'Hello $name,\n\nYour alumni account has been approved. You can now log in and access all features.';

    try {
      await send(message, _smtpServer);
      return true;
    } catch (e) {
      print('Email sending failed: $e');
      return false;
    }
  }
}
