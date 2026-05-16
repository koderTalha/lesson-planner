import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/storage/slide_pptx_repository.dart';
import '../services/slides_backend_service.dart';
import 'slides_state.dart';

class SlidesCubit extends Cubit<SlidesState> {
  final SlidePptxRepository _repo;
  final SlidesBackendService _backend;

  SlidesCubit(this._repo, {required SlidesBackendService backend})
      : _backend = backend,
        super(const SlidesState());

  Future<void> generate({
    required String subject,
    required String topic,
    required String title,
    String? subtitle,
    String? classLevel,
    String? audience,
    String? tone,
    required int slideCount,
    String theme = 'brand',
  }) async {
    final t = title.trim();
    if (t.isEmpty) {
      emit(state.copyWith(error: 'Please enter a title.'));
      return;
    }

    emit(state.copyWith(generating: true, clearError: true));
    try {
      final Uint8List bytes = await _backend.generatePptx(
        subject: subject.trim(),
        topic: topic.trim(),
        title: t,
        subtitle: subtitle?.trim(),
        classLevel: classLevel?.trim(),
        audience: audience?.trim(),
        tone: tone?.trim(),
        slideCount: slideCount.clamp(3, 30),
        theme: theme,
      );
      final saved = await _repo.save(
        bytes: bytes,
        subject: subject.trim(),
        topic: topic.trim(),
        title: t,
        subtitle: subtitle?.trim(),
        classLevel: classLevel?.trim(),
        audience: audience?.trim(),
        tone: tone?.trim(),
        theme: theme,
        slideCount: slideCount,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          generating: false,
          lastSavedAt: saved.createdAt,
          lastSavedTitle: saved.displayTitle,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(generating: false, error: e.toString()));
    }
  }
}
