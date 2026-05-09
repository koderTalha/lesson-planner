import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/lesson_plan_generated.dart';
import '../models/lesson_plan_input.dart';

class AiLessonService {
  AiLessonService({
    this.host = 'generativelanguage.googleapis.com',
  });

  final String host;

  Future<LessonPlanGenerated> generate(
    LessonPlanInput input, {
    required String apiKey,
    String model = 'gemini-2.5-flash',
  }) async {
    final ctx = input.toPromptContext();
    final userJson = jsonEncode(ctx);
    final useProvidedObjectives = !input.useAiForObjectives &&
        input.ownLessonObjectives.trim().isNotEmpty;
    final system = StringBuffer()
      ..writeln(
        'You write detailed school lesson plans in the style of an experienced subject teacher. '
        'Output MUST be one JSON object with exactly these string keys (all required): '
        'lessonObjectives, skillsFocusedOn, resources, methodology, priorKnowledge, '
        'explanation, activity, wrapUp, classWork, homework, aol, afl, differentiation, criticalEvaluation. '
        'Write the ENTIRE plan in FUTURE TENSE only (e.g. will introduce, will explain, students will, the teacher will); '
        'do not use past tense for planned classroom actions. '
        'Use plain text in JSON string values. You MAY use **double asterisks** only for short bold emphasis on key terms or section labels. '
        'No markdown headings (#), no links, no backticks. '
        'Use one line per list item, each line starting with "- " (dash and space) or a numbered line like "1. " (digit, period, space). '
        'Use line breaks between paragraphs. For sub-topics in explanation, use a line "Label name:" (ends with colon) then the paragraph on the same or next lines.',
      )
      ..writeln(
        'Match this overall structure and tone: formal lesson-plan prose; concrete classroom procedures; '
        'cross-curricular links inside explanation where natural; '
        'differentiation by pacing or task complexity (e.g. groups A/B/C) when appropriate.',
      );

    if (useProvidedObjectives) {
      system.writeln(
        'Use providedLessonObjectives from the user JSON inside lessonObjectives and align all sections to them.',
      );
    } else {
      system.writeln(
        'lessonObjectives: Start with one line "At the end of the lesson SWBAT:" then on SEPARATE lines give 2–4 measurable outcomes '
        'numbered exactly "1. ", "2. ", "3. " each followed by the outcome in future tense (students will be able to…).',
      );
    }

    system.writeln(
      'skillsFocusedOn: Organise as short labelled blocks in plain text, for example lines starting with '
        '"Conceptual and Theoretical Skills:", "Analytical Thinking:", "Problem Solving:" '
        'each followed by one or two sentences.',
    );
    system.writeln(
      'resources: Name apparatus, textbook references, ICT, handouts, etc. as short phrases separated by full stops or line breaks.',
    );
    system.writeln(
      'methodology: Name teaching approaches in a compact list (e.g. inquiry-based, brainstorming, interactive).',
    );
    system.writeln(
      'priorKnowledge: Write the questions or prompts you will use to activate prior learning (short lines or bullets), in future tense.',
    );
    system.writeln(
      'explanation: Full teaching sequence in future tense: introduce concepts, define terms, properties or steps, '
        'classification or comparison where relevant, examples from daily life, and a "Cross Curricular Links:" '
        'paragraph naming subjects and links. Use clear sub-headings as plain lines ending with a colon then paragraph text.',
    );
    system.writeln(
      'activity: Hands-on or collaborative work: lab steps, demonstrations, gallery walk, group tasks — '
        'stepwise and practical like a chemistry lesson plan.',
    );
    system.writeln(
      'wrapUp: Board summary outline, recap of main ideas, oral checks, mention of next lesson, '
        'space for student questions.',
    );
    system.writeln(
      'aol: Assessment of Learning — short oral or written questions (one per line or numbered) checking the main outcomes. '
        'END this section with ONE clear concluding sentence in future tense stating how the lesson will be closed '
        '(for example exit questioning, short quiz, recap activity).',
    );
    system.writeln(
      'classWork: What students will do in class for this lesson (C.W) in one compact line or short list.',
    );
    system.writeln(
      'homework: H.W — brief homework task tied to the topic.',
    );
    system.writeln(
      'afl: Assessment FOR learning — include exactly two labelled parts in plain text. '
        'First part **Prior Knowledge:** rewrite or closely reuse the SAME questions (or equivalent wording) that you wrote in priorKnowledge, '
        'so teachers see those questions repeated here. '
        'Second part **Explanation:** short questions that will probe understanding during the explanation phase.',
    );
    system.writeln(
      'differentiation: How tasks or support will vary for different learners (e.g. Group A/B/C or pacing).',
    );
    system.writeln(
      'criticalEvaluation: MUST be an empty string "" (no text); the PDF leaves a blank box for the teacher.',
    );

    final uri = Uri.https(
      host,
      '/v1beta/models/$model:generateContent',
      {'key': apiKey},
    );

    final body = {
      'systemInstruction': {
        'parts': [
          {'text': system.toString()},
        ],
      },
      'contents': [
        {
          'parts': [
            {'text': 'Context JSON:\n$userJson'},
          ],
        },
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
      },
    };

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      if (res.statusCode == 429) {
        throw Exception(_quotaMessage(model));
      }
      if (res.statusCode == 404) {
        throw Exception(
          'Gemini model not found (404). Update GEMINI_MODEL in .env to a valid '
          'model id (for example gemini-2.5-flash or gemini-2.0-flash). '
          'List: https://ai.google.dev/gemini-api/docs/models',
        );
      }
      throw Exception(
        'Gemini request failed (${res.statusCode}): ${res.body.isNotEmpty ? res.body : res.reasonPhrase}',
      );
    }
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List<dynamic>?;
    final first = candidates?.first as Map<String, dynamic>?;
    final content = first?['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    final text = (parts?.first as Map<String, dynamic>?)?['text'] as String?;
    final trimmed = text?.trim() ?? '';
    if (trimmed.isEmpty) {
      throw Exception('Empty Gemini response');
    }
    return LessonPlanGenerated.fromJsonString(trimmed);
  }

  static String _quotaMessage(String model) {
    return 'Gemini quota or rate limit (429). Try again in about one minute. '
        'If this persists, set GEMINI_MODEL in .env to another model '
        '(for example gemini-2.5-flash-lite or gemini-2.0-flash). '
        'You used model "$model". '
        'New API keys can take a few minutes to get quota. '
        'Details: https://ai.google.dev/gemini-api/docs/rate-limits';
  }
}
