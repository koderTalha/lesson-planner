import 'dart:convert';

import '../utils/lesson_plain_text.dart';

class LessonPlanGenerated {
  LessonPlanGenerated({
    required this.lessonObjectives,
    required this.skillsFocusedOn,
    required this.resources,
    required this.methodology,
    required this.priorKnowledge,
    required this.explanation,
    required this.activity,
    required this.wrapUp,
    required this.classWork,
    required this.homework,
    required this.aol,
    required this.afl,
    required this.differentiation,
    required this.criticalEvaluation,
  });

  final String lessonObjectives;
  final String skillsFocusedOn;
  final String resources;
  final String methodology;
  final String priorKnowledge;
  final String explanation;
  final String activity;
  final String wrapUp;
  final String classWork;
  final String homework;
  final String aol;
  final String afl;
  final String differentiation;
  final String criticalEvaluation;

  static LessonPlanGenerated fromJsonString(String raw) {
    String t = raw.trim();
    if (t.startsWith('```')) {
      t = t.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
      t = t.replaceFirst(RegExp(r'\s*```\s*$'), '');
    }
    final m = jsonDecode(t) as Map<String, dynamic>;
    String s(String k) =>
        LessonPlainText.normalize((m[k] ?? '').toString().trim());
    final skills = s('skillsFocusedOn');
    final skillsAlt = s('skillsFocused');
    return LessonPlanGenerated(
      lessonObjectives: s('lessonObjectives'),
      skillsFocusedOn: skills.isNotEmpty ? skills : skillsAlt,
      resources: s('resources'),
      methodology: s('methodology'),
      priorKnowledge: s('priorKnowledge'),
      explanation: s('explanation'),
      activity: s('activity'),
      wrapUp: s('wrapUp'),
      classWork: s('classWork'),
      homework: s('homework'),
      aol: s('aol'),
      afl: s('afl'),
      differentiation: s('differentiation'),
      criticalEvaluation: '',
    );
  }
}
