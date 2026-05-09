import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';

import '../../../core/storage/lesson_pdf_repository.dart';
import '../../../core/storage/saved_lesson_pdf.dart';
import 'media_state.dart';

class MediaCubit extends Cubit<MediaState> {
  final LessonPdfRepository _repo;
  StreamSubscription<List<SavedLessonPdf>>? _sub;

  MediaCubit(this._repo) : super(const MediaState(loading: true)) {
    _sub = _repo.watch().listen(_onItems, onError: _onError);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final items = await _repo.list();
      _onItems(items);
    } catch (e) {
      _onError(e);
    }
  }

  void _onItems(List<SavedLessonPdf> items) {
    if (isClosed) return;
    emit(state.copyWith(items: items, loading: false, clearError: true));
  }

  void _onError(Object error) {
    if (isClosed) return;
    emit(state.copyWith(loading: false, error: error.toString()));
  }

  Future<void> refresh() async {
    if (state.loading) return;
    emit(state.copyWith(loading: true));
    try {
      await _repo.list(forceReload: true);
    } catch (e) {
      _onError(e);
    }
  }

  Future<Uint8List> readBytes(SavedLessonPdf item) => _repo.readBytes(item);

  Future<void> share(SavedLessonPdf item) async {
    final bytes = await _repo.readBytes(item);
    await Printing.sharePdf(bytes: bytes, filename: item.exportFilename);
  }

  Future<void> delete(SavedLessonPdf item) => _repo.delete(item);

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
