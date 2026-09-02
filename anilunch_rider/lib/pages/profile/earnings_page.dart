import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/providers/api_provider.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';

class EarningsPage extends StatefulWidget {
  const EarningsPage({super.key});
  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> with SingleTickerProviderStateMixin {
  List<OrderModel> _delivered = [];
  bool _loading = true;
  late TabController _tabCtrl;
  // 0=Today, 1=Week, 2=Month, 3=All
  int _selectedPeriod = 0;

  String get _riderId => AniApi.currentUserId ?? '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(() { if (!_tabCtrl.indexIsChanging) setState(() => _selectedPeriod = _tabCtrl.index); });
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final orders = await OrderService.fetchMyOrders(_riderId);
    if (mounted) setState(() { _delivered = orders.where((o) => o.status == 'delivered').toList(); _loading = false; });
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  // ── Period filtering ────────────────────────────────────────────────────────
  List<OrderModel> get _filteredOrders {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 0: return _delivered.where((o) => o.createdAt != null && o.createdAt!.year == now.year && o.createdAt!.month == now.month && o.createdAt!.day == now.day).toList();
      case 1: return _delivered.where((o) => o.createdAt != null && now.difference(o.createdAt!).inDays < 7).toList();
      case 2: return _delivered.where((o) => o.createdAt != null && o.createdAt!.year == now.year && o.createdAt!.month == now.month).toList();
      default: return _delivered;
    }
  }

  // ── Aggregate stats ─────────────────────────────────────────────────────────
  double _earnings(List<OrderModel> orders) => orders.fold(0.0, (s, o) => s + (o.totalAmount ?? 0));

  List<OrderModel> _forPeriod(String p) {
    final now = DateTime.now();
    return _delivered.where((o) {
      if (o.createdAt == null) return false;
      switch (p) {
        case 'today': return o.createdAt!.year == now.year && o.createdAt!.month == now.month && o.createdAt!.day == now.day;
        case 'week': return now.difference(o.createdAt!).inDays < 7;
        case 'month': return o.createdAt!.year == now.year && o.createdAt!.month == now.month;
        default: return true;
      }
    }).toList();
  }

