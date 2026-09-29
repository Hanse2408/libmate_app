// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:libmate_app/app/routes/app_router.dart';
import 'package:libmate_app/features/auth/providers/auth_provider.dart';
import 'package:libmate_app/main.dart';

void main() {
  testWidgets('Unauthenticated users are routed to the login screen', (
    WidgetTester tester,
  ) async {
    final appRouter = AppRouter(AuthProvider());
    await tester.pumpWidget(MyApp(router: appRouter.router));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
  });
}

