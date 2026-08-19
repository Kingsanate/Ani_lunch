import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/auth_service.dart';
import '../../main_wrapper.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final rider = await AuthService.signUpRider(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (rider != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainWrapper()),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create Rider\nAccount',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    )),
                const SizedBox(height: 8),
                Text('Join AniLunch as a delivery partner',
                    style: GoogleFonts.inter(
                        color: Colors.white38, fontSize: 14)),
                const SizedBox(height: 36),
                _buildField(
                  label: 'Full Name',
                  ctrl: _nameCtrl,
                  hint: 'John Doe',
                  icon: LucideIcons.user,
                  validator: (v) =>
                      (v != null && v.trim().length > 2) ? null : 'Enter name',
                ),
                const SizedBox(height: 18),
                _buildField(
                  label: 'Phone Number',
                  ctrl: _phoneCtrl,
                  hint: '+91 98765 43210',
                  icon: LucideIcons.phone,
                  keyboard: TextInputType.phone,
                  validator: (v) =>
                      (v != null && v.trim().length >= 8) ? null : 'Enter phone',
                ),
                const SizedBox(height: 18),
                _buildField(
                  label: 'Email Address',
                  ctrl: _emailCtrl,
                  hint: 'rider@email.com',
                  icon: LucideIcons.mail,
                  keyboard: TextInputType.emailAddress,
                  validator: (v) =>
                      (v != null && v.contains('@')) ? null : 'Invalid email',
                ),
                const SizedBox(height: 18),
                _buildField(
                  label: 'Password',
                  ctrl: _passCtrl,
                  hint: '••••••••',
                  icon: LucideIcons.lock,
                  obscure: _obscure,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? LucideIcons.eyeOff : LucideIcons.eye,
                      color: Colors.white38,
                      size: 18,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) => (v != null && v.length >= 6)
                      ? null
                      : 'Min 6 characters',
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.alertCircle,
                            color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                              style: GoogleFonts.inter(
                                  color: Colors.red, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9100),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                                color: Colors.black, strokeWidth: 2.5))
                        : Text('CREATE ACCOUNT',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            )),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                color: Colors.white60,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyboard,
          validator: validator,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 15),
            prefixIcon: Icon(icon, color: Colors.white38, size: 18),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.07)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.07)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: Color(0xFFFF9100), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          ),
        ),
      ],
    );
  }
}

