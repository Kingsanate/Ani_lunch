import 'overview_dashboard_view.dart';
import 'menu_management_view.dart';
import 'order_management_view.dart';
import 'daily_deals_management_view.dart';
import 'app_settings_view.dart';
import '../rider_management_view.dart';
import 'login_view.dart';
import '../admin_theme.dart';
import '../core/providers/api_provider.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  void switchTab(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.bg,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          OverviewDashboardView(onSwitchTab: switchTab),
          const MenuManagementView(),
          const OrderManagementView(),
          const DailyDealsManagementView(),
          const AppSettingsView(),
          const RiderManagementView(),
        ],
      ),
      drawer: _buildDrawer(context),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.grid_view_rounded, 'label': 'Home'},
      {'icon': Icons.restaurant_menu_rounded, 'label': 'Menu'},
      {'icon': Icons.receipt_long_rounded, 'label': 'Orders'},
      {'icon': Icons.local_offer_rounded, 'label': 'Deals'},
      {'icon': Icons.settings_rounded, 'label': 'Settings'},
    ];
    final activeIndex = _currentIndex > 4 ? 0 : _currentIndex;

    return Container(
      decoration: const BoxDecoration(
        color: AdminTheme.surface,
        border: Border(top: BorderSide(color: AdminTheme.border, width: 0.8)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 54,
          child: Row(
            children: List.generate(items.length, (i) {
              final isActive = activeIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentIndex = i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? AdminTheme.primary.withValues(alpha: 0.10) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          items[i]['icon'] as IconData,
                          size: 20,
                          color: isActive ? AdminTheme.primary : AdminTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        items[i]['label'] as String,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive ? AdminTheme.primary : AdminTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    String email = 'admin@anilunch.com';
    try {
      email = Supabase.instance.client.auth.currentUser?.email ?? 'admin@anilunch.com';
    } catch (_) {}
    final displayName = email.split('@').first;

    return Drawer(
      backgroundColor: AdminTheme.surface,
      surfaceTintColor: Colors.transparent,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 16,
              left: 16,
              right: 16,
            ),
            color: AdminTheme.dark,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AdminTheme.primary,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AniLunch', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                    Text(displayName, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _drawerItem(0, Icons.grid_view_rounded, 'Dashboard'),
          _drawerItem(1, Icons.restaurant_menu_rounded, 'Menu Manager'),
          _drawerItem(2, Icons.receipt_long_rounded, 'Orders'),
          _drawerItem(3, Icons.local_offer_rounded, 'Deals'),
          _drawerItem(4, Icons.settings_rounded, 'Settings'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Divider(color: AdminTheme.border, height: 1),
          ),
          _drawerItem(5, Icons.delivery_dining_rounded, 'Riders'),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
            child: InkWell(
              onTap: () async {
                await AniApi.exchangeForSession(supabaseToken: '');
                await Supabase.instance.client.auth.signOut();
                if (!mounted) return;
                // ignore: use_build_context_synchronously
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginView()));
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AdminTheme.danger.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AdminTheme.danger.withValues(alpha: 0.15)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.logout_rounded, color: AdminTheme.danger, size: 16),
                    SizedBox(width: 10),
                    Text('Sign Out', style: TextStyle(color: AdminTheme.danger, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(int index, IconData icon, String title) {
    final isActive = _currentIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: isActive ? AdminTheme.primary.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        onTap: () { setState(() => _currentIndex = index); Navigator.pop(context); },
        dense: true,
        visualDensity: const VisualDensity(vertical: -2),
        leading: Icon(icon, color: isActive ? AdminTheme.primary : AdminTheme.textMuted, size: 18),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? AdminTheme.primary : AdminTheme.textBody,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
        trailing: isActive
            ? Container(width: 4, height: 4, decoration: const BoxDecoration(color: AdminTheme.primary, shape: BoxShape.circle))
            : null,
      ),
    );
  }
}
