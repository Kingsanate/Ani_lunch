import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/lunch_provider.dart';
import '../providers/order_provider.dart';
import '../models/smart_image.dart';
import 'auth_page.dart';
import 'edit_information_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Widget _buildMenuOption(IconData icon, String title, {bool isDestructive = false, VoidCallback? onTap}) {
    return ListTile(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
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
                  CircleAvatar(radius: 40,
                    backgroundImage: user?.userMetadata?['profile_image_url'] != null
                      ? SmartImage.provider(user!.userMetadata!['profile_image_url'])
                      : const AssetImage('assets/images/hero.png'),
                    backgroundColor: const Color(0xFFF9F6F3)),
                  const SizedBox(height: 12),
                  Text(user?.userMetadata?['full_name'] ?? 'Guest', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C1A0E))),
                  const SizedBox(height: 2),
                  Text(user?.email ?? 'No Email', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
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
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditInformationPage()));
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
