import 'dart:async';
import 'package:anilunch_core/anilunch_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/providers/api_provider.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry-point: call this static method from MainWrapper to show the overlay.
// ─────────────────────────────────────────────────────────────────────────────
class NewOrderOverlay {
  static void show({
    required BuildContext context,
    required OrderModel order,
    required String riderId,
    required VoidCallback onAccepted,
    VoidCallback? onDismissed,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'new_order',
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 420),
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
      pageBuilder: (ctx, animation, secondaryAnimation) => _NewOrderSheet(
        order: order,
        riderId: riderId,
        onAccepted: onAccepted,
        onDismissed: onDismissed,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal sheet widget
// ─────────────────────────────────────────────────────────────────────────────
class _NewOrderSheet extends StatefulWidget {
  final OrderModel order;
  final String riderId;
  final VoidCallback onAccepted;
  final VoidCallback? onDismissed;

  const _NewOrderSheet({
    required this.order,
    required this.riderId,
    required this.onAccepted,
    this.onDismissed,
  });

  @override
  State<_NewOrderSheet> createState() => _NewOrderSheetState();
}

class _NewOrderSheetState extends State<_NewOrderSheet>
    with TickerProviderStateMixin {
  static const int _totalSeconds = 30;
  int _remaining = _totalSeconds;
  Timer? _countdown;
  bool _isAccepting = false;

  // State for when order is taken by another rider
  bool _isTakenByOther = false;

  StreamSubscription<WsEvent>? _orderWatchSub;

  // Pulse animation for the radar ring
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // Shake/dismiss animation for "taken" state
  late AnimationController _takenController;
  late Animation<double> _takenAnim;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _takenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _takenAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _takenController, curve: Curves.elasticIn),
    );

    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _remaining--);
      if (_remaining <= 0) {
        t.cancel();
        _dismiss();
      }
    });

    _subscribeToOrderChanges();
  }

  void _subscribeToOrderChanges() {
    final realtime = AniApi.instance.realtime;
    if (!realtime.isConnected) return;

    realtime.join('order:${widget.order.id}');
    _orderWatchSub = realtime.events.listen((event) {
      if (!mounted) return;
      final orderEvent = event.orderEvent;
      if (orderEvent == null || orderEvent.orderId != widget.order.id) return;
      final riderId = orderEvent.riderId ?? '';
      final status = orderEvent.status.toLowerCase();

      if (riderId.isNotEmpty &&
          riderId != widget.riderId &&
          status == 'accepted') {
        _handleTakenByOtherRider();
      }
    });
  }

  void _handleTakenByOtherRider() {
    if (_isTakenByOther || _isAccepting) return;
    _countdown?.cancel();
    _pulseController.stop();

    setState(() => _isTakenByOther = true);
    _takenController.forward();

    // Auto-dismiss after showing "taken" message for 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _dismiss();
    });
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _pulseController.dispose();
    _takenController.dispose();
    _orderWatchSub?.cancel();
    super.dispose();
  }

  void _dismiss() {
    if (mounted) {
      widget.onDismissed?.call();
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _accept() async {
    if (_isAccepting || _isTakenByOther) return;
    setState(() => _isAccepting = true);
    _countdown?.cancel();

    final success =
        await OrderService.acceptOrder(widget.order.id);

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (success) {
      widget.onAccepted();
    } else {
      widget.onDismissed?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order already taken by another rider 😔',
              style: GoogleFonts.inter()),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _reject() {
    _countdown?.cancel();
    widget.onDismissed?.call();
    _dismiss();
  }

  // ── Derived values ──────────────────────────────────────────────────────────

  bool get _isHighValue => (widget.order.totalAmount ?? 0) >= 500;

  String get _displayName =>
      widget.order.customerName?.isNotEmpty == true
          ? widget.order.customerName!
          : 'Customer';

  String get _pickupText => 'AniLunch Restaurant';

  String get _dropoffText =>
      widget.order.customerAddress?.isNotEmpty == true
          ? widget.order.customerAddress!
          : 'Delivery Address';

  // ───────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Animated dark map-like background ────────────────────────────
          _buildMapBackground(size),

          // ── "Taken by another rider" overlay ────────────────────────────
          if (_isTakenByOther)
            AnimatedBuilder(
              animation: _takenAnim,
              builder: (context, child) => Container(
                color: Colors.black.withValues(alpha: 0.7 * _takenAnim.value),
              ),
            ),

          // ── Main content ─────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const SizedBox(height: 12),

                // Show "Taken" banner or countdown ring
                if (_isTakenByOther)
                  _buildTakenBanner()
                else
                  _buildCountdownRing(),

                const SizedBox(height: 16),
                Expanded(
                  child: _buildCard(),
                ),
                if (!_isTakenByOther) ...[
                  _buildActionButtons(),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── "Taken by another rider" banner ─────────────────────────────────────
  Widget _buildTakenBanner() {
    return AnimatedBuilder(
      animation: _takenAnim,
      builder: (context, child) => Opacity(
        opacity: _takenAnim.value,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.red.shade900.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(18),
            border:
                Border.all(color: Colors.red.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.alertCircle,
                  color: Colors.redAccent, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Taken!',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Another rider accepted this order first.',
                      style: GoogleFonts.inter(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Animated map background ───────────────────────────────────────────────
  Widget _buildMapBackground(Size size) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) => Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1117), Color(0xFF0A0A0A)],
          ),
        ),
        child: CustomPaint(
          painter: _MapGridPainter(_pulseAnim.value),
        ),
      ),
    );
  }

  // ── Top bar with logo + bell ──────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              shape: BoxShape.circle,
              border:
                  Border.all(color: const Color(0xFFFF9100), width: 1.5),
            ),
            child: const Icon(LucideIcons.bike,
                color: Color(0xFFFF9100), size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            'DELIVERY HUB',
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF9100),
              fontSize: 16,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.0,
            ),
          ),
          const Spacer(),
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, child) => Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9100)
                    .withValues(alpha: 0.1 + 0.1 * _pulseAnim.value),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFF9100)
                      .withValues(alpha: 0.3 + 0.3 * _pulseAnim.value),
                ),
              ),
              child: const Icon(LucideIcons.bell,
                  color: Color(0xFFFF9100), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── Circular countdown ring ───────────────────────────────────────────────
  Widget _buildCountdownRing() {
    final progress = _remaining / _totalSeconds;
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 5,
              valueColor:
                  AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          SizedBox(
            width: 90,
            height: 90,
            child: TweenAnimationBuilder<double>(
              tween: Tween(
                  begin: progress + 1 / _totalSeconds, end: progress),
              duration: const Duration(milliseconds: 800),
              builder: (context, val, child) => CircularProgressIndicator(
                value: val,
                strokeWidth: 5,
                strokeCap: StrokeCap.round,
                valueColor: AlwaysStoppedAnimation(
                  progress > 0.4
                      ? const Color(0xFFFF9100)
                      : progress > 0.2
                          ? const Color(0xFFFFCC02)
                          : Colors.redAccent,
                ),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$_remaining',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Main info card ────────────────────────────────────────────────────────
  Widget _buildCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _isTakenByOther
            ? const Color(0xFF1A0A0A)
            : const Color(0xFF141414),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _isTakenByOther
              ? Colors.red.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isTakenByOther
                            ? 'ALREADY ACCEPTED'
                            : 'INCOMING REQUEST',
                        style: GoogleFonts.inter(
                          color: _isTakenByOther
                              ? Colors.red.shade300
                              : Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _displayName,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (widget.order.totalAmount != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isTakenByOther
                          ? Colors.red.shade800
                          : const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '₹${widget.order.totalAmount!.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 18),
            _buildDivider(),
            const SizedBox(height: 18),

            Row(
              children: [
                _buildStatChip(
                  icon: LucideIcons.navigation2,
                  label: 'DISTANCE',
                  value: '~3-5 km',
                ),
                const SizedBox(width: 14),
                _buildStatChip(
                  icon: LucideIcons.clock,
                  label: 'ESTIMATED',
                  value: '~20 mins',
                  isEta: true,
                ),
              ],
            ),

            const SizedBox(height: 18),
            _buildDivider(),
            const SizedBox(height: 18),

            _buildLocationRow(
              dotColor: const Color(0xFFFF9100),
              label: 'PICKUP',
              value: _pickupText,
            ),
            _buildConnectorLine(),
            _buildLocationRow(
              dotColor: const Color(0xFF4CAF50),
              label: 'DROP-OFF',
              value: _dropoffText,
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                if (_isHighValue) ...[
                  _buildTag(
                    icon: LucideIcons.star,
                    label: 'HIGH VALUE',
                    color: const Color(0xFFFF9100),
                  ),
                  const SizedBox(width: 8),
                ],
                _buildTag(
                  icon: LucideIcons.flame,
                  label: 'HOT FOOD',
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 8),
                _buildTag(
                  icon: LucideIcons.shoppingBag,
                  label:
                      '${widget.order.items.length} ITEM${widget.order.items.length == 1 ? '' : 'S'}',
                  color: const Color(0xFF2196F3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => Container(
        height: 1,
        color: Colors.white.withValues(alpha: 0.06),
      );

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    bool isEta = false,
  }) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: Colors.white38),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow({
    required Color dotColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: dotColor.withValues(alpha: 0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white38,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnectorLine() {
    return Padding(
      padding: const EdgeInsets.only(left: 5, top: 4, bottom: 4),
      child: Column(
        children: List.generate(
          4,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 3),
            width: 2,
            height: 4,
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
      ),
    );
  }

  Widget _buildTag({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Action buttons ────────────────────────────────────────────────────────
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // REJECT
          Expanded(
            child: GestureDetector(
              onTap: _isAccepting ? null : _reject,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                      width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.x,
                        color: Colors.redAccent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'REJECT',
                      style: GoogleFonts.outfit(
                        color: Colors.redAccent,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // ACCEPT
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _isAccepting ? null : _accept,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: _isAccepting
                      ? const Color(0xFF4CAF50).withValues(alpha: 0.5)
                      : const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: _isAccepting
                      ? []
                      : [
                          BoxShadow(
                            color: const Color(0xFF4CAF50)
                                .withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: _isAccepting
                    ? const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2.5,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.checkCircle2,
                              color: Colors.black, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'ACCEPT',
                            style: GoogleFonts.outfit(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom painter — animated grid lines that mimic a dark map background
// ─────────────────────────────────────────────────────────────────────────────
class _MapGridPainter extends CustomPainter {
  final double pulse;
  _MapGridPainter(this.pulse);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 0.8;

    // Grid lines
    const step = 38.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Radar rings centred on the upper portion
    final cx = size.width / 2;
    final cy = size.height * 0.28;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 1; i <= 3; i++) {
      final radius = 55.0 * i * (0.9 + 0.1 * pulse);
      ringPaint.color =
          const Color(0xFFFF9100).withValues(alpha: 0.04 * (4 - i) * pulse);
      canvas.drawCircle(Offset(cx, cy), radius, ringPaint);
    }

    // Centre dot
    canvas.drawCircle(
      Offset(cx, cy),
      6 + 2 * pulse,
      Paint()
        ..color = const Color(0xFFFF9100).withValues(alpha: 0.8 * pulse)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      6 + 2 * pulse,
      Paint()
        ..color = const Color(0xFFFF9100).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Diagonal road-like lines
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - 60, cy - 40),
      Offset(cx + 80, cy + 60),
      roadPaint,
    );
    canvas.drawLine(
      Offset(cx + 30, cy - 80),
      Offset(cx - 50, cy + 80),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(_MapGridPainter old) => old.pulse != pulse;
}
