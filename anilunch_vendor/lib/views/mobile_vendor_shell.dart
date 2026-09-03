import 'dart:async';
import 'package:anilunch_core/anilunch_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../vendor_theme.dart';
import '../services/supabase_service.dart';
import '../core/cache/vendor_cache.dart';
import '../core/providers/api_provider.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/wallet_tab.dart';
import 'tabs/reviews_tab.dart';
import 'tabs/profile_tab.dart';

class MobileVendorShell extends StatefulWidget {
  const MobileVendorShell({super.key});

  @override
  State<MobileVendorShell> createState() => _MobileVendorShellState();
}

class _MobileVendorShellState extends State<MobileVendorShell> {
  int _currentIndex = 0;
  String? _vendorId;
  bool _isLoading = true;
  final Set<String> _seenOrderIds = {};

  StreamSubscription<WsEvent>? _orderSubscription;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadVendor();
  }

  void _setupRealtime() {
    final realtime = AniApi.instance.realtime;
    final vendorId = _vendorId ?? AniApi.currentUserId ?? 'vendor-1';

    realtime.connect().then((_) {
      realtime.join('vendor:$vendorId');
      realtime.join('vendor:orders');
      realtime.join('admin.orders');

      _orderSubscription?.cancel();
      _orderSubscription = realtime.events.listen((event) {
        final orderEvent = event.orderEvent;
        if (orderEvent == null) return;
        final status = orderEvent.status.toLowerCase();
        if (status == 'pending' || status == 'confirmed' || status == 'preparing') {
          _showNewOrderAlert(orderEvent.orderId, orderEvent.totalAmount != null ? orderEvent.totalAmount!.paise / 100 : null);
        }
      });
    }).catchError((_) {});

    // Polling safety net to check for newly arriving orders
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _checkForNewOrders());
    _checkForNewOrders();
  }

  Future<void> _checkForNewOrders() async {
    try {
      final orders = await AniApi.instance.api.vendors.orders();
      final pendingOrders = orders.where((o) => o.status.toLowerCase() == 'pending' || o.status.toLowerCase() == 'confirmed').toList();
      for (final o in pendingOrders) {
        if (!_seenOrderIds.contains(o.id)) {
          _seenOrderIds.add(o.id);
          _showNewOrderAlert(o.id, o.totalAmount.paise / 100);
          break;
        }
      }
    } catch (_) {}
  }

  void _showNewOrderAlert(String orderId, double? amount) {
    if (!mounted) return;
    if (_seenOrderIds.contains('alerted_$orderId')) return;
    _seenOrderIds.add('alerted_$orderId');

    final shortId = orderId.length > 8 ? orderId.substring(0, 8).toUpperCase() : orderId;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Color(0xFF16A34A),
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '🚨 NEW ORDER RECEIVED!',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Order #$shortId',
                      style: GoogleFonts.robotoMono(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    if (amount != null && amount > 0) ...[
                      const SizedBox(width: 12),
                      Text(
                        '₹${amount.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'A new customer lunch order just arrived. Accept now to start cooking!',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Dismiss', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(dialogCtx);
                        await SupabaseService.updateOrderStatus(orderId, 'preparing');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('👨‍🍳 Order #$shortId accepted! Kitchen started preparing.', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                              backgroundColor: const Color(0xFF2563EB),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Accept & Cook',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadVendor() async {
    try {
      final userId = AniApi.currentUserId;
      if (userId != null) {
        try {
          final cached = await VendorCache.instance.getProfile(userId).timeout(
            const Duration(seconds: 1),
            onTimeout: () => null,
          );
          if (cached != null && cached['id'] != null) {
            if (mounted) {
              setState(() {
                _vendorId = cached['id'];
                _isLoading = false;
              });
            }
            _setupRealtime();
          }
        } catch (_) {}
      }

      final profile = await SupabaseService.getVendorProfile().timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
      if (profile != null && mounted) {
        setState(() {
          _vendorId = profile['id'];
          _isLoading = false;
        });
        _setupRealtime();
      } else if (mounted) {
        setState(() {
          _vendorId = _vendorId ?? userId ?? 'vendor-1';
          _isLoading = false;
        });
        _setupRealtime();
      }
    } catch (e) {
      debugPrint('Load vendor notice: $e');
      if (mounted) {
        setState(() {
          _vendorId = _vendorId ?? AniApi.currentUserId ?? 'vendor-1';
          _isLoading = false;
        });
        _setupRealtime();
      }
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
      WalletTab(vendorId: _vendorId!),
      ReviewsTab(vendorId: _vendorId!),
      ProfileTab(vendorId: _vendorId!),
    ];

    return Scaffold(
      backgroundColor: VendorTheme.background,
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: VendorTheme.floatingShadow,
            border: Border.all(color: VendorTheme.border.withValues(alpha: 0.8), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.soup_kitchen_rounded, 'Live Kitchen'),
              _buildNavItem(1, Icons.account_balance_wallet_rounded, 'Earnings'),
              _buildNavItem(2, Icons.star_rate_rounded, 'Reviews'),
              _buildNavItem(3, Icons.settings_rounded, 'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? VendorTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : VendorTheme.textMuted,
              size: 20,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
