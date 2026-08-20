import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/smart_image.dart';
import 'home_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _pinCodeController = TextEditingController();

  String _parseAuthError(dynamic error) {
    final errStr = error.toString().toLowerCase();

    if (error is AuthApiException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login credentials') || error.code == 'invalid_credentials') {
        return 'Incorrect email or password. Please verify and try again.';
      }
      if (msg.contains('email not confirmed')) {
        return 'Your email is not verified yet. Please check your inbox for the activation link.';
      }
      if (msg.contains('user already registered') || msg.contains('already exists')) {
        return 'An account with this email already exists. Please log in.';
      }
      if (msg.contains('password should be at least')) {
        return 'Password must be at least 6 characters long.';
      }
      if (msg.contains('rate limit') || msg.contains('too many requests')) {
        return 'Too many attempts. Please wait a moment before trying again.';
      }
      if (error.message.isNotEmpty && !error.message.contains('Exception') && !error.message.contains('{')) {
        return error.message;
      }
    }

    if (errStr.contains('invalid login credentials') || errStr.contains('invalid_credentials')) {
      return 'Incorrect email or password. Please check your credentials and try again.';
    }
    if (errStr.contains('email not confirmed')) {
      return 'Please verify your email before logging in. Check your inbox for the activation link.';
    }
    if (errStr.contains('user already registered') || errStr.contains('already exists')) {
      return 'This email is already registered. Please sign in instead.';
    }
    if (errStr.contains('socketexception') || errStr.contains('network') || errStr.contains('connection')) {
      return 'Unable to reach the server. Please check your internet connection.';
    }

    return 'Authentication failed. Please check your details and try again.';
  }

  void _showNotification(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.info_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFD32F2F) : const Color(0xFF388E3C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 4),
        elevation: 4,
      ),
    );
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        final res = await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (res.user != null && mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false,
          );
        }
      } else {
        final res = await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          data: {
            'full_name': _nameController.text.trim(),
            'phone_number': _phoneController.text.trim(),
            'address': _addressController.text.trim(),
          },
        );
        if (res.user != null) {
          try {
            await Supabase.instance.client.from('users').insert({
              'id': res.user!.id,
              'user_id': res.user!.id,
              'name': _nameController.text.trim(),
              'email': _emailController.text.trim(),
              'phone_number': _phoneController.text.trim(),
              'address': _addressController.text.trim(),
              'pin_code': _pinCodeController.text.trim(),
            });
          } catch (e) {
            debugPrint('Insert notice on Registration: $e');
          }
          if (mounted) {
            _showNotification('Account created! Please check your email to activate your account.', isError: false);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showNotification(_parseAuthError(e), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetEmailController = TextEditingController(text: _emailController.text.trim());
    final resetFormKey = GlobalKey<FormState>();
    bool isSending = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(dialogCtx).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Form(
                key: resetFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF15A24).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lock_reset_rounded, color: Color(0xFFF15A24), size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reset Password',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C1A0E)),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "We'll send a reset link to your email",
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: resetEmailController,
                      keyboardType: TextInputType.emailAddress,
                      autofocus: true,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Please enter your email address';
                        if (!v.contains('@') || !v.contains('.')) return 'Please enter a valid email address';
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[400]),
                        filled: true,
                        fillColor: const Color(0xFFF9F6F3),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSending
                            ? null
                            : () async {
                                if (!resetFormKey.currentState!.validate()) return;
                                setDialogState(() => isSending = true);
                                final email = resetEmailController.text.trim();
                                try {
                                  await Supabase.instance.client.auth.resetPasswordForEmail(email);
                                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                                  _showNotification('Password reset link sent to $email. Please check your inbox.', isError: false);
                                } catch (err) {
                                  setDialogState(() => isSending = false);
                                  _showNotification(_parseAuthError(err), isError: true);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF15A24),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: isSending
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Send Reset Link', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F3),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AniLunchLogo(size: 48),
                  const SizedBox(height: 12),
                  Text(_isLogin ? 'Welcome Back!' : 'Create Account', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C1A0E))),
                  const SizedBox(height: 8),
                  Text(_isLogin ? 'Sign in to order your fresh lunch' : 'Join the Lunch Time community today', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 32),
                  if (!_isLogin) ...[
                    _buildField('Full Name', _nameController, Icons.person_outline, validator: (v) => v!.isEmpty ? 'Name required' : null),
                    const SizedBox(height: 16),
                    _buildField('Phone Number', _phoneController, Icons.phone_outlined, keyboard: TextInputType.phone, validator: (v) {
                      if (v == null || v.isEmpty) return 'Phone required';
                      if (!RegExp(r'^\d{10,15}$').hasMatch(v)) return 'Enter valid phone (10-15 digits)';
                      return null;
                    }),
                    const SizedBox(height: 16),
                    _buildField('Address', _addressController, Icons.home_outlined, maxLines: 3, validator: (v) => v!.trim().isEmpty ? 'Address required' : null),
                    const SizedBox(height: 16),
                    _buildField('Pin Code', _pinCodeController, Icons.pin_drop_outlined, keyboard: TextInputType.number, validator: (v) {
                      if (v == null || v.isEmpty) return 'Pin Code required';
                      if (!RegExp(r'^\d+$').hasMatch(v)) return 'Digits only';
                      return null;
                    }),
                    const SizedBox(height: 16),
                  ],
                  _buildField('Email Address', _emailController, Icons.email_outlined, keyboard: TextInputType.emailAddress, validator: (v) => !v!.contains('@') ? 'Invalid email' : null),
                  const SizedBox(height: 16),
                  _buildField('Password', _passwordController, Icons.lock_outline, isPassword: true, validator: (v) => v!.length < 6 ? 'Min 6 chars' : null),
                  const SizedBox(height: 12),
                  if (_isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFFF15A24), fontWeight: FontWeight.w600)),
                      ),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleAuth,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF15A24), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(_isLogin ? 'Log In' : 'Sign Up', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [Text(_isLogin ? "Don't have an account? " : "Already have an account? "), GestureDetector(onTap: () => setState(() => _isLogin = !_isLogin), child: Text(_isLogin ? 'Sign Up' : 'Log In', style: const TextStyle(color: Color(0xFFF15A24), fontWeight: FontWeight.bold)))]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctr, IconData icon, {bool isPassword = false, TextInputType keyboard = TextInputType.text, String? Function(String?)? validator, int maxLines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
      const SizedBox(height: 8),
      TextFormField(
        controller: ctr,
        obscureText: isPassword && _obscurePassword,
        keyboardType: keyboard,
        validator: validator,
        maxLines: isPassword ? 1 : maxLines,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 20, color: Colors.grey[400]),
          suffixIcon: isPassword ? IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20, color: Colors.grey[400]), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)) : null,
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    ]);
  }
}
