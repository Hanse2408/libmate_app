import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libmate_app/app/theme/app_theme.dart';
import 'package:libmate_app/features/student/common/screens/profile_screen.dart';
import 'library_test_support.dart';

void main() {
  testWidgets('profile reflects active theme and switches back with one tap after reopening', (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = AppThemeController.instance;
    controller.setDarkMode(false);
    addTearDown(() => controller.setDarkMode(false));
    final library = studentRepo(await seededFirestore());
    addTearDown(library.dispose);
    Widget app(String screenKey) => ListenableBuilder(
      listenable: controller,
      builder: (context, _) => MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: controller.themeMode,
        home: ProfileScreen(key: ValueKey(screenKey), library: library),
      ),
    );
    final toggle = find.byType(Switch).first;
    await tester.pumpWidget(app('first'));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(toggle).value, false);
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(controller.isDarkMode, true);
    expect(tester.widget<Switch>(toggle).value, true);
    expect(find.text('Dark mode enabled'), findsOneWidget);
    await tester.pumpWidget(app('reopened'));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(toggle).value, true);
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(controller.isDarkMode, false);
    expect(tester.widget<Switch>(toggle).value, false);
    expect(find.text('Dark mode disabled'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}