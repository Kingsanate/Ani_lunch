import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import 'core/providers/api_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/lunch_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'pages/auth_page.dart';
import 'pages/home_page.dart';
import 'models/app_theme.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      debugPrint('Warning: Could not load .env file: $e');
    }

    await AniApi.ensureInitialized();

    runApp(const riverpod.ProviderScope(child: AniLunchApp()));
  } catch (e, stackTrace) {
    debugPrint('Fatal Startup Error: $e\n$stackTrace');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Failed to start app:\n$e\n\n$stackTrace',
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AniLunchApp extends StatelessWidget {
  const AniLunchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()..fetchInitialData()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => LunchProvider()..fetchProducts()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: MaterialApp(
        title: 'Lunch Time',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFF15A24)),
            ),
          );
        }
        if (auth.isLoggedIn) return const HomePage();
        return const AuthPage();
      },
    );
  }
}
