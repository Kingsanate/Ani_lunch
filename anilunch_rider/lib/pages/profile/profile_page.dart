import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/providers/api_provider.dart';
import '../../models/rider.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../auth/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  RiderModel? _rider;
  bool _loading = true;
  int _totalDeliveries = 0;
  double _totalEarnings = 0;
  int _todayDeliveries = 0;
  double _todayEarnings = 0;

  String get _riderId => AniApi.currentUserId ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rider = await AuthService.loadRiderProfile();
    final orders = await OrderService.fetchMyOrders(_riderId);
    final delivered = orders.where((o) => o.status == 'delivered').toList();
    final now = DateTime.now();
    final todayDelivered = delivered.where((o) => o.createdAt != null && o.createdAt!.year == now.year && o.createdAt!.month == now.month && o.createdAt!.day == now.day).toList();
    if (mounted) {
      setState(() {
        _rider = rider;
        _totalDeliveries = delivered.length;
        _totalEarnings = delivered.fold(0, (s, o) => s + (o.totalAmount ?? 0));
        _todayDeliveries = todayDelivered.length;
        _todayEarnings = todayDelivered.fold(0, (s, o) => s + (o.totalAmount ?? 0));
        _loading = false;
      });
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to sign out?', style: GoogleFonts.inter(color: Colors.white54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white38))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sign Out', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService.signOut();
      if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF9100)))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHeroHeader(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildStatsRow(),
                        const SizedBox(height: 20),
                        _buildInfoSection(),
                        const SizedBox(height: 16),
                        _buildAccountSection(),
                        const SizedBox(height: 24),
                        _buildSignOutButton(),
                        const SizedBox(height: 12),
                        Text('AniLunch Rider v1.0.0', style: GoogleFonts.inter(color: Colors.white24, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeroHeader() {
    final trimmed = _rider?.name.trim() ?? '';
    final initial = trimmed.isNotEmpty ? trimmed[0].toUpperCase() : 'R';
    final memberSince = _rider?.createdAt != null ? DateFormat('MMM yyyy').format(_rider!.createdAt!) : '';
    final isOnline = _rider?.isOnline ?? false;

    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF111111), Color(0xFF080808)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Back button row
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
                        child: const Icon(LucideIcons.arrowLeft, color: Colors.white54, size: 18),
                      ),
                    ),
                    const Spacer(),
                    Text('PROFILE', style: GoogleFonts.inter(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                    const Spacer(),
                    const SizedBox(width: 42),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFF9100), Color(0xFFFF6000)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: const Color(0xFFFF9100).withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 8))],
                    ),
                    child: Center(child: Text(initial, style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 38))),
                  ),
                  Positioned(
                    bottom: 4, right: 4,
                    child: Container(
                      width: 18, height: 18,
                      decoration: BoxDecoration(
                        color: isOnline ? const Color(0xFF00C853) : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF111111), width: 2.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(_rider?.name.isNotEmpty == true ? _rider!.name : 'Rider', style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOnline ? const Color(0xFF00C853).withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isOnline ? const Color(0xFF00C853).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: isOnline ? const Color(0xFF00C853) : Colors.white38)),
                        const SizedBox(width: 6),
                        Text(isOnline ? 'Online' : 'Offline', style: GoogleFonts.inter(color: isOnline ? const Color(0xFF00C853) : Colors.white38, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  if (memberSince.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Text('· Since $memberSince', style: GoogleFonts.inter(color: Colors.white24, fontSize: 12)),
                  ],
                ],
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _statCard('TOTAL RUNS', '$_totalDeliveries', LucideIcons.bike, const Color(0xFFFF9100)),
        const SizedBox(width: 12),
        _statCard('TOTAL EARNED', '₹${_totalEarnings.toStringAsFixed(0)}', LucideIcons.wallet, const Color(0xFF00C853)),
        const SizedBox(width: 12),
        _statCard("TODAY'S RUNS", '$_todayDeliveries', LucideIcons.sun, const Color(0xFF2196F3)),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withValues(alpha: 0.18))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 10),
            Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.inter(color: color.withValues(alpha: 0.8), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return _section(
      title: 'PERSONAL INFO',
      icon: LucideIcons.user,
      children: [
        _infoRow(LucideIcons.userCircle, 'Full Name', _rider?.name.isNotEmpty == true ? _rider!.name : '—'),
        _infoRow(LucideIcons.mail, 'Email', _rider?.email.isNotEmpty == true ? _rider!.email : '—'),
        _infoRow(LucideIcons.phone, 'Phone', _rider?.phone.isNotEmpty == true ? _rider!.phone : '—'),
        _infoRow(LucideIcons.hash, 'Rider ID', _riderId.length > 12 ? '${_riderId.substring(0, 12)}…' : _riderId, isLast: true),
      ],
    );
  }

  Widget _buildAccountSection() {
    return _section(
      title: 'ACCOUNT',
      icon: LucideIcons.settings,
      children: [
        _infoRow(LucideIcons.shieldCheck, 'Account Status', 'Verified', valueColor: const Color(0xFF00C853)),
        _infoRow(LucideIcons.truck, "Today's Earnings", '₹${_todayEarnings.toStringAsFixed(0)}', valueColor: const Color(0xFFFF9100), isLast: true),
      ],
    );
  }

  Widget _section({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon, size: 13, color: Colors.white38),
                const SizedBox(width: 7),
                Text(title, style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              ],
            ),
          ),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {Color? valueColor, bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(width: 32, height: 32, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 14, color: Colors.white38)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(value, style: GoogleFonts.outfit(color: valueColor ?? Colors.white, fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Container(height: 1, margin: const EdgeInsets.only(left: 60), color: Colors.white.withValues(alpha: 0.04)),
      ],
    );
  }

  Widget _buildSignOutButton() {
    return GestureDetector(
      onTap: _signOut,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.logOut, color: Colors.red, size: 18),
            const SizedBox(width: 10),
            Text('Sign Out', style: GoogleFonts.outfit(color: Colors.red, fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

