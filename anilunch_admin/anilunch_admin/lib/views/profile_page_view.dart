import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_view.dart';

class ProfilePageView extends StatefulWidget {
  const ProfilePageView({super.key});

  @override
  State<ProfilePageView> createState() => _ProfilePageViewState();
}

class _ProfilePageViewState extends State<ProfilePageView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController(text: '+91 98765 43210');
  bool _pushNotifications = true;
  bool _emailAlerts = false;

  String get _adminEmail => Supabase.instance.client.auth.currentUser?.email ?? 'admin@anilunch.com';
  String get _displayName => _adminEmail.split('@').first;

  @override
  void initState() {
    super.initState();
    _nameController.text = _displayName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Color(0xFF0F1621), fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F1621)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFF0F0F0)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Avatar
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF0F1621), Color(0xFF8B3500)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(
                        _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'A',
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Color(0xFFEA6E21), shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(_displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F1621))),
            const SizedBox(height: 4),
            Text(_adminEmail, style: const TextStyle(color: Colors.black45, fontSize: 13)),
            const SizedBox(height: 24),

            // Personal Details
            _buildSection('Personal Details', [
              _buildField('Display Name', _nameController),
              const SizedBox(height: 12),
              _buildField('Phone Number', _phoneController),
            ]),
            const SizedBox(height: 16),

            // Preferences
            _buildSection('Preferences', [
              _buildSwitch('Push Notifications', _pushNotifications, (v) => setState(() => _pushNotifications = v)),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              _buildSwitch('Email Alerts', _emailAlerts, (v) => setState(() => _emailAlerts = v)),
            ]),
            const SizedBox(height: 24),

            // Save
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Profile updated!'), backgroundColor: Color(0xFF16A34A)),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA6E21),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 12),

            // Sign Out
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginView()),
                    (route) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red, width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F1621))),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black45)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF7FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEA6E21), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Color(0xFF4A5568))),
          Switch(value: value, onChanged: onChanged, activeThumbColor: const Color(0xFFEA6E21)),
        ],
      ),
    );
  }
}
