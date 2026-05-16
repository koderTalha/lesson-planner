import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/auth_token_cubit.dart';
import '../core/config/backend_url_cubit.dart';
import '../core/storage/lesson_pdf_repository.dart';
import '../core/storage/slide_pptx_repository.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_cubit.dart';
import '../features/shell/shell.dart';

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  final ThemeMode initialThemeMode;

  const MyApp({
    super.key,
    required this.prefs,
    required this.initialThemeMode,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<LessonPdfRepository>(
          create: (_) => LessonPdfRepository(),
        ),
        RepositoryProvider<SlidePptxRepository>(
          create: (_) => SlidePptxRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => ThemeCubit(prefs: prefs, initial: initialThemeMode),
          ),
          BlocProvider(
            create: (_) => BackendUrlCubit(
              prefs: prefs,
              initial: BackendUrlCubit.readStoredUrl(prefs),
            ),
          ),
          BlocProvider(
            create: (_) => AuthTokenCubit(
              prefs: prefs,
              initial: AuthTokenCubit.readStoredToken(prefs),
            ),
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, mode) => MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Lesson Plan Generator',
            theme: buildLightTheme(),
            darkTheme: buildDarkTheme(),
            themeMode: mode,
            home: const MainShell(),
          ),
        ),
      ),
    );
  }
}
