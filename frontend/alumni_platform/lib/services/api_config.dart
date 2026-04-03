import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiConfig {
  // 🛑 Update this IP to your computer's local IP address 🛑
  static const String _computerIP = '192.168.0.12'; 

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';
    } else if (Platform.isAndroid) {
      // Use 10.0.2.2 for Android Emulator, otherwise use computer IP for physical device
      // But for physical phone, we MUST use the computer's IP.
      return 'http://$_computerIP:8080';
    } else {
      return 'http://$_computerIP:8080';
    }
  }
}
