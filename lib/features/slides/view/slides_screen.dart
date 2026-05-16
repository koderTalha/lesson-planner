import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/auth_token_cubit.dart';
import '../../../core/config/backend_auth.dart';
import '../../../core/config/backend_url_cubit.dart';
import '../../../core/storage/slide_pptx_repository.dart';
import '../../../shared/widgets/widgets.dart';
import '../../shell/bloc/nav_cubit.dart';
import '../bloc/slides_cubit.dart';
import '../bloc/slides_state.dart';
import '../services/slides_backend_service.dart';

class SlidesScreen extends StatelessWidget {
  const SlidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (c) {
        final auth = BackendAuth(
          baseUrl: () => c.read<BackendUrlCubit>().state,
          readToken: () => c.read<AuthTokenCubit>().state,
          writeToken: (t) => c.read<AuthTokenCubit>().setToken(t),
        );
        return SlidesCubit(
          c.read<SlidePptxRepository>(),
          backend: SlidesBackendService(
            baseUrlProvider: () {
              final stored = c.read<BackendUrlCubit>().state.trim();
              return stored.isNotEmpty
                  ? stored
                  : AppConfig.resolveBackendBaseUrl();
            },
            ensureAuth: auth.ensureToken,
          ),
        );
      },
      child: const _SlidesView(),
    );
  }
}

class _SlidesView extends StatefulWidget {
  const _SlidesView();

  @override
  State<_SlidesView> createState() => _SlidesViewState();
}

class _SlidesViewState extends State<_SlidesView> {
  final _subject = TextEditingController();
  final _topic = TextEditingController();
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _classLevel = TextEditingController();
  final _audience = TextEditingController(text: 'Grade 9 students');
  final _tone = TextEditingController(
    text: 'Clear, teacher-style, exam-focused',
  );
  final _slides = TextEditingController(text: '8');
  String _theme = 'brand';

  @override
  void dispose() {
    for (final c in [
      _subject,
      _topic,
      _title,
      _subtitle,
      _classLevel,
      _audience,
      _tone,
      _slides,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _reset() {
    for (final c in [_subject, _topic, _title, _subtitle, _classLevel]) {
      c.clear();
    }
    _audience.text = 'Grade 9 students';
    _tone.text = 'Clear, teacher-style, exam-focused';
    _slides.text = '8';
    setState(() => _theme = 'brand');
  }

  void _generate(SlidesCubit cubit) {
    final n = int.tryParse(_slides.text.trim());
    cubit.generate(
      subject: _subject.text,
      topic: _topic.text,
      title: _title.text,
      subtitle: _subtitle.text.trim().isEmpty ? null : _subtitle.text,
      classLevel: _classLevel.text.trim().isEmpty ? null : _classLevel.text,
      audience: _audience.text.trim().isEmpty ? null : _audience.text,
      tone: _tone.text.trim().isEmpty ? null : _tone.text,
      slideCount: (n ?? 8).clamp(3, 30),
      theme: _theme,
    );
  }

  void _onSaved(BuildContext context, SlidesState state) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Saved “${state.lastSavedTitle ?? 'Slides'}” to Media'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            context.read<NavCubit>().select(1);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cubit = context.read<SlidesCubit>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Slides',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Generate · Auto-saved to Media',
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              child: BlocConsumer<SlidesCubit, SlidesState>(
                listenWhen: (a, b) =>
                    b.lastSavedAt != null && b.lastSavedAt != a.lastSavedAt,
                listener: _onSaved,
                builder: (context, state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AppHeroBanner(
                        icon: Icons.slideshow_rounded,
                        title: 'PPT / Slides',
                        subtitle:
                            'Fill in your lesson details, pick a theme, and generate. The deck is saved on this device and appears in Media.',
                      ),
                      const SizedBox(height: 22),
                      ResponsiveFormRow(
                        cells: [
                          ResponsiveFormCell(
                            LabeledTextField(
                              label: 'Subject',
                              controller: _subject,
                            ),
                          ),
                          ResponsiveFormCell(
                            LabeledTextField(
                              label: 'Topic',
                              controller: _topic,
                            ),
                            flex: 2,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      LabeledTextField(
                        label: 'Title',
                        required: true,
                        controller: _title,
                      ),
                      const SizedBox(height: 14),
                      LabeledTextField(
                        label: 'Subtitle / subtopic',
                        controller: _subtitle,
                      ),
                      const SizedBox(height: 14),
                      ResponsiveFormRow(
                        cells: [
                          ResponsiveFormCell(
                            LabeledTextField(
                              label: 'Class',
                              hint: 'e.g. Grade 9',
                              controller: _classLevel,
                            ),
                          ),
                          ResponsiveFormCell(
                            LabeledTextField(
                              label: 'Audience',
                              controller: _audience,
                            ),
                            flex: 2,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      LabeledTextField(
                        label: 'Tone',
                        controller: _tone,
                      ),
                      const SizedBox(height: 14),
                      ResponsiveFormRow(
                        cells: [
                          ResponsiveFormCell(
                            LabeledTextField(
                              label: 'Number of slides',
                              hint: '3–30',
                              controller: _slides,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          ResponsiveFormCell(
                            LabeledDropdown<String>(
                              label: 'Theme',
                              value: _theme,
                              items: const [
                                DropdownMenuItem(
                                  value: 'brand',
                                  child: Text('Untitled Presentation'),
                                ),
                                DropdownMenuItem(
                                  value: 'classroom',
                                  child: Text('Classroom Blue'),
                                ),
                                DropdownMenuItem(
                                  value: 'ocean',
                                  child: Text('Ocean Teal'),
                                ),
                                DropdownMenuItem(
                                  value: 'forest',
                                  child: Text('Forest Green'),
                                ),
                              ],
                              onChanged: (v) => setState(() => _theme = v),
                            ),
                            flex: 2,
                          ),
                        ],
                      ),
                      if (state.error != null) ...[
                        const SizedBox(height: 12),
                        AppInlineError(state.error!),
                      ],
                      const SizedBox(height: 20),
                      FormActionBar(
                        loading: state.generating,
                        onPrimary: () => _generate(cubit),
                        onSecondary: _reset,
                        primaryLabel: 'Generate Slides',
                        primaryLoadingLabel: 'Generating…',
                        primaryIcon: Icons.auto_awesome,
                        secondaryLabel: 'Reset',
                        secondaryIcon: Icons.restart_alt,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
