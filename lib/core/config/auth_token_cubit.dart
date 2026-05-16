import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthTokenCubit extends Cubit<String> {
  static const _key = 'backend_jwt';

  final SharedPreferences _prefs;

  AuthTokenCubit({
    required SharedPreferences prefs,
    required String initial,
  })  : _prefs = prefs,
        super(initial);

  static String readStoredToken(SharedPreferences prefs) =>
      prefs.getString(_key)?.trim() ?? '';

  void setToken(String token) {
    final v = token.trim();
    if (v.isEmpty) {
      _prefs.remove(_key);
      emit('');
      return;
    }
    _prefs.setString(_key, v);
    emit(v);
  }

  void clear() => setToken('');
}

