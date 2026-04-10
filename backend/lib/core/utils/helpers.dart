import '../../config/app_config.dart';

class Helpers {
  static String fixUrl(String? url) {
    if (url == null) return '';
    // This helper helps replace 'localhost' with serverIp for client-side access (useful for mobile tests)
    return url.replaceAll('localhost', AppConfig.serverIp);
  }
}
