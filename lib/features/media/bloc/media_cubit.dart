import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_file/open_file.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/storage/lesson_pdf_repository.dart';
import '../../../core/storage/saved_lesson_pdf.dart';
import '../../../core/storage/saved_slide_pptx.dart';
import '../../../core/storage/slide_pptx_repository.dart';
import '../../../shared/widgets/media_capsule_switch.dart';
import 'media_state.dart';

class MediaCubit extends Cubit<MediaState> {
  final LessonPdfRepository _pdfRepo;
  final SlidePptxRepository _slideRepo;
  StreamSubscription<List<SavedLessonPdf>>? _pdfSub;
  StreamSubscription<List<SavedSlidePptx>>? _slideSub;

  MediaCubit(this._pdfRepo, this._slideRepo)
      : super(const MediaState(loading: true)) {
    _pdfSub = _pdfRepo.watch().listen(_onPdfItems, onError: _onError);
    _slideSub = _slideRepo.watch().listen(_onSlideItems, onError: _onError);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await Future.wait([
        _pdfRepo.list(),
        _slideRepo.list(),
      ]);
    } catch (e) {
      _onError(e);
    }
  }

  void selectKind(MediaLibraryKind kind) {
    if (state.kind == kind) return;
    emit(state.copyWith(kind: kind, clearError: true));
  }

  void _onPdfItems(List<SavedLessonPdf> items) {
    if (isClosed) return;
    emit(state.copyWith(pdfItems: items, loading: false, clearError: true));
  }

  void _onSlideItems(List<SavedSlidePptx> items) {
    if (isClosed) return;
    emit(state.copyWith(slideItems: items, loading: false, clearError: true));
  }

  void _onError(Object error) {
    if (isClosed) return;
    emit(state.copyWith(loading: false, error: error.toString()));
  }

  Future<void> refresh() async {
    emit(state.copyWith(loading: true));
    try {
      await Future.wait([
        _pdfRepo.list(forceReload: true),
        _slideRepo.list(forceReload: true),
      ]);
    } catch (e) {
      _onError(e);
    }
  }

  Future<Uint8List> readPdfBytes(SavedLessonPdf item) => _pdfRepo.readBytes(item);

  Future<void> sharePdf(SavedLessonPdf item) async {
    final bytes = await _pdfRepo.readBytes(item);
    await Printing.sharePdf(bytes: bytes, filename: item.exportFilename);
  }

  Future<void> deletePdf(SavedLessonPdf item) => _pdfRepo.delete(item);

  Future<void> shareSlide(SavedSlidePptx item) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(item.path)],
        fileNameOverrides: [item.exportFilename],
      ),
    );
  }

  Future<void> openSlide(SavedSlidePptx item) async {
    final result = await OpenFile.open(item.path);
    if (result.type != ResultType.done) {
      throw Exception(result.message);
    }
  }

  Future<void> deleteSlide(SavedSlidePptx item) => _slideRepo.delete(item);

  @override
  Future<void> close() {
    _pdfSub?.cancel();
    _slideSub?.cancel();
    return super.close();
  }
}
