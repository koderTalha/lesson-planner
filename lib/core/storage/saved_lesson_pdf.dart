import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

class SavedLessonPdf extends Equatable {
  final String id;
  final String path;
  final String subject;
  final String className;
  final String topic;
  final String? subTopic;
  final DateTime createdAt;
  final DateTime? lessonDate;
  final int sizeBytes;

  const SavedLessonPdf({
    required this.id,
    required this.path,
    required this.subject,
    required this.className,
    required this.topic,
    required this.subTopic,
    required this.createdAt,
    this.lessonDate,
    required this.sizeBytes,
  });

  String get displayTitle => topic.isEmpty ? 'Untitled lesson' : topic;

  String get displaySubtitle {
    final parts = <String>[
      if (subject.isNotEmpty) subject,
      if (className.isNotEmpty) className,
    ];
    return parts.isEmpty ? 'Lesson plan' : parts.join(' · ');
  }

  String get readableDate => lessonDate != null
      ? DateFormat('d MMM yyyy').format(lessonDate!)
      : DateFormat('d MMM yyyy').format(createdAt);

  String get readableSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get exportFilename {
    final dateStr = lessonDate != null
        ? DateFormat('yyyyMMdd').format(lessonDate!)
        : DateFormat('yyyyMMdd').format(createdAt);
    final parts = [
      'lesson',
      _slug(subject),
      _slug(topic),
      dateStr,
    ].where((p) => p.isNotEmpty).join('_');
    return '$parts.pdf';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'className': className,
        'topic': topic,
        'subTopic': subTopic,
        'createdAt': createdAt.toIso8601String(),
        if (lessonDate != null) 'lessonDate': lessonDate!.toIso8601String(),
      };

  factory SavedLessonPdf.fromJson(
    Map<String, dynamic> j, {
    required String path,
    required int sizeBytes,
  }) {
    return SavedLessonPdf(
      id: j['id'] as String,
      path: path,
      subject: (j['subject'] as String?) ?? '',
      className: (j['className'] as String?) ?? '',
      topic: (j['topic'] as String?) ?? '',
      subTopic: j['subTopic'] as String?,
      createdAt:
          DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      lessonDate: DateTime.tryParse(j['lessonDate'] as String? ?? ''),
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
  List<Object?> get props =>
      [id, path, subject, className, topic, subTopic, createdAt, lessonDate, sizeBytes];
}
