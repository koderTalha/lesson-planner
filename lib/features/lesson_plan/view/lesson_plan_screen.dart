import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/storage/lesson_pdf_repository.dart';
import '../../../shared/widgets/widgets.dart';
import '../../shell/bloc/nav_cubit.dart';
import '../bloc/lesson_plan_bloc.dart';
import '../bloc/lesson_plan_event.dart';
import '../bloc/lesson_plan_state.dart';
import '../models/lesson_plan_input.dart';

class LessonPlanScreen extends StatelessWidget {
  const LessonPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (c) => LessonPlanBloc(
        repository: c.read<LessonPdfRepository>(),
      ),
      child: const _LessonPlanView(),
    );
  }
}

class _LessonPlanView extends StatefulWidget {
  const _LessonPlanView();

  @override
  State<_LessonPlanView> createState() => _LessonPlanViewState();
}

class _LessonPlanViewState extends State<_LessonPlanView> {
  static const _sessions = ['2025-2026', '2026-2027', '2027-2028'];
  static const _periods = [
    '35 minutes',
    '40 minutes',
    '45 minutes',
    '50 minutes',
    '60 minutes',
  ];

  final _institution = TextEditingController();
  final _plannerNo = TextEditingController();
  final _week = TextEditingController();
  final _teacher = TextEditingController();
  final _subject = TextEditingController();
  final _className = TextEditingController();
  final _unit = TextEditingController();
  final _title = TextEditingController();
  final _topic = TextEditingController();
  final _subTopic = TextEditingController();
  final _ownObjectives = TextEditingController();

  List<TextEditingController> get _allControllers => [
        _institution,
        _plannerNo,
        _week,
        _teacher,
        _subject,
        _className,
        _unit,
        _title,
        _topic,
        _subTopic,
        _ownObjectives,
      ];

