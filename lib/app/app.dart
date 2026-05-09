import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/storage/lesson_pdf_repository.dart';
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
    return RepositoryProvider<LessonPdfRepository>(
      create: (_) => LessonPdfRepository(),
      child: BlocProvider(
        create: (_) => ThemeCubit(prefs: prefs, initial: initialThemeMode),
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
