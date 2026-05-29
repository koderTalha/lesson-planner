import 'package:equatable/equatable.dart';

import '../models/lesson_plan_input.dart';

sealed class LessonPlanEvent extends Equatable {
  const LessonPlanEvent();

  @override
  List<Object?> get props => [];
}

class LessonPlanSessionChanged extends LessonPlanEvent {
  final String session;
  const LessonPlanSessionChanged(this.session);
  @override
  List<Object?> get props => [session];
}

class LessonPlanPeriodChanged extends LessonPlanEvent {
  final String period;
  const LessonPlanPeriodChanged(this.period);
  @override
  List<Object?> get props => [period];
}

class LessonPlanDateChanged extends LessonPlanEvent {
  final DateTime? date;
  const LessonPlanDateChanged(this.date);
  @override
  List<Object?> get props => [date];
}

class LessonPlanObjectivesModeChanged extends LessonPlanEvent {
  final bool useAi;
  const LessonPlanObjectivesModeChanged(this.useAi);
  @override
  List<Object?> get props => [useAi];
}

class LessonPlanResetRequested extends LessonPlanEvent {
  const LessonPlanResetRequested();
}

class LessonPlanGenerateRequested extends LessonPlanEvent {
  final LessonPlanInput input;
  const LessonPlanGenerateRequested(this.input);
  @override
  List<Object?> get props => [input];
}
