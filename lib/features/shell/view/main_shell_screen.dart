import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../lesson_plan/lesson_plan.dart';
import '../../media/media.dart';
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

class _MainShellView extends StatelessWidget {
  const _MainShellView();

  static const _pages = <Widget>[
    LessonPlanScreen(),
    MediaScreen(),
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
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

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
