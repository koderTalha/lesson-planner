class LessonPlainText {
  static String normalize(String input) {
    if (input.isEmpty) return input;
    var t = input.replaceAll('\r\n', '\n');
    t = t.replaceAllMapped(
      RegExp(r'`{1,3}([^`]+)`{1,3}'),
      (m) => m[1]!,
    );
    t = t.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\(([^)]+)\)'),
      (m) => m[1]!,
    );
    t = t.replaceAllMapped(
      RegExp(r'__([^_]+)__'),
      (m) => '**${m[1]}**',
    );
    final boldHold = <String>[];
    t = t.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (m) {
      boldHold.add(m[1]!);
      return '\x00B${boldHold.length - 1}\x00';
    });
    t = t.split('\n').map(_cleanLine).join('\n');
    t = t.replaceAllMapped(
      RegExp(r'\*([a-zA-Z][^*\n]{0,200}?[a-zA-Z0-9.!?])\*'),
      (m) => m[1]!,
    );
    for (var j = 0; j < boldHold.length; j++) {
      t = t.replaceAll('\x00B$j\x00', '**${boldHold[j]}**');
    }
    t = t.replaceAll(RegExp(r'[ \t]+'), ' ');
    t = t.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return t.trim();
  }

  static String _cleanLine(String line) {
    var l = line.trim();
    l = l.replaceFirst(RegExp(r'^#{1,6}\s*'), '');
    return l;
  }
}
