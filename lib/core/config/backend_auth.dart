import 'app_config.dart';
import '../../features/settings/services/backend_auth_service.dart';

typedef TokenReader = String Function();
typedef TokenWriter = void Function(String token);
typedef BaseUrlReader = String Function();

class BackendAuth {
  final BackendAuthService _service;
  final BaseUrlReader baseUrl;
  final TokenReader readToken;
  final TokenWriter writeToken;

  BackendAuth({
    BackendAuthService? service,
    required this.baseUrl,
    required this.readToken,
    required this.writeToken,
  }) : _service = service ?? BackendAuthService();

  String resolveBaseUrl() {
    final stored = baseUrl().trim();
    if (stored.isNotEmpty) {
      return stored;
    }
    return AppConfig.resolveBackendBaseUrl();
  }

  Future<String> ensureToken({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final existing = readToken().trim();
      if (existing.isNotEmpty) {
        return existing;
      }
    }
    final apiKey = AppConfig.authApiKey.trim();
    if (apiKey.isEmpty) {
      throw Exception(
        'Missing AUTH_API_KEY. Add it to .env (e.g. AUTH_API_KEY=dev-key).',
      );
    }
    final url = resolveBaseUrl();
    if (url.isEmpty) {
      throw Exception(
        'Missing backend URL. Set BACKEND_BASE_URL in .env or Settings.',
      );
    }
    final token = await _service.fetchToken(baseUrl: url, apiKey: apiKey);
    writeToken(token);
    return token;
  }
}
