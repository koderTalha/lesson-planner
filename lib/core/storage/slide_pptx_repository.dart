import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'saved_slide_pptx.dart';

class SlidePptxRepository {
  static const _folder = 'slides';

  final _controller = StreamController<List<SavedSlidePptx>>.broadcast();
  List<SavedSlidePptx> _cache = const [];
  Directory? _dir;
  Future<void>? _initialLoad;

  Stream<List<SavedSlidePptx>> watch() => _controller.stream;

  List<SavedSlidePptx> get current => List.unmodifiable(_cache);

  Future<List<SavedSlidePptx>> list({bool forceReload = false}) {
    if (forceReload) {
      _initialLoad = _reload();
    } else {
      _initialLoad ??= _reload();
    }
    return _initialLoad!.then((_) => _cache);
  }

  Future<Uint8List> readBytes(SavedSlidePptx item) =>
      File(item.path).readAsBytes();

  Future<SavedSlidePptx> save({
    required Uint8List bytes,
    required String title,
    required String? subtitle,
    required String subject,
    required String topic,
    String? classLevel,
    String? audience,
    String? tone,
    String theme = 'brand',
    required int slideCount,
  }) async {
    final dir = await _ensureDir();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final pptxPath = '${dir.path}/$id.pptx';
    final jsonPath = '${dir.path}/$id.json';

    final item = SavedSlidePptx(
      id: id,
      path: pptxPath,
      title: title,
      subtitle: (subtitle ?? '').trim().isEmpty ? null : subtitle!.trim(),
      subject: subject,
      topic: topic,
      classLevel: (classLevel ?? '').trim().isEmpty ? null : classLevel!.trim(),
      audience: (audience ?? '').trim().isEmpty ? null : audience!.trim(),
      tone: (tone ?? '').trim().isEmpty ? null : tone!.trim(),
      theme: theme.trim().isEmpty ? 'brand' : theme.trim(),
      slideCount: slideCount,
      createdAt: DateTime.now(),
      sizeBytes: bytes.length,
    );

    await Future.wait([
      File(pptxPath).writeAsBytes(bytes, flush: true),
      File(jsonPath).writeAsString(jsonEncode(item.toJson()), flush: true),
    ]);

    _cache = [item, ..._cache];
    _emit();
    return item;
  }

  Future<void> delete(SavedSlidePptx item) async {
    final pptx = File(item.path);
    final meta = File(_metaPath(item.path));
    await Future.wait([
      if (await pptx.exists()) pptx.delete(),
      if (await meta.exists()) meta.delete(),
    ]);
    _cache = _cache.where((e) => e.id != item.id).toList(growable: false);
    _emit();
  }

  Future<void> _reload() async {
    final dir = await _ensureDir();
    final entries = await dir.list().toList();
    final files = entries
        .whereType<File>()
        .where((f) => f.path.endsWith('.pptx'))
        .toList();
    final loaded = await Future.wait(files.map(_loadItem));
    final items = loaded.whereType<SavedSlidePptx>().toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _cache = items;
    _emit();
  }

  Future<SavedSlidePptx?> _loadItem(File pptx) async {
    try {
      final metaFile = File(_metaPath(pptx.path));
      if (!await metaFile.exists()) return null;
      final stat = await pptx.stat();
      final raw = await metaFile.readAsString();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return SavedSlidePptx.fromJson(
        json,
        path: pptx.path,
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

  String _metaPath(String pptxPath) =>
      pptxPath.replaceAll(RegExp(r'\.pptx$'), '.json');

  void _emit() {
    if (!_controller.isClosed) _controller.add(_cache);
  }

  Future<void> dispose() => _controller.close();
}

