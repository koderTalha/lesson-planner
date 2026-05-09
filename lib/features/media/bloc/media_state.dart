import 'package:equatable/equatable.dart';

import '../../../core/storage/saved_lesson_pdf.dart';

class MediaState extends Equatable {
  final List<SavedLessonPdf> items;
  final bool loading;
  final String? error;

  const MediaState({
    this.items = const [],
    this.loading = false,
    this.error,
  });

  bool get isEmpty => !loading && items.isEmpty && error == null;

  MediaState copyWith({
    List<SavedLessonPdf>? items,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return MediaState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [items, loading, error];
}
