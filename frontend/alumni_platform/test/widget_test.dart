import 'package:flutter_test/flutter_test.dart';
import 'package:alumni_platform/services/api_config.dart';

void main() {
  test('ApiConfig has a non-empty base URL', () {
    expect(ApiConfig.baseUrl, isNotEmpty);
  });
}
