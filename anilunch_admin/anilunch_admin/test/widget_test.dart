import 'package:flutter_test/flutter_test.dart';
import 'package:anilunch_admin/main.dart';
import 'package:anilunch_admin/views/admin_shell.dart';
import 'package:anilunch_admin/views/login_view.dart';

void main() {
  testWidgets('Admin Shell smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AniLunchAdminApp(home: AdminShell()));
    await tester.pump();

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Menu'), findsWidgets);
  });

  testWidgets('Admin Login smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AniLunchAdminApp(home: LoginView()));
    await tester.pump();

    expect(find.text('Sign In'), findsWidgets);
  });
}
