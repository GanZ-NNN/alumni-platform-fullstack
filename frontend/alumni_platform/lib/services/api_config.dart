class ApiConfig {
  static const String _defaultBaseUrl = 'http://localhost:8080';

  static String get baseUrl {
    const envBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: _defaultBaseUrl,
    );
    return envBaseUrl.trim().isEmpty ? _defaultBaseUrl : envBaseUrl.trim();
  }
}
