import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../../features/lesson_plan/models/lesson_plan_input.dart';
import 'saved_lesson_pdf.dart';

class LessonPdfRepository {
  static const _folder = 'lesson_plans';

  final _controller = StreamController<List<SavedLessonPdf>>.broadcast();
  List<SavedLessonPdf> _cache = const [];
  Directory? _dir;
  Future<void>? _initialLoad;

  Stream<List<SavedLessonPdf>> watch() => _controller.stream;

  List<SavedLessonPdf> get current => List.unmodifiable(_cache);

  Future<List<SavedLessonPdf>> list({bool forceReload = false}) {
    if (forceReload) {
      _initialLoad = _reload();
    } else {
      _initialLoad ??= _reload();
    }
    return _initialLoad!.then((_) => _cache);
  }

  Future<Uint8List> readBytes(SavedLessonPdf item) =>
      File(item.path).readAsBytes();

  Future<SavedLessonPdf> save({
    required Uint8List bytes,
    required LessonPlanInput input,
  }) async {
    final dir = await _ensureDir();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final pdfPath = '${dir.path}/$id.pdf';
    final jsonPath = '${dir.path}/$id.json';

    final item = SavedLessonPdf(
      id: id,
      path: pdfPath,
      subject: input.subject,
      className: input.className,
      topic: input.topic,
      subTopic: input.subTopic.isEmpty ? null : input.subTopic,
      createdAt: DateTime.now(),
      lessonDate: input.date,
      sizeBytes: bytes.length,
    );

    await Future.wait([
      File(pdfPath).writeAsBytes(bytes, flush: true),
      File(jsonPath).writeAsString(jsonEncode(item.toJson()), flush: true),
    ]);

    _cache = [item, ..._cache];
    _emit();
    return item;
  }

  Future<void> delete(SavedLessonPdf item) async {
    final pdf = File(item.path);
    final meta = File(_metaPath(item.path));
    await Future.wait([
      if (await pdf.exists()) pdf.delete(),
      if (await meta.exists()) meta.delete(),
    ]);
    _cache = _cache.where((e) => e.id != item.id).toList(growable: false);
    _emit();
  }

  Future<void> _reload() async {
    final dir = await _ensureDir();
    final entries = await dir.list().toList();
    final pdfs = entries
        .whereType<File>()
        .where((f) => f.path.endsWith('.pdf'))
        .toList();
    final loaded = await Future.wait(pdfs.map(_loadItem));
    final items = loaded.whereType<SavedLessonPdf>().toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _cache = items;
    _emit();
  }

  Future<SavedLessonPdf?> _loadItem(File pdf) async {
    try {
      final metaFile = File(_metaPath(pdf.path));
      if (!await metaFile.exists()) return null;
      final stat = await pdf.stat();
      final raw = await metaFile.readAsString();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return SavedLessonPdf.fromJson(
        json,
        path: pdf.path,
        sizeBytes: stat.size,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Directory> _ensureDir() async {
    if (_dir != null) return _dir!;
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/$_folder');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _dir = dir;
    return dir;
  }

  String _metaPath(String pdfPath) =>
      pdfPath.replaceAll(RegExp(r'\.pdf$'), '.json');

  void _emit() {
    if (!_controller.isClosed) _controller.add(_cache);
  }

  Future<void> dispose() => _controller.close();
}
