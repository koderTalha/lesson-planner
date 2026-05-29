import 'package:equatable/equatable.dart';

class LessonPlanState extends Equatable {
  static const defaultSession = '2026-2027';
  static const defaultPeriod = '40 minutes';
  final String academicSession;
  final String period;
  final DateTime? date;
  final bool useAiObjectives;
  final bool loading;
  final String? error;
  final DateTime? lastSavedAt;
  final String? lastSavedTitle;

  const LessonPlanState({
    required this.academicSession,
    required this.period,
    this.date,
    required this.useAiObjectives,
    required this.loading,
    required this.error,
    this.lastSavedAt,
    this.lastSavedTitle,
  });

  factory LessonPlanState.initial() => const LessonPlanState(
        academicSession: defaultSession,
        period: defaultPeriod,
        date: null,
        useAiObjectives: true,
        loading: false,
        error: null,
      );

  LessonPlanState copyWith({
    String? academicSession,
    String? period,
    DateTime? date,
    bool clearDate = false,
    bool? useAiObjectives,
    bool? loading,
    String? error,
    bool clearError = false,
    DateTime? lastSavedAt,
    String? lastSavedTitle,
  }) {
    return LessonPlanState(
      academicSession: academicSession ?? this.academicSession,
      period: period ?? this.period,
      date: clearDate ? null : (date ?? this.date),
      useAiObjectives: useAiObjectives ?? this.useAiObjectives,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
      lastSavedTitle: lastSavedTitle ?? this.lastSavedTitle,
    );
  }

  @override
  List<Object?> get props => [
        academicSession,
        period,
        date,
        useAiObjectives,
        loading,
        error,
        lastSavedAt,
        lastSavedTitle,
      ];
}
