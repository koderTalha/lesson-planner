class LessonPlanInput {
  LessonPlanInput({
    required this.institutionName,
    required this.academicSession,
    required this.plannerNo,
    required this.week,
    required this.date,
    required this.teacherName,
    required this.subject,
    required this.className,
    required this.periodDuration,
    required this.unit,
    required this.title,
    required this.topic,
    required this.subTopic,
    required this.useAiForObjectives,
    required this.ownLessonObjectives,
  });

  final String institutionName;
  final String academicSession;
  final String plannerNo;
  final String week;
  final DateTime date;
  final String teacherName;
  final String subject;
  final String className;
  final String periodDuration;
  final String unit;
  final String title;
  final String topic;
  final String subTopic;
  final bool useAiForObjectives;
  final String ownLessonObjectives;

  String get topicsLine {
    if (subTopic.isEmpty) {
      return topic;
    }
    return '$topic. $subTopic';
  }

  Map<String, String> toPromptContext() {
    return {
      'institutionName': institutionName,
      'academicSession': academicSession,
      'plannerNo': plannerNo,
      'week': week,
      'date': date.toIso8601String().split('T').first,
      'teacherName': teacherName,
      'subject': subject,
      'class': className,
      'periodDuration': periodDuration,
      'unit': unit,
      'title': title,
      'topic': topic,
      'subTopic': subTopic,
      'topicsLine': topicsLine,
      if (!useAiForObjectives && ownLessonObjectives.isNotEmpty)
        'providedLessonObjectives': ownLessonObjectives,
    };
  }
}
