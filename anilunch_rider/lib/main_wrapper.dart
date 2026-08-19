import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/pending_approval_page.dart';
import 'pages/dashboard/dashboard_page.dart';
import 'pages/orders/deliveries_page.dart';
import 'pages/orders/new_order_overlay.dart';
import 'pages/orders/active_order_page.dart';
import 'pages/profile/earnings_page.dart';
import 'models/order.dart';
import 'services/auth_service.dart';
import 'services/rider_state_provider.dart';
import 'services/location_tracker.dart';
import 'core/sync/rider_sync_engine.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  // Track which order IDs have already had a popup shown to prevent duplicates
  final Set<String> _shownOrderPopupIds = {};

  // Track if a popup is currently visible (only show one at a time)
  bool _isPopupShowing = false;

  late final RiderStateProvider _riderProvider;

  final List<Widget> _pages = const [
    DashboardPage(),
    DeliveriesPage(),
    EarningsPage(),
  ];

  @override
  void initState() {
    super.initState();

    if (!AuthService.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      });
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initRiderAndSubscribe();
    });
  }

  Future<void> _initRiderAndSubscribe() async {
    final provider = context.read<RiderStateProvider>();
    _riderProvider = provider;
    await provider.fetchInitialData();

    if (!mounted) return;

    final rider = provider.rider;
    if (rider == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }

    // Background reconciliation: pull orders + profile into the local cache
    // and drain the mutation queue every 30s.
    RiderSyncEngine.instance.startPeriodicSync();

    if (!rider.isApproved) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PendingApprovalPage(
            riderName: rider.name,
            riderEmail: rider.email,
          ),
        ),
      );
      return;
    }

    // ── Live GPS: adaptive cadence (30s idle / 10s while carrying an order) ─
    LocationTracker.instance.start(rider.id);
    provider.addListener(_onRiderStateChanged);

    // ── Subscribe to ready_for_pickup orders (broadcast to ALL riders) ──────
    // This fires whenever a vendor presses "Food Ready" on any order.
    // All online riders get the popup — first to tap ACCEPT wins.
    provider.subscribeToReadyForPickupOrders(
      onNewOrder: (OrderModel order) async {
        if (!mounted) return;

        // Deduplicate: don't show the same order twice
        if (_shownOrderPopupIds.contains(order.id)) return;

        // Don't stack popups — only show one at a time
        if (_isPopupShowing) return;

        // Check rider is online
        try {
          final liveData = await Supabase.instance.client
              .from('riders')
              .select('is_online')
              .eq('id', rider.id)
              .single();
          final isOnline = liveData['is_online'] == true;
          if (!isOnline) return;
        } catch (_) {
          final currentRider = provider.rider;
          if (currentRider == null || !currentRider.isOnline) return;
        }

        if (!mounted) return;
        _shownOrderPopupIds.add(order.id);
        _showNewOrderPopup(order, rider.id);
      },
    );

    // ── Also keep legacy subscription for directly assigned orders ──────────
    provider.subscribeToNewOrders(
      onNewOrder: (OrderModel order) async {
        if (!mounted) return;
        if (_shownOrderPopupIds.contains(order.id)) return;
        if (_isPopupShowing) return;

        try {
          final liveData = await Supabase.instance.client
              .from('riders')
              .select('is_online')
              .eq('id', rider.id)
              .single();
          final isOnline = liveData['is_online'] == true;
          if (!isOnline) return;
        } catch (_) {
          final currentRider = provider.rider;
          if (currentRider == null || !currentRider.isOnline) return;
        }

        if (!mounted) return;
        _shownOrderPopupIds.add(order.id);
        _showNewOrderPopup(order, rider.id);
      },
    );
  }

  void _showNewOrderPopup(OrderModel order, String riderId) {
    _isPopupShowing = true;

    NewOrderOverlay.show(
      context: context,
      order: order,
      riderId: riderId,
      onDismissed: () {
        _isPopupShowing = false;
      },
      onAccepted: () async {
        _isPopupShowing = false;
        final provider = context.read<RiderStateProvider>();
        final success = await provider.acceptOrder(order.id);
        if (success && mounted) {
          final activeOrder = provider.activeOrder;
          if (activeOrder != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ActiveOrderPage(order: activeOrder),
              ),
            );
          }
        }
      },
    );
  }

  // ── Adaptive GPS: switch cadence when an active order starts/ends ────────
  void _onRiderStateChanged() {
    LocationTracker.instance.setActive(_riderProvider.activeOrder != null);
  }

  @override
  void dispose() {
    _riderProvider.removeListener(_onRiderStateChanged);
    LocationTracker.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isLoggedIn) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(index: 0, icon: LucideIcons.bike, label: 'REQUESTS'),
              _navItem(
                  index: 1,
                  icon: LucideIcons.clipboardList,
                  label: 'DELIVERIES'),
              _navItem(
                  index: 2, icon: LucideIcons.wallet, label: 'EARNINGS'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isActive = _currentIndex == index;
    final Color color = isActive
        ? const Color(0xFFFF9100)
        : Colors.white.withValues(alpha: 0.35);

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFFFF9100).withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 9,
                fontWeight:
                    isActive ? FontWeight.bold : FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
