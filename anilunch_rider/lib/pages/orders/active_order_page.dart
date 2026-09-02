import 'dart:async';
import 'package:anilunch_core/anilunch_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers/api_provider.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import 'map_tracking_widget.dart';

class ActiveOrderPage extends StatefulWidget {
  final OrderModel order;
  const ActiveOrderPage({super.key, required this.order});

  @override
  State<ActiveOrderPage> createState() => _ActiveOrderPageState();
}

class _ActiveOrderPageState extends State<ActiveOrderPage> {
  late OrderModel _order;
  bool _loading = false;
  StreamSubscription<WsEvent>? _wsSub;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _listenToOrder();
  }

  void _listenToOrder() {
    final realtime = AniApi.instance.realtime;
    if (!realtime.isConnected) return;

    realtime.join('order:${_order.id}');
    _wsSub = realtime.events.listen((event) {
      final orderEvent = event.orderEvent;
      if (orderEvent == null || orderEvent.orderId != _order.id) return;

      final status = orderEvent.status.toLowerCase();
      if (status == 'cancelled' && mounted) {
        _showCancelledDialog();
      } else if (mounted) {
        setState(() {
          _order = _order.copyWith(status: status);
        });
      }
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  bool get _isAccepted => _order.status == 'accepted';
  bool get _isPickedUp => _order.status == 'picked_up';
  bool get _isDelivered => _order.status == 'delivered';

  Future<void> _updateStatus(String status) async {
    setState(() => _loading = true);
    await OrderService.updateStatus(_order.id, status);
    setState(() {
      _order = OrderModel(
        id: _order.id,
        status: status,
        riderId: _order.riderId,
        customerName: _order.customerName,
        customerPhone: _order.customerPhone,
        customerAddress: _order.customerAddress,
        items: _order.items,
        totalAmount: _order.totalAmount,
        createdAt: _order.createdAt,
      );
      _loading = false;
    });
    if (status == 'delivered' && mounted) {
      _showDeliveredDialog();
    }
  }

  void _showDeliveredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF0D2E0D),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.checkCircle2,
                  color: Color(0xFF4CAF50), size: 52),
            ),
            const SizedBox(height: 20),
            Text('Order Delivered!',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Great work! Order has been marked as delivered.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // go back to dashboard
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('BACK TO DASHBOARD',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelledDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF3E0D0D),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.xCircle,
                  color: Color(0xFFF44336), size: 52),
            ),
            const SizedBox(height: 20),
            Text('Order Cancelled',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('The user has cancelled this order. Please stop current activity.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // go back to dashboard
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF44336),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('BACK TO DASHBOARD',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color get _statusColor {
    switch (_order.status) {
      case 'accepted':
        return const Color(0xFFFF9100);
      case 'picked_up':
        return const Color(0xFF2196F3);
      case 'delivered':
        return const Color(0xFF4CAF50);
      default:
        return Colors.white38;
    }
  }

  String get _statusLabel {
    switch (_order.status) {
      case 'accepted':
        return 'HEADING TO PICKUP';
      case 'picked_up':
        return 'DELIVERING';
      case 'delivered':
        return 'DELIVERED ✓';
      default:
        return _order.status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    SizedBox(
                      height: 250,
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: MapTrackingWidget(
                          order: _order,
                          isDelivering: _isPickedUp,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildStatusCard(),
                    const SizedBox(height: 20),
                    _buildLocationCard(
                      title: 'PICKUP LOCATION',
                      titleColor: const Color(0xFFFF9100),
                      name: 'Restaurant',
                      address: 'Pick up the order here',
                      isActive: _isAccepted,
                      onTap: () => _showDetailsDialog(
                        type: 'Restaurant',
                        name: 'Restaurant',
                        address: 'Pick up the order here',
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildLocationCard(
                      title: 'DROP-OFF',
                      titleColor: const Color(0xFF4CAF50),
                      name: _order.customerName ?? 'Customer',
                      address: _order.customerAddress ?? '',
                      phone: _order.customerPhone,
                      isActive: _isPickedUp,
                      onTap: () => _showDetailsDialog(
                        type: 'Customer',
                        name: _order.customerName ?? 'Customer',
                        address: _order.customerAddress ?? '',
                        phone: _order.customerPhone,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildOrderSummary(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            _buildActionArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text('ACTIVE ORDER',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
          ),
          Text(_order.shortId,
              style:
                  GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  void _showDetailsDialog({
    required String type,
    required String name,
    required String address,
    String? phone,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$type Details',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _detailRow(LucideIcons.user, name),
            const SizedBox(height: 12),
            _detailRow(LucideIcons.mapPin, address),
            if (phone != null && phone.isNotEmpty) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final Uri launchUri = Uri(scheme: 'tel', path: phone);
                  if (await canLaunchUrl(launchUri)) {
                    await launchUrl(launchUri);
                  }
                },
                child: _detailRow(LucideIcons.phone, phone, isPhone: true),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('CLOSE',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text, {bool isPhone = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: isPhone ? const Color(0xFF4CAF50) : Colors.white,
              fontSize: 15,
              fontWeight: isPhone ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _statusColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.bike, color: _statusColor, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CURRENT STATUS',
                  style: GoogleFonts.inter(
                      color: _statusColor.withValues(alpha: 0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0)),
              const SizedBox(height: 4),
              Text(_statusLabel,
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard({
    required String title,
    required Color titleColor,
    required String name,
    required String address,
    String? phone,
    required bool isActive,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? titleColor.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
        ),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.mapPin, color: titleColor, size: 14),
                  const SizedBox(width: 6),
                  Text(title,
                      style: GoogleFonts.inter(
                          color: titleColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5)),
                ],
              ),
              if (phone != null && phone.isNotEmpty)
                GestureDetector(
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.2)),
                    ),
                    child: const Icon(LucideIcons.phone,
                        color: Color(0xFF4CAF50), size: 15),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(name,
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(address,
              style: GoogleFonts.inter(
                  color: Colors.white54, fontSize: 13)),
        ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    final subtotal = _order.subtotal ?? (_order.totalAmount != null ? _order.totalAmount! - (_order.deliveryFee ?? 30.0) : 200.0);
    final deliveryFee = _order.deliveryFee ?? 30.0;
    final total = _order.totalAmount ?? (subtotal + deliveryFee);

    final displayItems = _order.items.isNotEmpty
        ? _order.items
        : [
            {
              'name': 'Signature Lunch Thali',
              'quantity': 1,
              'price': subtotal.toInt(),
              'image': 'assets/images/bento.png',
            }
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ORDER SUMMARY',
            style: GoogleFonts.inter(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            )),
        const SizedBox(height: 12),
        ...displayItems.map((item) {
          final name = item['name']?.toString() ??
              item['title']?.toString() ??
              item['product_name']?.toString() ??
              'Signature Lunch Thali';
          final qty = (item['quantity'] ?? item['qty'] ?? 1) as num;
          final price = (item['price'] ?? item['unit_price'] ?? 200) as num;
          final imageUrl = item['image']?.toString() ?? item['image_url']?.toString();
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                _buildDishThumbnail(name, imageUrl, size: 44),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9100).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${qty.toInt()}x',
                      style: GoogleFonts.outfit(
                          color: const Color(0xFFFF9100),
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      if (item['customizations'] != null && item['customizations'] is Map) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${item['customizations']['Meat'] ?? ''} ${item['customizations']['Rice'] ?? ''}'.trim(),
                          style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Text('₹${(price * qty).toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Food Subtotal', style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
                  Text('₹${subtotal.toStringAsFixed(0)}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Delivery Fee', style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
                  Text('₹${deliveryFee.toStringAsFixed(0)}', style: GoogleFonts.outfit(color: const Color(0xFF4CAF50), fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Colors.white12),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Amount to Collect', style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  Text('₹${total.toStringAsFixed(0)}', style: GoogleFonts.outfit(color: const Color(0xFF4CAF50), fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionArea() {
    if (_isDelivered) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF9100)))
          : _isAccepted
              ? _bigButton(
                  label: 'MARK AS PICKED UP',
                  icon: LucideIcons.shoppingBag,
                  color: const Color(0xFF2196F3),
                  onTap: () => _updateStatus('picked_up'),
                )
              : _bigButton(
                  label: 'MARK AS DELIVERED',
                  icon: LucideIcons.checkCircle2,
                  color: const Color(0xFF4CAF50),
                  onTap: () => _updateStatus('delivered'),
                ),
    );
  }

  Widget _bigButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black, size: 22),
            const SizedBox(width: 10),
            Text(label,
                style: GoogleFonts.outfit(
                    color: Colors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildDishThumbnail(String name, String? imageUrl, {double size = 44, int? price}) {
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

    if (imageUrl != null && imageUrl.startsWith('assets/')) {
      assetPath = imageUrl;
    }

    Widget imgWidget;
    if (imageUrl != null && imageUrl.startsWith('http')) {
      imgWidget = Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.asset(assetPath, width: size, height: size, fit: BoxFit.cover),
      );
    } else {
      imgWidget = Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF222222),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(LucideIcons.utensils, size: 20, color: Colors.white38),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showDishImagePreview(name, imageUrl, price: price),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imgWidget,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9100),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: const Icon(Icons.zoom_in, color: Colors.black, size: 9),
            ),
          ),
        ],
      ),
    );
  }

  void _showDishImagePreview(String name, String? imageUrl, {int? price}) {
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

    if (imageUrl != null && imageUrl.startsWith('assets/')) {
      assetPath = imageUrl;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(LucideIcons.utensilsCrossed, color: Color(0xFFFF9100), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              name,
                              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(ctx),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 340, maxWidth: 360),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 3.5,
                    child: (imageUrl != null && imageUrl.startsWith('http'))
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => Image.asset(assetPath, fit: BoxFit.contain),
                          )
                        : Image.asset(assetPath, fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (price != null) ...[
                      Text(
                        '₹$price',
                        style: GoogleFonts.outfit(color: const Color(0xFF4CAF50), fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                      const SizedBox(width: 12),
                    ],
                    const Icon(Icons.zoom_in_rounded, color: Colors.white54, size: 16),
                    const SizedBox(width: 4),
                    Text('Pinch to zoom • Tap to preview', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

