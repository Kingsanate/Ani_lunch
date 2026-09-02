import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/cache/order_cache.dart';
import 'core/database/app_database.dart';
import 'core/providers/api_provider.dart';
import 'core/sync/rider_sync_engine.dart';
import 'pages/auth/login_page.dart';
import 'main_wrapper.dart';
import 'services/rider_state_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint("Notice: .env file not found: $e");
    }

    try {
      await AniApi.ensureInitialized();
    } catch (e) {
      debugPrint("AniApi init notice: $e");
    }

    try {
      final db = AppDatabase();
      OrderCache.instance.init(db);
      RiderSyncEngine.instance.init(db);
    } catch (e) {
      debugPrint("Database init notice: $e");
    }

    runApp(const AniLunchRiderApp());
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
                  const Text('AniLunch Rider', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

class AniLunchRiderApp extends StatelessWidget {
  final Widget? home;
  const AniLunchRiderApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    final hasSession = AniApi.isLoggedIn;

    return ChangeNotifierProvider(
      create: (_) => RiderStateProvider(),
      child: MaterialApp(
        title: 'AniLunch Rider',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0A0A0A),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF9100),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: home ?? (hasSession ? const MainWrapper() : const LoginPage()),
      ),
    );
  }
}
