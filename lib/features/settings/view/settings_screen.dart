import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/auth_token_cubit.dart';
import '../../../core/config/backend_url_cubit.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../shared/widgets/widgets.dart';
import '../services/backend_auth_service.dart';

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
                  const _BackendSettingsCard(),
                  const SizedBox(height: 16),
                  const _BackendAuthCard(),
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

class _BackendSettingsCard extends StatefulWidget {
  const _BackendSettingsCard();

  @override
  State<_BackendSettingsCard> createState() => _BackendSettingsCardState();
}

class _BackendSettingsCardState extends State<_BackendSettingsCard> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<BackendUrlCubit>();
    return BlocBuilder<BackendUrlCubit, String>(
      builder: (context, url) {
        if (_controller.text.isEmpty) {
          _controller.text = url;
        }
        return _SettingsCard(
          title: 'Backend',
          subtitle: 'Set the PPT generator server base URL.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FieldLabel('Base URL'),
              TextField(
                controller: _controller,
                decoration: appInputDecoration(
                  context,
                  hint: AppConfig.defaultBackendBaseUrl,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () => cubit.setUrl(_controller.text),
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Save'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      cubit.reset();
                      _controller.text = cubit.state;
                      FocusScope.of(context).unfocus();
                    },
                    icon: const Icon(Icons.restart_alt, size: 18),
                    label: const Text('Reset'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Tip: on a real phone, use your computer IP (e.g. http://192.168.1.10:8000).',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BackendAuthCard extends StatefulWidget {
  const _BackendAuthCard();

  @override
  State<_BackendAuthCard> createState() => _BackendAuthCardState();
}

class _BackendAuthCardState extends State<_BackendAuthCard> {
  final _apiKey = TextEditingController();
  final _token = TextEditingController();
  final _auth = BackendAuthService();
  bool _loading = false;

  @override
  void dispose() {
    _apiKey.dispose();
    _token.dispose();
    super.dispose();
  }

  Future<void> _getToken(BuildContext context) async {
    final baseUrl = context.read<BackendUrlCubit>().state.trim();
    final apiKey = _apiKey.text.trim();
    if (baseUrl.isEmpty || apiKey.isEmpty) return;
    setState(() => _loading = true);
    try {
      final token = await _auth.fetchToken(baseUrl: baseUrl, apiKey: apiKey);
      if (!context.mounted) return;
      context.read<AuthTokenCubit>().setToken(token);
      _token.text = token;
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('JWT saved.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokenCubit = context.read<AuthTokenCubit>();
    return BlocBuilder<AuthTokenCubit, String>(
      builder: (context, token) {
        if (_token.text.isEmpty) {
          _token.text = token;
        }
        return _SettingsCard(
          title: 'Auth (JWT)',
          subtitle: 'Get and store a JWT to call protected endpoints.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FieldLabel('API key'),
              TextField(
                controller: _apiKey,
                obscureText: true,
                decoration: appInputDecoration(context, hint: 'AUTH_API_KEY'),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: _loading ? null : () => _getToken(context),
                    icon: _loading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.vpn_key_outlined, size: 18),
                    label: Text(_loading ? 'Requesting…' : 'Get JWT'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _loading
                        ? null
                        : () {
                            tokenCubit.clear();
                            _token.clear();
                            FocusScope.of(context).unfocus();
                          },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Clear JWT'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const FieldLabel('Stored JWT'),
              TextField(
                controller: _token,
                readOnly: true,
                maxLines: 3,
                decoration: appInputDecoration(
                  context,
                  hint: 'No token stored',
                ),
              ),
            ],
          ),
        );
      },
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