  @override
  void dispose() {
    for (final c in _allControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onReset() {
    for (final c in _allControllers) {
      c.clear();
    }
    context.read<LessonPlanBloc>().add(const LessonPlanResetRequested());
  }

  void _onGenerate(LessonPlanState state) {
    final input = LessonPlanInput(
      institutionName: _institution.text.trim(),
      academicSession: state.academicSession,
      plannerNo: _plannerNo.text.trim(),
      week: _week.text.trim(),
      date: state.date,
      teacherName: _teacher.text.trim(),
      subject: _subject.text.trim(),
      className: _className.text.trim(),
      periodDuration: state.period,
      unit: _unit.text.trim(),
      title: _title.text.trim(),
      topic: _topic.text.trim(),
      subTopic: _subTopic.text.trim(),
      useAiForObjectives: state.useAiObjectives,
      ownLessonObjectives: _ownObjectives.text.trim(),
    );
    context.read<LessonPlanBloc>().add(LessonPlanGenerateRequested(input));
  }

  List<DropdownMenuItem<String>> _items(List<String> values) => [
        for (final v in values) DropdownMenuItem(value: v, child: Text(v)),
      ];

  void _onSaved(BuildContext context, LessonPlanState state) {
    final messenger = ScaffoldMessenger.of(context);
    final scheme = Theme.of(context).colorScheme;
    final title = state.lastSavedTitle ?? 'Lesson plan';
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Saved “$title” to Media'),
        action: SnackBarAction(
          label: 'View',
          textColor: scheme.onPrimary,
          onPressed: () => context.read<NavCubit>().select(1),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bloc = context.read<LessonPlanBloc>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Lesson Studio',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Plan · Generate · Share',
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
              child: BlocConsumer<LessonPlanBloc, LessonPlanState>(
                listenWhen: (prev, curr) =>
                    curr.lastSavedAt != null &&
                    curr.lastSavedAt != prev.lastSavedAt,
                listener: _onSaved,
                builder: (context, state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AppHeroBanner(
                        icon: Icons.auto_stories_rounded,
                        title: 'Daily lesson plan',
                        subtitle:
                            'School-style layout: fill the form, AI writes every block, export PDF.',
                      ),
                      const SizedBox(height: 22),
                      ResponsiveFormRow(
                        cells: [
                          ResponsiveFormCell(
                            LabeledTextField(
                              label: 'Institution Name',
                              controller: _institution,
                            ),
                            flex: 2,
                          ),
                          ResponsiveFormCell(
                            LabeledDropdown<String>(
                              label: 'Academic Session',
                              value: state.academicSession,
                              items: _items(_sessions),
                              onChanged: (v) =>
                                  bloc.add(LessonPlanSessionChanged(v)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ResponsiveFormRow(
                        cells: [
                          ResponsiveFormCell(
                            LabeledTextField(
                              label: 'Planner',
                              hint: 'e.g. 4.1',
                              controller: _plannerNo,
                            ),
                          ),
                          ResponsiveFormCell(
                            LabeledTextField(
                              label: 'Week #',
                              hint: 'e.g. 04',
                              controller: _week,
                            ),
                          ),
                          ResponsiveFormCell(
                            LabeledDateField(
                              label: 'Date',
                              value: state.date,
                              onChanged: (d) =>
                                  bloc.add(LessonPlanDateChanged(d)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ResponsiveFormRow(
                        cells: [
                          ResponsiveFormCell(
                            LabeledTextField(
                              label: 'Developed By',
                              hint: 'Teacher name',
                              controller: _teacher,
                            ),
                          ),
                          ResponsiveFormCell(
                            LabeledTextField(
                              label: 'Subject',
                              required: true,
                              controller: _subject,
                            ),
                          ),
                          ResponsiveFormCell(
                            LabeledTextField(
                              label: 'Class',
                              required: true,
                              controller: _className,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ResponsiveFormRow(
                        cells: [
                          ResponsiveFormCell(
                            LabeledDropdown<String>(
                              label: 'Period / Duration',
                              value: state.period,
                              items: _items(_periods),
                              onChanged: (v) =>
                                  bloc.add(LessonPlanPeriodChanged(v)),
                            ),
                          ),
                          ResponsiveFormCell(
                            LabeledTextField(
                              label: 'Unit',
                              hint: 'e.g. 02',
                              controller: _unit,
                            ),
                          ),
                          ResponsiveFormCell(
                            LabeledTextField(
                              label: 'Title',
                              hint: 'Lesson title',
                              controller: _title,
                            ),
                            flex: 2,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      LabeledTextField(
                        label: 'Topic',
                        required: true,
                        controller: _topic,
                      ),
                      const SizedBox(height: 14),
                      LabeledTextField(
                        label: 'Sub-Topic',
                        controller: _subTopic,
                      ),
                      const SizedBox(height: 16),
                      const FieldLabel('AI / Own (DLO/SLO)'),
                      AppSegmentedToggle<bool>(
                        value: state.useAiObjectives,
                        onChanged: (v) =>
                            bloc.add(LessonPlanObjectivesModeChanged(v)),
                        options: const [
                          SegmentedOption(
                            value: true,
                            label: 'AI',
                            icon: Icons.auto_awesome,
                          ),
                          SegmentedOption(
                            value: false,
                            label: 'Own',
                            icon: Icons.edit_note,
                          ),
                        ],
                      ),
                      if (!state.useAiObjectives) ...[
                        const SizedBox(height: 14),
                        LabeledTextField(
                          label: 'Your lesson objectives',
                          hint: 'Enter your DLOs/SLOs here',
                          controller: _ownObjectives,
                          maxLines: 4,
                        ),
                      ],
                      if (state.error != null) ...[
                        const SizedBox(height: 12),
                        AppInlineError(state.error!),
                      ],
                      const SizedBox(height: 20),
                      FormActionBar(
                        loading: state.loading,
                        onPrimary: () => _onGenerate(state),
                        onSecondary: _onReset,
                        primaryLabel: 'Generate Lesson Plan',
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
