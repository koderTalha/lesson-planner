import 'dart:convert';

import 'package:http/http.dart' as http;

class BackendAuthService {
  final http.Client _client;

  BackendAuthService({http.Client? client}) : _client = client ?? http.Client();

  Future<String> fetchToken({
    required String baseUrl,
    required String apiKey,
  }) async {
    final uri = Uri.parse(baseUrl.trim()).replace(path: '/api/v1/auth/token');
    final res = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'api_key': apiKey}),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'Auth failed (${res.statusCode}): ${res.body.isNotEmpty ? res.body : res.reasonPhrase}',
      );
    }
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final token = (decoded['access_token'] as String?)?.trim() ?? '';
    if (token.isEmpty) {
      throw Exception('Auth returned empty token');
    }
    return token;
  }
}

