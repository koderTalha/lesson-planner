import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_config.dart';

class BackendUrlCubit extends Cubit<String> {
  static const _key = 'backend_base_url';

  final SharedPreferences _prefs;

  BackendUrlCubit({
    required SharedPreferences prefs,
    required String initial,
  })  : _prefs = prefs,
        super(initial);

  static String readStoredUrl(SharedPreferences prefs) {
    return prefs.getString(_key)?.trim().isNotEmpty == true
        ? prefs.getString(_key)!.trim()
        : AppConfig.resolveBackendBaseUrl();
  }

  void setUrl(String url) {
    final v = url.trim();
    if (v.isEmpty) {
      _prefs.remove(_key);
      emit(AppConfig.resolveBackendBaseUrl());
      return;
    }
    _prefs.setString(_key, v);
    emit(v);
  }

  void reset() => setUrl('');
}

