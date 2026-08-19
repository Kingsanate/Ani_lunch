import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin_theme.dart';
import '../core/providers/api_provider.dart';
import 'admin_shell.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await AniApi.exchangeForSession();
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminShell()));
    } on AuthException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) _showError('Unexpected error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AdminTheme.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Brand mark
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AdminTheme.dark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.restaurant_rounded, color: AdminTheme.primary, size: 24),
              ),
              const SizedBox(height: 14),
              const Text('AniLunch Admin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AdminTheme.dark)),
              const SizedBox(height: 4),
              const Text('Sign in to manage your kitchen', style: TextStyle(fontSize: 12, color: AdminTheme.textMuted)),
              const SizedBox(height: 28),

              // Card
              Container(
                constraints: const BoxConstraints(maxWidth: 360),
                padding: const EdgeInsets.all(20),
                decoration: AdminTheme.cardDecoration(radius: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Email
                    const Text('Email', style: AdminTheme.cardTitle),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(fontSize: 13),
                      decoration: AdminTheme.inputDecoration('admin@example.com'),
                    ),
                    const SizedBox(height: 14),

                    // Password
                    const Text('Password', style: AdminTheme.cardTitle),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      style: const TextStyle(fontSize: 13),
                      decoration: AdminTheme.inputDecoration('••••••••').copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 16, color: AdminTheme.textMuted),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      onSubmitted: (_) => _isLoading ? null : _signIn(),
                    ),
                    const SizedBox(height: 20),

                    // Button
                    SizedBox(
                      height: 42,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Sign In', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
