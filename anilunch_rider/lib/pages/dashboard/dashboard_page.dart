import 'dart:async';
import 'package:anilunch_core/anilunch_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../models/rider.dart';
import '../../models/order.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/rider_service.dart';
import '../orders/active_order_page.dart';
import '../auth/login_page.dart';
import '../profile/profile_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  RiderModel? _rider;
  List<OrderModel> _availableOrders = [];
  OrderModel? _activeOrder;
  bool _loading = true;
  bool _togglingStatus = false;
  StreamSubscription<WsEvent>? _channel;
  Timer? _locationTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _init();
  }

  Future<void> _init() async {
    final rider = await AuthService.loadRiderProfile();
    if (rider == null) {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
      return;
    }
    setState(() { _rider = rider; _loading = false; });
    await _refresh();
    _subscribeRealtime();
  }

  final Set<String> _seenOrderAlerts = {};
  Timer? _pollTimer;

  Future<void> _refresh() async {
    if (_rider == null) return;
    final orders = await OrderService.fetchAvailableOrders(_rider!.id);
    final active = await OrderService.fetchActiveOrder(_rider!.id);
    if (mounted) {
      setState(() { _availableOrders = orders; _activeOrder = active; });
      if (_rider!.isOnline && orders.isNotEmpty) {
        for (final o in orders) {
          if (!_seenOrderAlerts.contains(o.id)) {
            _seenOrderAlerts.add(o.id);
            _showNewDeliveryDialog(o);
            break;
          }
        }
      }
    }
  }

  void _showNewDeliveryDialog(OrderModel order) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => Dialog(
        backgroundColor: const Color(0xFF161616),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFFFF9100), width: 1.5)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9100).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.bike, color: Color(0xFFFF9100), size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                '🛵 NEW DELIVERY AVAILABLE!',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Order #${order.shortId} • ₹${order.totalAmount?.toStringAsFixed(0) ?? "0"}',
                style: GoogleFonts.robotoMono(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFFFF9100)),
              ),
              const SizedBox(height: 12),
              Text(
                order.customerAddress ?? 'Customer delivery ready for pickup',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Decline', style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        _acceptOrder(order);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9100),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Accept Delivery', style: TextStyle(fontWeight: FontWeight.w900)),
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

  void _subscribeRealtime() {
    if (_rider == null) return;
    _channel = OrderService.subscribeToAvailableOrders(
      riderId: _rider!.id,
      onUpdate: (orders) async {
        final active = await OrderService.fetchActiveOrder(_rider!.id);
        if (mounted) setState(() { _availableOrders = orders; _activeOrder = active; });
      },
    );
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  Future<void> _toggleOnline() async {
    if (_rider == null) return;

    if (!_rider!.isApproved) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Your account is pending admin approval. Please wait.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFFF9100),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    setState(() => _togglingStatus = true);
    final newStatus = !_rider!.isOnline;
    await RiderService.setOnlineStatus(_rider!.id, newStatus);
    setState(() { _rider = _rider!.copyWith(isOnline: newStatus); _togglingStatus = false; });
    if (newStatus) await _refresh();
  }

  Future<void> _acceptOrder(OrderModel order) async {
    if (_rider == null) return;
    final success = await OrderService.acceptOrder(order.id);
    if (!success) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order already taken by another rider'), backgroundColor: Colors.red));
      await _refresh();
      return;
    }
    await _refresh();
    if (_activeOrder != null && mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => ActiveOrderPage(order: _activeOrder!)));
  }

  @override
  void dispose() {
    _channel?.cancel();
    _locationTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF080808),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFF9100))),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFFF9100),
          backgroundColor: const Color(0xFF1A1A1A),
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(child: _buildStatusCard()),
              if (_activeOrder != null) SliverToBoxAdapter(child: _buildActiveOrderCard()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: _rider!.isOnline ? _buildOrderList() : _buildOfflineState(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final trimmed = _rider?.name.trim() ?? '';
    final initial = trimmed.isNotEmpty ? trimmed[0].toUpperCase() : 'R';
    return SliverAppBar(
      backgroundColor: const Color(0xFF080808),
      floating: true, snap: true, elevation: 0,
      titleSpacing: 16, toolbarHeight: 62,
      title: Row(
        children: [
          RichText(
            text: TextSpan(children: [
              TextSpan(text: 'ANI', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              TextSpan(text: 'LUNCH', style: GoogleFonts.outfit(color: const Color(0xFFFF9100), fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              TextSpan(text: '  RIDER', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
            ]),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
            child: Container(
              width: 38, height: 38,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFFFF9100), Color(0xFFFF6D00)]),
                shape: BoxShape.circle,
              ),
              child: Center(child: Text(initial, style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final isOnline = _rider?.isOnline ?? false;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isOnline ? [const Color(0xFF0A2015), const Color(0xFF071410)] : [const Color(0xFF1A1008), const Color(0xFF110C04)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isOnline ? const Color(0xFF00C853).withValues(alpha: 0.2) : const Color(0xFFFF9100).withValues(alpha: 0.15), width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (context, child) => Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOnline ? const Color(0xFF00C853).withValues(alpha: _pulseAnim.value) : Colors.white24,
                            boxShadow: isOnline ? [BoxShadow(color: const Color(0xFF00C853).withValues(alpha: _pulseAnim.value * 0.7), blurRadius: 6, spreadRadius: 2)] : [],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(isOnline ? 'ONLINE' : 'OFFLINE', style: GoogleFonts.inter(color: isOnline ? const Color(0xFF00C853) : Colors.white38, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isOnline ? '${_availableOrders.length} ${_availableOrders.length == 1 ? 'order' : 'orders'} waiting' : 'Go online to earn',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700),
                  ),
                  if (isOnline && _availableOrders.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Accept orders to start earning', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: _togglingStatus ? null : _toggleOnline,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                decoration: BoxDecoration(
                  gradient: isOnline
                      ? const LinearGradient(colors: [Color(0xFF1B3A20), Color(0xFF2A5C30)])
                      : const LinearGradient(colors: [Color(0xFFFF9100), Color(0xFFFF6200)]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isOnline ? const Color(0xFF00C853).withValues(alpha: 0.35) : Colors.transparent),
                  boxShadow: [BoxShadow(color: (isOnline ? const Color(0xFF00C853) : const Color(0xFFFF9100)).withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 5))],
                ),
                child: _togglingStatus
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(isOnline ? 'GO OFF' : 'GO ON', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOrderCard() {
    final o = _activeOrder!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ActiveOrderPage(order: o))),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFF9100), Color(0xFFFF6000)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: const Color(0xFFFF9100).withValues(alpha: 0.3), blurRadius: 22, offset: const Offset(0, 8))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(LucideIcons.bike, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ACTIVE DELIVERY', style: GoogleFonts.inter(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                    const SizedBox(height: 3),
                    Text(o.customerName ?? 'Customer', style: GoogleFonts.outfit(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                      child: Text(o.status.toUpperCase(), style: GoogleFonts.inter(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, color: Colors.white70, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.07))),
              child: const Icon(LucideIcons.wifiOff, color: Colors.white24, size: 34),
            ),
            const SizedBox(height: 22),
            Text("You're Offline", style: GoogleFonts.outfit(color: Colors.white54, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Toggle online to receive\norders and start earning', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white24, fontSize: 14, height: 1.6)),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: _togglingStatus ? null : _toggleOnline,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFF9100), Color(0xFFFF6000)]),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: const Color(0xFFFF9100).withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 6))],
                ),
                child: Text('GO ONLINE', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList() {
    if (_availableOrders.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.07))),
                child: const Icon(LucideIcons.packageOpen, color: Colors.white24, size: 34),
              ),
              const SizedBox(height: 22),
              Text("No Orders Yet", style: GoogleFonts.outfit(color: Colors.white54, fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text("We'll notify you when new\norders are available", textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white24, fontSize: 14, height: 1.6)),
            ],
          ),
        ),
      );
    }
    
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildOrderCard(_availableOrders[index]),
        childCount: _availableOrders.length,
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${order.id.length >= 6 ? order.id.substring(0, 6) : order.id}',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9100).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'READY FOR PICKUP',
                  style: GoogleFonts.inter(color: const Color(0xFFFF9100), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFF9100).withValues(alpha: 0.2)),
                ),
                child: const Center(child: Icon(LucideIcons.bike, color: Color(0xFFFF9100), size: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customerName ?? 'Customer',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${order.totalAmount?.toStringAsFixed(0) ?? '0'}',
                      style: GoogleFonts.inter(color: const Color(0xFF00C853), fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _acceptOrder(order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9100),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(LucideIcons.check, size: 16, color: Colors.black),
                label: Text(
                  'ACCEPT',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          if (order.items.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: order.items.map((item) {
                  final name = item['name']?.toString() ?? item['product_name']?.toString() ?? 'Item';
                  final qty = item['quantity']?.toString() ?? '1';
                  final imageUrl = item['image']?.toString() ?? item['image_url']?.toString();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        _buildDishThumbnail(name, imageUrl, size: 28),
                        const SizedBox(width: 8),
                        Text('${qty}x', style: GoogleFonts.outfit(color: const Color(0xFFFF9100), fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(name, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDishThumbnail(String name, String? imageUrl, {double size = 32}) {
    final lower = name.toLowerCase();
    String assetPath = 'assets/images/bento.png';
    if (lower.contains('mizo')) {
      assetPath = 'assets/images/pork.png';
    } else if (lower.contains('naga')) {
      assetPath = 'assets/images/chicken.png';
    } else if (lower.contains('khasi')) {
      assetPath = 'assets/images/beef.png';
    } else if (lower.contains('indian') || lower.contains('thali')) {
      assetPath = 'assets/images/bento.png';
    } else if (lower.contains('salad') || lower.contains('veg')) {
      assetPath = 'assets/images/salad.png';
    } else if (lower.contains('chicken') || lower.contains('biryani')) {
      assetPath = 'assets/images/chicken.png';
    } else if (lower.contains('pork') || lower.contains('mutton')) {
      assetPath = 'assets/images/pork.png';
    } else if (lower.contains('beef') || lower.contains('meat')) {
      assetPath = 'assets/images/beef.png';
    }

    if (imageUrl != null && imageUrl.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Image.asset(assetPath, width: size, height: size, fit: BoxFit.cover),
        ),
      );
    }

    if (imageUrl != null && imageUrl.startsWith('assets/')) {
      assetPath = imageUrl;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF222222),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(LucideIcons.utensils, size: 16, color: Colors.white38),
        ),
      ),
    );
  }
}
