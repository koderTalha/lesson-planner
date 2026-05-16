import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

class SlidesBackendService {
  final http.Client _client;
  final String Function() _baseUrlProvider;
  final Future<String> Function({bool forceRefresh}) _ensureAuth;

  SlidesBackendService({
    http.Client? client,
    String Function()? baseUrlProvider,
    required Future<String> Function({bool forceRefresh}) ensureAuth,
  })  : _client = client ?? http.Client(),
        _baseUrlProvider = baseUrlProvider ?? AppConfig.resolveBackendBaseUrl,
        _ensureAuth = ensureAuth;

  Future<Uint8List> generatePptx({
    required String subject,
    required String topic,
    required String title,
    String? subtitle,
    required int slideCount,
    String? classLevel,
    String? audience,
    String? tone,
    String theme = 'brand',
  }) async {
    final base = _baseUrlProvider().trim();
    if (base.isEmpty) {
      throw Exception('Missing BACKEND_BASE_URL in .env or Settings.');
    }
    final uri = Uri.parse(base).replace(path: '/api/v1/ppt/generate_ai');
    final body = {
      'subject': subject,
      'topic': topic,
      'title': title,
      'subtitle': subtitle,
      'slide_count': slideCount,
      if (classLevel != null && classLevel.trim().isNotEmpty)
        'class_level': classLevel.trim(),
      if (audience != null && audience.trim().isNotEmpty)
        'audience': audience.trim(),
      if (tone != null && tone.trim().isNotEmpty) 'tone': tone.trim(),
      'theme': theme.trim().isEmpty ? 'brand' : theme.trim(),
    };
    return _postPptx(uri, body, retried: false);
  }

  Future<Uint8List> _postPptx(
    Uri uri,
    Map<String, dynamic> body, {
    required bool retried,
  }) async {
    final token = await _ensureAuth(forceRefresh: retried);
    final res = await _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 120));

    if (res.statusCode == 401 && !retried) {
      return _postPptx(uri, body, retried: true);
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'Backend failed (${res.statusCode}): ${res.body.isNotEmpty ? res.body : res.reasonPhrase}',
      );
    }
    if (res.bodyBytes.isEmpty) {
      throw Exception('Backend returned empty PPTX');
    }
    return res.bodyBytes;
  }
}