  // ── Bar chart data for last 7 days ─────────────────────────────────────────
  List<_DayData> get _last7Days {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final dayOrders = _delivered.where((o) => o.createdAt != null && o.createdAt!.year == day.year && o.createdAt!.month == day.month && o.createdAt!.day == day.day).toList();
      return _DayData(label: DateFormat('EEE').format(day), earnings: _earnings(dayOrders), count: dayOrders.length, isToday: i == 6);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (!_loading) ...[
              _buildHeroCard(),
              _buildPeriodTabs(),
            ],
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF9100)))
                  : RefreshIndicator(
                      color: const Color(0xFFFF9100),
                      backgroundColor: const Color(0xFF1A1A1A),
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        children: [
                          _buildStatsRow(),
                          const SizedBox(height: 16),
                          _buildWeekChart(),
                          const SizedBox(height: 20),
                          _buildTransactionList(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('EARNINGS', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              Text('Finance Dashboard', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: _load,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
              child: const Icon(LucideIcons.refreshCw, color: Colors.white54, size: 17),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    final filtered = _filteredOrders;
    final periodEarnings = _earnings(filtered);
    final periodLabels = ['Today', 'This Week', 'This Month', 'All Time'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF0A2015), Color(0xFF061510), Color(0xFF080E08)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF00C853).withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF00C853).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF00C853).withValues(alpha: 0.2))),
                  child: Text(periodLabels[_selectedPeriod].toUpperCase(), style: GoogleFonts.inter(color: const Color(0xFF00C853), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                ),
                const Spacer(),
                Text('${filtered.length} deliveries', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${periodEarnings.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: -1),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(LucideIcons.trendingUp, color: Color(0xFF00C853), size: 14),
                          const SizedBox(width: 5),
                          Text('Total earnings for ${periodLabels[_selectedPeriod].toLowerCase()}', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          periodEarnings > 0 
                            ? 'Processing withdrawal of ₹${periodEarnings.toStringAsFixed(0)}...'
                            : 'No earnings to withdraw for this period',
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: const Color(0xFF1A1A1A),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF00C853), Color(0xFF00A846)]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: const Color(0xFF00C853).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.landmark, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Withdraw',
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodTabs() {
    final labels = ['Today', 'Week', 'Month', 'All'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
        child: TabBar(
          controller: _tabCtrl,
          indicator: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF00C853), Color(0xFF00A846)]), borderRadius: BorderRadius.circular(12)),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 12),
          dividerColor: Colors.transparent,
          tabs: labels.map((l) => Tab(text: l)).toList(),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final today = _forPeriod('today');
    final week = _forPeriod('week');
    final month = _forPeriod('month');
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          _statCard('TODAY', '₹${_earnings(today).toStringAsFixed(0)}', '${today.length} orders', LucideIcons.sun, const Color(0xFFFF9100)),
          const SizedBox(width: 10),
          _statCard('THIS WEEK', '₹${_earnings(week).toStringAsFixed(0)}', '${week.length} orders', LucideIcons.calendarDays, const Color(0xFF2196F3)),
          const SizedBox(width: 10),
          _statCard('THIS MONTH', '₹${_earnings(month).toStringAsFixed(0)}', '${month.length} orders', LucideIcons.calendarRange, const Color(0xFF9C27B0)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, String sub, IconData icon, Color color) {
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
            Text(sub, style: GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(color: color.withValues(alpha: 0.8), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekChart() {
    final days = _last7Days;
    final maxEarnings = days.map((d) => d.earnings).fold(0.0, (a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('LAST 7 DAYS', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFF00C853).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(7)),
                child: Text('₹${_earnings(_forPeriod("week")).toStringAsFixed(0)}', style: GoogleFonts.outfit(color: const Color(0xFF00C853), fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((d) {
                final ratio = maxEarnings > 0 ? d.earnings / maxEarnings : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (d.earnings > 0)
                          Text('₹${d.earnings.toStringAsFixed(0)}', style: GoogleFonts.inter(color: d.isToday ? const Color(0xFFFF9100) : Colors.white38, fontSize: 8, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          height: ratio * 70 + (d.earnings > 0 ? 6 : 3),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: d.isToday ? [const Color(0xFFFF9100), const Color(0xFFFF6000)] : [const Color(0xFF00C853).withValues(alpha: 0.7), const Color(0xFF00C853).withValues(alpha: 0.3)],
                              begin: Alignment.topCenter, end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(d.label, style: GoogleFonts.inter(color: d.isToday ? const Color(0xFFFF9100) : Colors.white38, fontSize: 10, fontWeight: d.isToday ? FontWeight.w800 : FontWeight.w500)),
                        if (d.count > 0) Text('${d.count}', style: GoogleFonts.inter(color: Colors.white24, fontSize: 9)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    final orders = _filteredOrders;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('TRANSACTIONS', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(6)),
              child: Text('${orders.length}', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (orders.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Column(
              children: [
                Container(width: 70, height: 70, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), shape: BoxShape.circle), child: const Icon(LucideIcons.wallet, color: Colors.white24, size: 28)),
                const SizedBox(height: 14),
                Text('No earnings for this period', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('Complete deliveries to see earnings', style: GoogleFonts.inter(color: Colors.white24, fontSize: 13)),
              ],
            ),
          )
        else
          ...orders.map((o) => _buildTransaction(o)),
      ],
    );
  }

  Widget _buildTransaction(OrderModel order) {
    String dateStr = '';
    if (order.createdAt != null) {
      final diff = DateTime.now().difference(order.createdAt!);
      if (diff.inDays == 0) {
        dateStr = 'Today, ${DateFormat('hh:mm a').format(order.createdAt!.toLocal())}';
      } else if (diff.inDays == 1) {
        dateStr = 'Yesterday, ${DateFormat('hh:mm a').format(order.createdAt!.toLocal())}';
      } else {
        dateStr = DateFormat('dd MMM, hh:mm a').format(order.createdAt!.toLocal());
      }
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: const Color(0xFF00C853).withValues(alpha: 0.09), shape: BoxShape.circle),
            child: const Icon(LucideIcons.checkCircle2, color: Color(0xFF00C853), size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.customerName ?? 'Customer', style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(LucideIcons.shoppingBag, size: 10, color: Colors.white24),
                    const SizedBox(width: 3),
                    Text('${order.items.length} items', style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
                    const SizedBox(width: 8),
                    Icon(LucideIcons.clock, size: 10, color: Colors.white24),
                    const SizedBox(width: 3),
                    Expanded(child: Text(dateStr, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(order.totalAmount != null ? '+₹${order.totalAmount!.toStringAsFixed(0)}' : '', style: GoogleFonts.outfit(color: const Color(0xFF00C853), fontSize: 16, fontWeight: FontWeight.w900)),
              Text(order.shortId, style: GoogleFonts.inter(color: Colors.white24, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayData {
  final String label;
  final double earnings;
  final int count;
  final bool isToday;
  _DayData({required this.label, required this.earnings, required this.count, required this.isToday});
}

