import 'package:flutter/material.dart';
import '../../vendor_theme.dart';
import '../../services/supabase_service.dart';
import '../login_view.dart';

class ProfileTab extends StatefulWidget {
  final String vendorId;
  const ProfileTab({super.key, required this.vendorId});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _isLoading = true;
  Map<String, dynamic>? _vendorProfile;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final profile = await SupabaseService.getVendorProfile();
    if (mounted) {
      setState(() {
        _vendorProfile = profile;
        _isOpen = profile?['is_open'] ?? false;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleOpenStatus(bool value) async {
    setState(() => _isOpen = value);
    await SupabaseService.toggleStoreStatus(widget.vendorId, value);
  }

  Future<void> _logout() async {
    await SupabaseService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: VendorTheme.background,
        body: Center(child: CircularProgressIndicator(color: VendorTheme.primary)),
      );
    }

    final name = _vendorProfile?['name'] ?? 'Vendor Name';
    final address = _vendorProfile?['address'] ?? 'No Address Provided';
    final phone = _vendorProfile?['phone'] ?? 'No Phone Provided';

    return Scaffold(
      backgroundColor: VendorTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Store Profile',
          style: VendorTheme.headingSmall,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Avatar & Info
            Center(
              child: CircleAvatar(
                radius: 48,
                backgroundColor: VendorTheme.primary.withValues(alpha: 0.1),
                child: const Icon(Icons.storefront, size: 48, color: VendorTheme.primary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: VendorTheme.headingLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              address,
              style: VendorTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              phone,
              style: VendorTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),

            // Store Settings
            Container(
              decoration: VendorTheme.cardDecoration(),
              child: Column(
                children: [
                  SwitchListTile(
                    activeThumbColor: VendorTheme.primary,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    title: Text('Store Open', style: VendorTheme.headingSmall),
                    subtitle: Text(
                      _isOpen ? 'Accepting new orders' : 'Store is currently closed',
                      style: VendorTheme.bodySmall,
                    ),
                    value: _isOpen,
                    onChanged: _toggleOpenStatus,
                  ),
                  const Divider(height: 1, indent: 20, endIndent: 20, color: VendorTheme.greyBg),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: const Icon(Icons.history, color: VendorTheme.textDark),
                    title: Text('Payout History', style: VendorTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right, color: VendorTheme.textMuted),
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 20, endIndent: 20, color: VendorTheme.greyBg),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: const Icon(Icons.settings_outlined, color: VendorTheme.textDark),
                    title: Text('Settings', style: VendorTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right, color: VendorTheme.textMuted),
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: VendorTheme.danger,
                  foregroundColor: VendorTheme.dangerText,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Sign Out', style: VendorTheme.headingSmall.copyWith(color: VendorTheme.dangerText)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
