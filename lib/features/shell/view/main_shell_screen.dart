import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/auth_token_cubit.dart';
import '../../../core/config/backend_auth.dart';
import '../../../core/config/backend_url_cubit.dart';
import '../../lesson_plan/lesson_plan.dart';
import '../../media/media.dart';
import '../../slides/slides.dart';
import '../../settings/settings.dart';
import '../bloc/nav_cubit.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NavCubit(),
      child: const _MainShellView(),
    );
  }
}

class _MainShellView extends StatefulWidget {
  const _MainShellView();

  @override
  State<_MainShellView> createState() => _MainShellViewState();
}

class _MainShellViewState extends State<_MainShellView> {
  static const _pages = <Widget>[
    LessonPlanScreen(),
    MediaScreen(),
    SlidesScreen(),
    SettingsScreen(),
  ];

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.auto_stories_outlined),
      selectedIcon: Icon(Icons.auto_stories),
      label: 'Lesson',
    ),
    NavigationDestination(
      icon: Icon(Icons.perm_media_outlined),
      selectedIcon: Icon(Icons.perm_media),
      label: 'Media',
    ),
    NavigationDestination(
      icon: Icon(Icons.slideshow_outlined),
      selectedIcon: Icon(Icons.slideshow),
      label: 'Slides',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapAuth());
  }

  Future<void> _bootstrapAuth() async {
    if (!mounted) return;
    try {
      final auth = BackendAuth(
        baseUrl: () => context.read<BackendUrlCubit>().state,
        readToken: () => context.read<AuthTokenCubit>().state,
        writeToken: (t) => context.read<AuthTokenCubit>().setToken(t),
      );
      await auth.ensureToken();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BlocBuilder<NavCubit, int>(
      builder: (context, index) => Scaffold(
        body: IndexedStack(index: index, children: _pages),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          child: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: context.read<NavCubit>().select,
            destinations: _destinations,
          ),
        ),
      ),
    );
  }
}
