import 'package:equatable/equatable.dart';

import '../../../core/storage/saved_lesson_pdf.dart';
import '../../../core/storage/saved_slide_pptx.dart';
import '../../../shared/widgets/media_capsule_switch.dart';

class MediaState extends Equatable {
  final MediaLibraryKind kind;
  final List<SavedLessonPdf> pdfItems;
  final List<SavedSlidePptx> slideItems;
  final bool loading;
  final String? error;

  const MediaState({
    this.kind = MediaLibraryKind.pdf,
    this.pdfItems = const [],
    this.slideItems = const [],
    this.loading = false,
    this.error,
  });

  bool get isEmpty {
    if (loading) return false;
    if (error != null) return false;
    return kind == MediaLibraryKind.pdf
        ? pdfItems.isEmpty
        : slideItems.isEmpty;
  }

  MediaState copyWith({
    MediaLibraryKind? kind,
    List<SavedLessonPdf>? pdfItems,
    List<SavedSlidePptx>? slideItems,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return MediaState(
      kind: kind ?? this.kind,
      pdfItems: pdfItems ?? this.pdfItems,
      slideItems: slideItems ?? this.slideItems,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [kind, pdfItems, slideItems, loading, error];
}
