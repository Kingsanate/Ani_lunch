import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/cache/admin_cache.dart';
import 'core/database/app_database.dart';
import 'core/providers/api_provider.dart';
import 'views/login_view.dart';
import 'views/admin_shell.dart';
import 'services/admin_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception('Missing Supabase URL or Anon Key in .env file');
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  await AniApi.ensureInitialized();
  await AniApi.exchangeForSession();

  final db = AppDatabase();
  AdminCache.instance.init(db);
  
  runApp(const AniLunchAdminApp());
}

// Global key so any state can show a SnackBar without needing a context
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class AniLunchAdminApp extends StatelessWidget {
  final Widget? home;
  const AniLunchAdminApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    bool hasSession = false;
    try {
      hasSession = Supabase.instance.client.auth.currentSession != null;
    } catch (_) {
      hasSession = false;
    }

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