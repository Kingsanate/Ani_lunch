import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/lunch_provider.dart';
import '../providers/order_provider.dart';
import 'auth_page.dart';
import 'edit_information_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _dbProfile;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final data = await Supabase.instance.client
          .from('users')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      if (mounted && data != null) {
        setState(() {
          _dbProfile = data;
        });
      }
    } catch (_) {}
  }

  Widget _buildAvatarWidget(dynamic avatarUrl) {
    if (avatarUrl != null && avatarUrl.toString().trim().isNotEmpty) {
      final url = avatarUrl.toString().trim();
      if (url.startsWith('data:image')) {
        try {
          final base64String = url.split(',').last;
          return Image.memory(base64Decode(base64String), fit: BoxFit.cover, width: 80, height: 80);
        } catch (_) {}
      } else if (url.startsWith('http') || url.startsWith('blob:')) {
        return Image.network(
          url,
          fit: BoxFit.cover,
          width: 80,
          height: 80,
          errorBuilder: (_, __, ___) => Image.asset('assets/images/hero.png', fit: BoxFit.cover, width: 80, height: 80),
        );
      } else if (url.startsWith('assets/')) {
        return Image.asset(url, fit: BoxFit.cover, width: 80, height: 80);
      }
    }
    return Image.asset('assets/images/hero.png', fit: BoxFit.cover, width: 80, height: 80);
  }

  Widget _buildMenuOption(IconData icon, String title, {bool isDestructive = false, VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: isDestructive ? Colors.red.withValues(alpha: 0.1) : const Color(0xFFF15A24).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: isDestructive ? Colors.red : const Color(0xFFF15A24), size: 18),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDestructive ? Colors.red : const Color(0xFF2C1A0E))),
        trailing: isDestructive ? null : Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
        onTap: onTap ?? () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final avatarUrl = _dbProfile?['profile_image_url'] ??
        user?.userMetadata?['profile_image_url'];
    final fullName = _dbProfile?['name'] ??
        user?.userMetadata?['full_name'] ??
        'Member';
    final email = _dbProfile?['email'] ?? user?.email ?? 'No Email';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F3),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))]),
                child: Column(children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade100,
                      border: Border.all(color: const Color(0xFFF15A24).withValues(alpha: 0.2), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: ClipOval(
                      child: _buildAvatarWidget(avatarUrl),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(fullName.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C1A0E))),
                  const SizedBox(height: 2),
                  Text(email.toString(), style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFF8CC63F).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.verified, color: Color(0xFF8CC63F), size: 16), SizedBox(width: 6),
                      Text('Verified Member', style: TextStyle(color: Color(0xFF8CC63F), fontWeight: FontWeight.w600, fontSize: 13)),
                    ])),
                ]),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('ACCOUNT', style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 2))]),
                    child: Column(children: [
                      _buildMenuOption(Icons.person_outline_rounded, 'Edit Information', onTap: () async {
                        final updated = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditInformationPage()));
                        if (mounted) {
                          // Always refetch — small delay ensures DB write has landed
                          await Future.delayed(const Duration(milliseconds: 300));
                          await _fetchProfile();
                        }
                      }),
                      Divider(height: 1, color: Colors.grey[100], indent: 64),
                      _buildMenuOption(Icons.payment_rounded, 'Payment Methods', onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Methods coming soon!'), behavior: SnackBarBehavior.floating));
                      }),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  Text('GENERAL', style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 2))]),
                    child: Column(children: [
                      _buildMenuOption(Icons.notifications_none_rounded, 'Notifications', onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifications coming soon!'), behavior: SnackBarBehavior.floating));
                      }),
                      Divider(height: 1, color: Colors.grey[100], indent: 64),
                      _buildMenuOption(Icons.headset_mic_outlined, 'Help & Support', onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Help & Support coming soon!'), behavior: SnackBarBehavior.floating));
                      }),
                      Divider(height: 1, color: Colors.grey[100], indent: 64),
                      _buildMenuOption(Icons.info_outline_rounded, 'About Lunch Time', onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('About Lunch Time coming soon!'), behavior: SnackBarBehavior.floating));
                      }),

                    ]),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 2))]),
                    child: _buildMenuOption(
                      Icons.logout_rounded,
                      'Log Out',
                      isDestructive: true,
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Log Out'),
                            content: const Text('Are you sure you want to log out from AniLunch?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Log Out'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && context.mounted) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFF15A24))),
                          );

                          try {
                            context.read<LunchProvider>().clearCart();
                            context.read<CartProvider>().clearCart();
                            context.read<OrderProvider>().clearOrders();
                            await context.read<AuthProvider>().signOut();
                          } catch (e) {
                            debugPrint('SignOut exception: $e');
                          }

                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const AuthPage()),
                              (route) => false,
                            );
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
