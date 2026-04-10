import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';
    } else if (Platform.isAndroid) {
      // Use 10.0.2.2 for Android Emulator, and the machine IP for physical devices.
      // Note: You might need a package like device_info_plus to detect this automatically, 
      // or just swap these based on your current testing target.
      // For now, I'll default to the physical IP as it's most common for mobile testing.
      // Replace with 'http://10.0.2.2:8080' if testing on Emulator.
      return 'http://192.168.0.12:8080'; 
    } else if (Platform.isIOS) {
      return 'http://192.168.0.12:8080';
    } else {
      // Windows, MacOS, Linux
      return 'http://localhost:8080';
    }
  }
}
