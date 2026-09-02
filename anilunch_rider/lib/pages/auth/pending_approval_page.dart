import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../services/auth_service.dart';
import '../../main_wrapper.dart';
import 'login_page.dart';

class PendingApprovalPage extends StatefulWidget {
  final String riderName;
  final String riderEmail;

  const PendingApprovalPage({
    super.key,
    required this.riderName,
    required this.riderEmail,
  });

  @override
  State<PendingApprovalPage> createState() => _PendingApprovalPageState();
}

class _PendingApprovalPageState extends State<PendingApprovalPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late Animation<double> _scaleAnim;

  Timer? _checkTimer;
  String _statusLabel = 'UNDER REVIEW';
  bool _isRejected = false;
  String? _rejectionReason;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _scaleAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _subscribeToApproval();
  }

  void _subscribeToApproval() {
    _checkTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final rider = await AuthService.loadRiderProfile();
      if (!mounted || rider == null) return;
      if (rider.isApproved) {
        _checkTimer?.cancel();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainWrapper()),
          (_) => false,
        );
      } else if (rider.approvalStatus == 'rejected') {
        setState(() {
          _isRejected = true;
          _statusLabel = 'REJECTED';
          _rejectionReason = rider.rejectionReason;
        });
      }
    });
  }

  Future<void> _logout() async {
    _checkTimer?.cancel();
    await AuthService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _checkTimer?.cancel();
    super.dispose();
  }

  Color get _accentColor =>
      _isRejected ? const Color(0xFFEF4444) : const Color(0xFFFF9100);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: Stack(
        children: [
          // Subtle background gradient blob
          Positioned(
            top: -100,
            left: -100,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) => Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _accentColor.withValues(alpha: _pulseAnim.value * 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main scrollable content — centered card
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo
                      RichText(
                        text: TextSpan(children: [
                          TextSpan(
                            text: 'ANI',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          TextSpan(
                            text: 'LUNCH',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFFF9100),
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          TextSpan(
                            text: '  RIDER',
                            style: GoogleFonts.outfit(
                              color: Colors.white24,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                            ),
                          ),
                        ]),
                      ),
                      // Logout
                      GestureDetector(
                        onTap: _logout,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.logOut,
                                  color: Colors.white38, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'Sign Out',
                                style: GoogleFonts.inter(
                                  color: Colors.white38,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Centered scrollable card
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ── Animated Icon ─────────────────────────────
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) => Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer glow ring
                                  Transform.scale(
                                    scale: _scaleAnim.value,
                                    child: Container(
                                      width: 140,
                                      height: 140,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _accentColor.withValues(alpha: 
                                              _pulseAnim.value * 0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Middle ring
                                  Container(
                                    width: 110,
                                    height: 110,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _accentColor
                                          .withValues(alpha: 0.06),
                                      border: Border.all(
                                        color: _accentColor
                                            .withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _accentColor.withValues(alpha: 
                                              _pulseAnim.value * 0.25),
                                          blurRadius: 30,
                                          spreadRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _isRejected
                                          ? LucideIcons.xCircle
                                          : LucideIcons.shieldCheck,
                                      color: _accentColor,
                                      size: 44,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // ── Status chip ───────────────────────────────
                            AnimatedBuilder(
                              animation: _pulseAnim,
                              builder: (context, child) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 7),
                                decoration: BoxDecoration(
                                  color: _accentColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                      color: _accentColor.withValues(alpha: 0.25)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _accentColor.withValues(alpha: 
                                            _pulseAnim.value),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _statusLabel,
                                      style: GoogleFonts.inter(
                                        color: _accentColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ── Headline ──────────────────────────────────
                            Text(
                              _isRejected
                                  ? 'Application\nNot Approved'
                                  : 'Application\nUnder Review',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // ── Subtitle ──────────────────────────────────
                            Text(
                              _isRejected
                                  ? 'Unfortunately your application\nwas not approved at this time.'
                                  : 'Your application has been submitted.\nOur admin team will review and\napprove your account shortly.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: Colors.white38,
                                fontSize: 14,
                                height: 1.7,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // ── Rejection reason ──────────────────────────
                            if (_isRejected && _rejectionReason != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444)
                                      .withValues(alpha: 0.07),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: const Color(0xFFEF4444)
                                          .withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Icon(LucideIcons.info,
                                        color: Color(0xFFEF4444), size: 16),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _rejectionReason!,
                                        style: GoogleFonts.inter(
                                          color: Colors.red.shade300,
                                          fontSize: 13,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // ── Info card ─────────────────────────────────
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.07)),
                              ),
                              child: Column(
                                children: [
                                  _infoRow(
                                    icon: LucideIcons.user,
                                    label: 'Full Name',
                                    value: widget.riderName,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    child: Divider(
                                        color: Colors.white.withValues(alpha: 0.06),
                                        height: 1),
                                  ),
                                  _infoRow(
                                    icon: LucideIcons.mail,
                                    label: 'Email Address',
                                    value: widget.riderEmail,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    child: Divider(
                                        color: Colors.white.withValues(alpha: 0.06),
                                        height: 1),
                                  ),
                                  _infoRow(
                                    icon: LucideIcons.clock,
                                    label: 'Account Status',
                                    value: _isRejected
                                        ? 'Rejected by admin'
                                        : 'Pending approval',
                                    valueColor: _accentColor,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // ── Auto-redirect hint (only for pending) ─────
                            if (!_isRejected)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFFF9100)
                                          .withValues(alpha: 0.06),
                                      Colors.transparent,
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: const Color(0xFFFF9100)
                                          .withValues(alpha: 0.15)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(LucideIcons.zap,
                                        color: Color(0xFFFF9100), size: 15),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'You\'ll be automatically redirected once your account is approved — no need to refresh.',
                                        style: GoogleFonts.inter(
                                          color: Colors.white38,
                                          fontSize: 12,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 28),

                            // ── Sign Out button ───────────────────────────
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton.icon(
                                onPressed: _logout,
                                icon: const Icon(LucideIcons.logOut,
                                    size: 16, color: Colors.white38),
                                label: Text(
                                  'Sign Out',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white38,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                      color: Colors.white.withValues(alpha: 0.1)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white38, size: 16),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white24,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  color: valueColor ?? Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

