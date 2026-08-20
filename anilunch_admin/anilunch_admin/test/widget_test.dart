import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anilunch_admin/main.dart';
import 'package:anilunch_admin/core/providers/api_provider.dart';
import 'package:anilunch_admin/views/login_view.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AniApi.ensureInitialized(baseUrl: 'http://localhost:8080');
  });

  testWidgets('Admin Login smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AniLunchAdminApp(home: LoginView()));
    await tester.pump();

    expect(find.text('Sign In'), findsWidgets);
  });
}
