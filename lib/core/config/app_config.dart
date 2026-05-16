import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static const String defaultGeminiModel = 'gemini-2.5-flash';
  static const String defaultBackendBaseUrl = 'http://127.0.0.1:8000';

  static String get _geminiApiKeyDefine =>
      const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  static String get _geminiModelDefine =>
      const String.fromEnvironment('GEMINI_MODEL', defaultValue: '');

  static String get _backendBaseUrlDefine =>
      const String.fromEnvironment('BACKEND_BASE_URL', defaultValue: '');

  static String get _authApiKeyDefine =>
      const String.fromEnvironment('AUTH_API_KEY', defaultValue: '');

  static String _cleanEnvValue(String raw) {
    var v = raw.trim();
    if (v.startsWith('export ')) {
      v = v.substring(7).trim();
    }
    if (v.length >= 2) {
      final q = v[0];
      if ((q == '"' || q == "'") && v.endsWith(q)) {
        v = v.substring(1, v.length - 1).trim();
      }
    }
    return v;
  }

  static String geminiApiKeyFromEnvFile() {
    if (!dotenv.isInitialized) {
      return '';
    }
    return _cleanEnvValue(dotenv.maybeGet('GEMINI_API_KEY') ?? '');
  }

  static String geminiModelFromEnvFile() {
    if (!dotenv.isInitialized) {
      return '';
    }
    return _cleanEnvValue(dotenv.maybeGet('GEMINI_MODEL') ?? '');
  }

  static String backendBaseUrlFromEnvFile() {
    if (!dotenv.isInitialized) {
      return '';
    }
    return _cleanEnvValue(dotenv.maybeGet('BACKEND_BASE_URL') ?? '');
  }

  static String authApiKeyFromEnvFile() {
    if (!dotenv.isInitialized) {
      return '';
    }
    return _cleanEnvValue(dotenv.maybeGet('AUTH_API_KEY') ?? '');
  }

  static String get geminiApiKey {
    final d = _geminiApiKeyDefine.trim();
    if (d.isNotEmpty) {
      return d;
    }
    return geminiApiKeyFromEnvFile();
  }

  static String get authApiKey {
    final d = _authApiKeyDefine.trim();
    if (d.isNotEmpty) {
      return d;
    }
    return authApiKeyFromEnvFile();
  }

  static String resolveGeminiModel() {
    final d = _geminiModelDefine.trim();
    if (d.isNotEmpty) {
      return d;
    }
    final f = geminiModelFromEnvFile();
    if (f.isNotEmpty) {
      return f;
    }
    return defaultGeminiModel;
  }

  static String resolveBackendBaseUrl() {
    final d = _backendBaseUrlDefine.trim();
    if (d.isNotEmpty) {
      return d;
    }
    final f = backendBaseUrlFromEnvFile();
    if (f.isNotEmpty) {
      return f;
    }
    return defaultBackendBaseUrl;
  }
}
