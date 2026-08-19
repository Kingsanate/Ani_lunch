import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/supabase_config.dart';
import 'core/cache/order_cache.dart';
import 'core/database/app_database.dart';
import 'core/providers/api_provider.dart';
import 'core/sync/rider_sync_engine.dart';
import 'pages/auth/login_page.dart';
import 'main_wrapper.dart';
import 'services/rider_state_provider.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey, // ignore: deprecated_member_use
  );

  await AniApi.ensureInitialized();
  await AniApi.exchangeForSession();

  final db = AppDatabase();
  OrderCache.instance.init(db);
  RiderSyncEngine.instance.init(db);

  runApp(const AniLunchRiderApp());
}

class AniLunchRiderApp extends StatelessWidget {
  const AniLunchRiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

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
        home: session != null ? const MainWrapper() : const LoginPage(),
      ),
    );
  }
}
