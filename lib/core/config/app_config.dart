import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static const String defaultGeminiModel = 'gemini-2.5-flash';

  static String get _geminiApiKeyDefine =>
      const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  static String get _geminiModelDefine =>
      const String.fromEnvironment('GEMINI_MODEL', defaultValue: '');

  static String geminiApiKeyFromEnvFile() {
    if (!dotenv.isInitialized) {
      return '';
    }
    return dotenv.maybeGet('GEMINI_API_KEY')?.trim() ?? '';
  }

  static String geminiModelFromEnvFile() {
    if (!dotenv.isInitialized) {
      return '';
    }
    return dotenv.maybeGet('GEMINI_MODEL')?.trim() ?? '';
  }

  static String get geminiApiKey {
    final d = _geminiApiKeyDefine.trim();
    if (d.isNotEmpty) {
      return d;
    }
    return geminiApiKeyFromEnvFile();
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
}
