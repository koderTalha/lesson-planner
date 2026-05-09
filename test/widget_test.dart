import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:studio_project/app/app.dart';
import 'package:studio_project/core/theme/theme_cubit.dart';

void main() {
  testWidgets('LessonPlanScreen renders header and hero', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      MyApp(prefs: prefs, initialThemeMode: ThemeCubit.readStoredMode(prefs)),
    );
    await tester.pump();

    expect(find.text('Lesson Studio'), findsOneWidget);
    expect(find.text('Daily lesson plan'), findsOneWidget);
    expect(find.text('Generate Lesson Plan'), findsOneWidget);
  });
}
