import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/smart_image.dart';

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

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await Supabase.instance.client.auth.signInWithPassword(email: _emailController.text.trim(), password: _passwordController.text);
      } else {
        final res = await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          data: {
            'full_name': _nameController.text.trim(),
            'phone_number': _phoneController.text.trim(),
            'address': _addressController.text.trim(),
          });
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
            debugPrint('Insert Fail on Registration: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Profile creation failed: $e'),
                backgroundColor: Colors.orange,
              ));
            }
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please check your email for confirmation!'), backgroundColor: Color(0xFFF15A24)));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
      }
    } finally { if (mounted) setState(() => _isLoading = false); }
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
                  if (_isLogin) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () {}, child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFFF15A24))))),
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
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_isLogin ? "Don't have an account? " : "Already have an account? "), GestureDetector(onTap: () => setState(() => _isLogin = !_isLogin), child: Text(_isLogin ? 'Sign Up' : 'Log In', style: const TextStyle(color: Color(0xFFF15A24), fontWeight: FontWeight.bold)))]),
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
