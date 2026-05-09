import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/theme_cubit.dart';
import '../../../shared/widgets/widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppHeroBanner(
                    icon: Icons.tune_rounded,
                    title: 'Personalize',
                    subtitle:
                        'Adjust appearance and preferences to make Lesson Studio yours.',
                  ),
                  const SizedBox(height: 24),
                  _SettingsCard(
                    title: 'Appearance',
                    subtitle: 'Switch between light, dark, or your system theme.',
                    child: BlocBuilder<ThemeCubit, ThemeMode>(
                      builder: (context, mode) => AppSegmentedToggle<ThemeMode>(
                        value: mode,
                        onChanged: context.read<ThemeCubit>().setMode,
                        options: const [
                          SegmentedOption(
                            value: ThemeMode.light,
                            label: 'Light',
                            icon: Icons.light_mode_outlined,
                          ),
                          SegmentedOption(
                            value: ThemeMode.dark,
                            label: 'Dark',
                            icon: Icons.dark_mode_outlined,
                          ),
                          SegmentedOption(
                            value: ThemeMode.system,
                            label: 'System',
                            icon: Icons.brightness_auto_outlined,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SettingsCard(
                    title: 'About',
                    subtitle: 'Lesson Studio · v1.0.0',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'AI-powered lesson plan generator with PDF export.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
