// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:alnisa_store/main.dart';

void main() {
  testWidgets('App starts on the splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // The splash screen should be shown first, before navigating to main.
    expect(find.byType(MyApp), findsOneWidget);

    // Let the splash screen's navigation timer fire so no timers are left
    // pending when the test tears down.
    await tester.pump(const Duration(seconds: 3));
  });
}
