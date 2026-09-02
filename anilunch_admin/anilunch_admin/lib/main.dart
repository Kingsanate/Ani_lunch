import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/cache/admin_cache.dart';
import 'core/database/app_database.dart';
import 'core/providers/api_provider.dart';
import 'views/login_view.dart';
import 'views/admin_shell.dart';
import 'services/admin_provider.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. Safe .env loading
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      debugPrint('Notice: .env file not found or could not be parsed: $e');
    }

    // 2. Initialize Go API Provider & Realtime
    try {
      await AniApi.ensureInitialized();
    } catch (e) {
      debugPrint('AniApi initialize notice: $e');
    }

    // 3. Initialize Local Drift Cache
    try {
      final db = AppDatabase();
      AdminCache.instance.init(db);
    } catch (e) {
      debugPrint('AdminCache database init notice: $e');
    }

    runApp(const AniLunchAdminApp());
  } catch (e, stackTrace) {
    debugPrint('Fatal Startup Error: $e\n$stackTrace');
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.orange, size: 48),
                  const SizedBox(height: 16),
                  const Text('AniLunch Admin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('$e', textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Global key so any state can show a SnackBar without needing a context
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class AniLunchAdminApp extends StatelessWidget {
  final Widget? home;
  const AniLunchAdminApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    final hasSession = AniApi.isLoggedIn;

    return ChangeNotifierProvider(
      create: (_) => AdminProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AniLunch Admin',
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF8F9FB),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFEA6E21),
            secondary: Color(0xFF0F1621),
            surface: Colors.white,
          ),
          textTheme: const TextTheme(
            displayLarge: TextStyle(
              color: Color(0xFF0F1621),
              fontWeight: FontWeight.bold,
            ),
            bodyLarge: TextStyle(color: Color(0xFF333333)),
            bodyMedium: TextStyle(color: Color(0xFF666666)),
          ),
          useMaterial3: true,
        ),
        // If user is already logged in, show AdminShell, otherwise show LoginView
        home: home ?? (hasSession ? const AdminShell() : const LoginView()),
      ),
    );
  }
}