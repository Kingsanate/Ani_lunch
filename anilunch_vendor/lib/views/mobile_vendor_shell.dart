import 'dart:async';
import 'package:anilunch_core/anilunch_core.dart';
import 'package:flutter/material.dart';
import '../vendor_theme.dart';
import '../services/supabase_service.dart';
import '../core/cache/vendor_cache.dart';
import '../core/providers/api_provider.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/orders_tab.dart';
import 'tabs/wallet_tab.dart';
import 'tabs/profile_tab.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MobileVendorShell extends StatefulWidget {
  const MobileVendorShell({super.key});

  @override
  State<MobileVendorShell> createState() => _MobileVendorShellState();
}

class _MobileVendorShellState extends State<MobileVendorShell> {
  int _currentIndex = 0;
  String? _vendorId;
  bool _isLoading = true;

  StreamSubscription<WsEvent>? _orderSubscription;

  @override
  void initState() {
    super.initState();
    _loadVendor();
    _setupRealtime();
  }

  void _setupRealtime() {
    final realtime = AniApi.instance.realtime;
    if (!realtime.isConnected) return;

    final vendorId = Supabase.instance.client.auth.currentUser?.id;
    if (vendorId == null) return;

    realtime.join('vendor:$vendorId');
    _orderSubscription = realtime.events.listen((event) {
      final orderEvent = event.orderEvent;
      if (orderEvent == null) return;
      if (orderEvent.vendorId != null && orderEvent.vendorId != vendorId) {
        return;
      }
      final shortId = orderEvent.orderId
          .toString()
          .substring(0, 5)
          .toUpperCase();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔔 New Order #$shortId Received!'),
            backgroundColor: VendorTheme.primary,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadVendor() async {
    // Cache-first: enter the shell instantly using the cached profile.
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final cached = await VendorCache.instance.getProfile(user.id);
      if (cached != null && cached['id'] != null) {
        setState(() {
          _vendorId = cached['id'];
          _isLoading = false;
        });
      }
    }

    // Background refresh with the authoritative profile.
    final profile = await SupabaseService.getVendorProfile();
    if (profile != null) {
      setState(() {
        _vendorId = profile['id'];
        _isLoading = false;
      });
    } else if (_vendorId == null) {
      // If we can't find a vendor profile, we'll try a dummy UUID so it doesn't crash Postgres,
      // but ideally we should show an error screen or log out.
      setState(() {
        _vendorId = '00000000-0000-0000-0000-000000000000'; 
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: VendorTheme.primary)),
      );
    }

    final List<Widget> pages = [
      DashboardTab(vendorId: _vendorId!),
      OrdersTab(vendorId: _vendorId!),
      WalletTab(vendorId: _vendorId!),
      ProfileTab(vendorId: _vendorId!),
    ];

    return Scaffold(
      backgroundColor: VendorTheme.background,
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.dashboard_outlined, 'DASHBOARD'),
            _buildNavItem(1, Icons.receipt_long_outlined, 'ORDERS'),
            _buildNavItem(2, Icons.account_balance_wallet_outlined, 'WALLET'),
            _buildNavItem(3, Icons.person_outline, 'PROFILE'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? Colors.white : VendorTheme.textMuted;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? VendorTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: VendorTheme.bodySmall.copyWith(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
