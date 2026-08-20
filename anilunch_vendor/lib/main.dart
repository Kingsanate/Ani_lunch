import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/cache/vendor_cache.dart';
import 'core/database/app_database.dart';
import 'core/providers/api_provider.dart';
import 'views/login_view.dart';
import 'views/mobile_vendor_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception('Missing Supabase URL or Anon Key in .env file');
  }

  // publishableKey replaces the deprecated anonKey param
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseAnonKey,
  );

  await AniApi.ensureInitialized();
  await AniApi.exchangeForSession();

  final db = AppDatabase();
  VendorCache.instance.init(db);

  runApp(const AniLunchVendorApp());
}

// Global key so any state can show a SnackBar without needing a context
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class AniLunchVendorApp extends StatelessWidget {
  const AniLunchVendorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final currentSession = Supabase.instance.client.auth.currentSession;

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
      home: currentSession != null ? const MobileVendorShell() : const LoginView(),
    );
  }
}
