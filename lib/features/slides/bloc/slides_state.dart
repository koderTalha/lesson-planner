import 'package:equatable/equatable.dart';

class SlidesState extends Equatable {
  final bool generating;
  final String? error;
  final DateTime? lastSavedAt;
  final String? lastSavedTitle;

  const SlidesState({
    this.generating = false,
    this.error,
    this.lastSavedAt,
    this.lastSavedTitle,
  });

  SlidesState copyWith({
    bool? generating,
    String? error,
    bool clearError = false,
    DateTime? lastSavedAt,
    String? lastSavedTitle,
  }) {
    return SlidesState(
      generating: generating ?? this.generating,
      error: clearError ? null : (error ?? this.error),
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
      lastSavedTitle: lastSavedTitle ?? this.lastSavedTitle,
    );
  }

  @override
  List<Object?> get props => [generating, error, lastSavedAt, lastSavedTitle];
}
