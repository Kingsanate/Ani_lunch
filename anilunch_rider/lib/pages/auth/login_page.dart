import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/auth_service.dart';
import 'signup_page.dart';
import '../../main_wrapper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res = await AuthService.signInWithEmail(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (res.user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainWrapper()),
        );
      }
    } catch (e) {
      setState(() => _error = 'Invalid email or password.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Logo / Branding
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9100).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFFFF9100).withValues(alpha: 0.3),
                          width: 1.5),
                    ),
                    child: const Icon(LucideIcons.bike,
                        color: Color(0xFFFF9100), size: 44),
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: Text(
                    'ANILUNCH RIDER',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'Delivery Partner Portal',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 50),
                Text('Email', style: _labelStyle()),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _emailCtrl,
                  hint: 'rider@email.com',
                  icon: LucideIcons.mail,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      v != null && v.contains('@') ? null : 'Enter valid email',
                ),
                const SizedBox(height: 20),
                Text('Password', style: _labelStyle()),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _passCtrl,
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
                      : 'Password too short',
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.red.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.alertCircle,
                            color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Text(_error!,
                            style: GoogleFonts.inter(
                                color: Colors.red, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9100),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text('LOG IN',
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            )),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SignupPage())),
                    child: RichText(
                      text: TextSpan(
                        text: "New rider? ",
                        style: GoogleFonts.inter(
                            color: Colors.white38, fontSize: 14),
                        children: [
                          TextSpan(
                            text: 'Create Account',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFFF9100),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _labelStyle() => GoogleFonts.inter(
        color: Colors.white.withValues(alpha: 0.6),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.inter(color: Colors.white24, fontSize: 15),
        prefixIcon: Icon(icon, color: Colors.white38, size: 18),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
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
    );
  }
}

