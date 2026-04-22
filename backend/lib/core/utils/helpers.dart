import '../../config/app_config.dart';

class Helpers {
  static String fixUrl(String? url) {
    if (url == null) return '';
    // Replace localhost with configured DB host for environments that cannot resolve localhost.
    return url.replaceAll('localhost', AppConfig.dbHost);
  }
}
