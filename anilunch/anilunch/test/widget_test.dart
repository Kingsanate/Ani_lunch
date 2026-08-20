import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anilunch/pages/auth_page.dart';

void main() {
  testWidgets('AuthPage smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AuthPage(),
      ),
    );
    await tester.pump();

    expect(find.byType(AuthPage), findsOneWidget);
  });
}
