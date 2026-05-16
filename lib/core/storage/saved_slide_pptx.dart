import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

class SavedSlidePptx extends Equatable {
  final String id;
  final String path;
  final String title;
  final String? subtitle;
  final String subject;
  final String topic;
  final String? classLevel;
  final String? audience;
  final String? tone;
  final String theme;
  final int slideCount;
  final DateTime createdAt;
  final int sizeBytes;

  const SavedSlidePptx({
    required this.id,
    required this.path,
    required this.title,
    required this.subtitle,
    required this.subject,
    required this.topic,
    this.classLevel,
    this.audience,
    this.tone,
    this.theme = 'brand',
    required this.slideCount,
    required this.createdAt,
    required this.sizeBytes,
  });

  String get displayTitle => title.isEmpty ? 'Untitled slides' : title;

  String get displaySubtitle {
    final parts = <String>[
      if ((subtitle ?? '').trim().isNotEmpty) subtitle!.trim(),
      if ((classLevel ?? '').trim().isNotEmpty) classLevel!.trim(),
      if (subject.trim().isNotEmpty) subject.trim(),
      if (topic.trim().isNotEmpty) topic.trim(),
      '$slideCount slides',
    ];
    return parts.join(' · ');
  }

  String get readableDate => DateFormat('d MMM yyyy').format(createdAt);

  String get readableSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get exportFilename {
    final date = DateFormat('yyyyMMdd_HHmm').format(createdAt);
    final parts = [
      'slides',
      _slug(subject),
      _slug(topic),
      _slug(title),
      date,
    ].where((p) => p.isNotEmpty).join('_');
    return '$parts.pptx';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'subject': subject,
        'topic': topic,
        'classLevel': classLevel,
        'audience': audience,
        'tone': tone,
        'theme': theme,
        'slideCount': slideCount,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SavedSlidePptx.fromJson(
    Map<String, dynamic> j, {
    required String path,
    required int sizeBytes,
  }) {
    return SavedSlidePptx(
      id: j['id'] as String,
      path: path,
      title: (j['title'] as String?) ?? '',
      subtitle: j['subtitle'] as String?,
      subject: (j['subject'] as String?) ?? '',
      topic: (j['topic'] as String?) ?? '',
      classLevel: j['classLevel'] as String?,
      audience: j['audience'] as String?,
      tone: j['tone'] as String?,
      theme: (j['theme'] as String?) ?? 'brand',
      slideCount: (j['slideCount'] as int?) ?? 0,
      createdAt:
          DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      sizeBytes: sizeBytes,
    );
  }

  static String _slug(String input) {
    final cleaned = input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return cleaned;
  }

  @override
  List<Object?> get props => [
        id,
        path,
        title,
        subtitle,
        subject,
        topic,
        classLevel,
        audience,
        tone,
        theme,
        slideCount,
        createdAt,
        sizeBytes,
      ];
}
