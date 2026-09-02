import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/cache/vendor_cache.dart';
import 'core/database/app_database.dart';
import 'core/providers/api_provider.dart';
import 'views/login_view.dart';
import 'views/mobile_vendor_shell.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      debugPrint('Notice: .env file not found or could not be parsed: $e');
    }

    // 1. Initialize Go API Provider & Realtime
    try {
      await AniApi.ensureInitialized();
    } catch (e) {
      debugPrint('AniApi initialize notice: $e');
    }

    // 2. Initialize Local Drift Cache
    try {
      final db = AppDatabase();
      VendorCache.instance.init(db);
    } catch (e) {
      debugPrint('VendorCache database init notice: $e');
    }

    runApp(const AniLunchVendorApp());
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
                  const Text('AniLunch Vendor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

class AniLunchVendorApp extends StatelessWidget {
  final Widget? home;
  const AniLunchVendorApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    final hasSession = AniApi.isLoggedIn;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AniLunch Vendor',
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
      home: home ?? (hasSession ? const MobileVendorShell() : const LoginView()),
    );
  }
}
