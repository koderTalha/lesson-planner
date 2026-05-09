import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_config.dart';
import '../../../core/storage/lesson_pdf_repository.dart';
import '../services/ai_lesson_service.dart';
import '../services/lesson_plan_pdf.dart';
import 'lesson_plan_event.dart';
import 'lesson_plan_state.dart';

class LessonPlanBloc extends Bloc<LessonPlanEvent, LessonPlanState> {
  final AiLessonService _ai;
  final LessonPdfRepository _repo;

  LessonPlanBloc({
    required LessonPdfRepository repository,
    AiLessonService? aiService,
  })  : _ai = aiService ?? AiLessonService(),
        _repo = repository,
        super(LessonPlanState.initial()) {
    on<LessonPlanSessionChanged>(
      (e, emit) => emit(state.copyWith(academicSession: e.session)),
    );
    on<LessonPlanPeriodChanged>(
      (e, emit) => emit(state.copyWith(period: e.period)),
    );
    on<LessonPlanDateChanged>(
      (e, emit) => emit(state.copyWith(date: e.date)),
    );
    on<LessonPlanObjectivesModeChanged>(
      (e, emit) => emit(state.copyWith(useAiObjectives: e.useAi)),
    );
    on<LessonPlanResetRequested>(
      (_, emit) => emit(LessonPlanState.initial()),
    );
    on<LessonPlanGenerateRequested>(_onGenerate);
  }

  Future<void> _onGenerate(
    LessonPlanGenerateRequested event,
    Emitter<LessonPlanState> emit,
  ) async {
    final input = event.input;
    if (input.subject.isEmpty ||
        input.className.isEmpty ||
        input.topic.isEmpty) {
      emit(state.copyWith(error: 'Please fill Subject, Class, and Topic.'));
      return;
    }
    if (!input.useAiForObjectives && input.ownLessonObjectives.isEmpty) {
      emit(
        state.copyWith(
          error: 'Enter your lesson objectives or switch to AI.',
        ),
      );
      return;
    }
    final key = AppConfig.geminiApiKey;
    if (key.isEmpty) {
      emit(
        state.copyWith(
          error:
              'Missing GEMINI_API_KEY. Add it to assets/config/secrets.env or build with --dart-define=GEMINI_API_KEY=…',
        ),
      );
      return;
    }

    emit(state.copyWith(loading: true, clearError: true));

    try {
      final gen = await _ai.generate(
        input,
        apiKey: key,
        model: AppConfig.resolveGeminiModel(),
      );
      if (emit.isDone) return;
      final pdf = await LessonPlanPdf.build(input: input, gen: gen);
      if (emit.isDone) return;
      final saved = await _repo.save(bytes: pdf, input: input);
      if (emit.isDone) return;
      await HapticFeedback.mediumImpact();
      if (emit.isDone) return;
      emit(state.copyWith(
        loading: false,
        lastSavedAt: saved.createdAt,
        lastSavedTitle: saved.displayTitle,
      ));
    } catch (e) {
      if (emit.isDone) return;
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }
}
