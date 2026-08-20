import 'dart:async';
import 'package:anilunch_core/anilunch_core.dart' hide ApiClient;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/cache/admin_cache.dart';
import 'core/providers/api_provider.dart';
import 'services/api_client.dart';

class RiderManagementView extends StatefulWidget {
  const RiderManagementView({super.key});

  @override
  State<RiderManagementView> createState() => _RiderManagementViewState();
}

class _RiderManagementViewState extends State<RiderManagementView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// All riders fetched from the `riders` table
  List<Map<String, dynamic>> _riders = [];

  /// Delivered order count per rider ID
  Map<String, int> _deliveryCounts = {};

  bool _isLoading = true;
  StreamSubscription<WsEvent>? _ridersChannel;

  static const double _earningsPerDelivery = 50.0;

  // ── Animated badge for pending count ──────────────────────────────────
  bool _badgePulse = false;
  Timer? _badgeTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _subscribeToRiders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ridersChannel?.cancel();
    _badgeTimer?.cancel();
    super.dispose();
  }

  // ── Data loading ────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final ridersData = await AdminCache.instance.fetchCacheFirst(
        entityType: 'riders',
        fetcher: () async => ApiClient.fetchRiders(),
      );
      final riders = List<Map<String, dynamic>>.from(ridersData);

      // Fetch delivered order counts grouped by rider_id
      final ordersData = await Supabase.instance.client
          .from('orders')
          .select('rider_id')
          .eq('status', 'delivered');

      final counts = <String, int>{};
      for (final o in ordersData) {
        final rid = o['rider_id']?.toString() ?? '';
        if (rid.isNotEmpty) {
          counts[rid] = (counts[rid] ?? 0) + 1;
        }
      }

      if (mounted) {
        final prevPending = _pendingRiders.length;
        setState(() {
          _riders = riders;
          _deliveryCounts = counts;
          _isLoading = false;
        });

        // Pulse badge animation when a new pending rider arrives
        if (_pendingRiders.length > prevPending) {
          _pulseBadge();
        }
      }
    } catch (e) {
      debugPrint('RiderMgmt load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeToRiders() {
    final realtime = AniApi.instance.realtime;
    if (!realtime.isConnected) return;
    realtime.join('admin');
    _ridersChannel = realtime.events.listen((_) => _loadData());
  }

  void _pulseBadge() {
    _badgeTimer?.cancel();
    setState(() => _badgePulse = true);
    _badgeTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _badgePulse = false);
    });
  }

  // ── Admin Actions ───────────────────────────────────────────────────────

  Future<void> _approveRider(String riderId) async {
    if (await ApiClient.setRiderApproval(riderId, 'approved')) {
      _showSnack('✅ Rider approved! They can now go online.', const Color(0xFF16A34A));
      return;
    }
    try {
      await Supabase.instance.client.from('riders').update({
        'is_approved': true,
        'approval_status': 'approved',
        'rejection_reason': null,
      }).eq('id', riderId);
      _showSnack('✅ Rider approved! They can now go online.', const Color(0xFF16A34A));
    } catch (e) {
      _showSnack('Error approving rider: $e', Colors.red);
    }
  }

  Future<void> _rejectRider(Map<String, dynamic> rider) async {
    final name = rider['name'] ?? 'this rider';
    final riderId = rider['id']?.toString() ?? '';
    final reasonCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Reject Rider?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reject application from "$name"?\nThey will be notified.'),
            const SizedBox(height: 14),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Reason (optional)',
                hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
                filled: true,
                fillColor: const Color(0xFFF8F9FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || riderId.isEmpty) return;

    final reason = reasonCtrl.text.trim();
    if (await ApiClient.setRiderApproval(
      riderId,
      'rejected',
      rejectionReason: reason.isEmpty ? null : reason,
    )) {
      _showSnack('Rider application rejected.', const Color(0xFF64748B));
      return;
    }

    try {
      await Supabase.instance.client.from('riders').update({
        'is_approved': false,
        'approval_status': 'rejected',
        'is_online': false,
        if (reason.isNotEmpty) 'rejection_reason': reason,
      }).eq('id', riderId);
      _showSnack('Rider application rejected.', const Color(0xFF64748B));
    } catch (e) {
      _showSnack('Error rejecting rider: $e', Colors.red);
    }
  }

  Future<void> _removeRider(Map<String, dynamic> rider) async {
    final name = rider['name'] ?? 'this rider';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Rider?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'Are you sure you want to permanently remove "$name"?\nThis cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child:
                const Text('Remove', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await Supabase.instance.client
          .from('riders')
          .delete()
          .eq('id', rider['id'].toString());
      _showSnack('Rider removed.', const Color(0xFF64748B));
    } catch (e) {
      _showSnack('Error: $e', Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Filtered lists ──────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _pendingRiders =>
      _riders.where((r) => (r['approval_status'] ?? 'pending') == 'pending').toList();

  List<Map<String, dynamic>> get _activeRiders =>
      _riders.where((r) => r['is_approved'] == true).toList();


  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pendingCount = _pendingRiders.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Column(
        children: [
          _buildHeader(pendingCount),
          _buildTabBar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFEA6E21)))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRiderList(_pendingRiders, tab: _RiderTab.pending),
                      _buildRiderList(_activeRiders, tab: _RiderTab.active),
                      _buildRiderList(_riders, tab: _RiderTab.all),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int pendingCount) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 16,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ANILUNCH ADMIN',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEA6E21),
                          letterSpacing: 1.5)),
                  SizedBox(height: 4),
                  Text('Rider Management',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A202C))),
                ],
              ),
              Row(
                children: [
                  // Refresh button
                  IconButton(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh_rounded,
                        color: Color(0xFFEA6E21), size: 22),
                    tooltip: 'Refresh',
                  ),
                  if (pendingCount > 0)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _badgePulse
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF59E0B)),
                        boxShadow: _badgePulse
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                )
                              ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.pending_actions,
                              size: 14,
                              color: _badgePulse
                                  ? Colors.white
                                  : const Color(0xFFF59E0B)),
                          const SizedBox(width: 6),
                          Text(
                            '$pendingCount Pending',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _badgePulse
                                    ? Colors.white
                                    : const Color(0xFFF59E0B)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Summary stats row
          Row(
            children: [
              _headerStat('Total', _riders.length.toString(),
                  const Color(0xFF6366F1)),
              const SizedBox(width: 10),
              _headerStat('Approved', _activeRiders.length.toString(),
                  const Color(0xFF16A34A)),
              const SizedBox(width: 10),
              _headerStat('Pending', _pendingRiders.length.toString(),
                  const Color(0xFFF59E0B)),
              const SizedBox(width: 10),
              _headerStat(
                'Online',
                _riders
                    .where((r) =>
                        r['is_online'] == true && r['is_approved'] == true)
                    .length
                    .toString(),
                const Color(0xFF0EA5E9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFFEA6E21),
        unselectedLabelColor: Colors.black38,
        indicatorColor: const Color(0xFFEA6E21),
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Pending'),
                if (_pendingRiders.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _badgePulse
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: _badgePulse
                          ? [
                              BoxShadow(
                                color: const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.5),
                                blurRadius: 8,
                              )
                            ]
                          : [],
                    ),
                    child: Text(
                      '${_pendingRiders.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ]
              ],
            ),
          ),
          const Tab(text: 'Active'),
          const Tab(text: 'All Riders'),
        ],
      ),
    );
  }

  Widget _buildRiderList(
    List<Map<String, dynamic>> riders, {
    required _RiderTab tab,
  }) {
    if (riders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.delivery_dining,
                  color: Color(0xFFEA6E21), size: 34),
            ),
            const SizedBox(height: 14),
            Text(
              tab == _RiderTab.pending
                  ? 'No pending riders'
                  : tab == _RiderTab.active
                      ? 'No active riders'
                      : 'No riders yet',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748)),
            ),
            const SizedBox(height: 6),
            Text(
              tab == _RiderTab.pending
                  ? 'New rider registrations will appear here.'
                  : tab == _RiderTab.active
                      ? 'Approved riders will be listed here.'
                      : 'Riders will appear here once they register.',
              style: const TextStyle(color: Colors.black38, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFFEA6E21),
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        itemCount: riders.length,
        itemBuilder: (ctx, i) =>
            _buildRiderCard(riders[i], tab: tab),
      ),
    );
  }

  Widget _buildRiderCard(Map<String, dynamic> rider,
      {required _RiderTab tab}) {
    final name = (rider['name'] ?? 'Unknown').toString();
    final phone = (rider['phone'] ?? '—').toString();
    final email = (rider['email'] ?? '—').toString();
    final isOnline = rider['is_online'] == true;
    final isApproved = rider['is_approved'] == true;
    final approvalStatus = (rider['approval_status'] ?? 'pending').toString();
    final riderId = rider['id']?.toString() ?? '';
    final deliveries = _deliveryCounts[riderId] ?? 0;
    final earnings = deliveries * _earningsPerDelivery;

    final createdAt = rider['created_at'] != null
        ? DateTime.tryParse(rider['created_at'].toString())
        : null;
    String joinDate = 'Unknown';
    if (createdAt != null) {
      final local = createdAt.toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun',
                      'Jul','Aug','Sep','Oct','Nov','Dec'];
      joinDate = '${local.day} ${months[local.month - 1]} ${local.year}';
    }

    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : '?';

    // Status colour & label
    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    if (approvalStatus == 'rejected') {
      statusColor = Colors.red;
      statusLabel = 'REJECTED';
      statusIcon = Icons.cancel_outlined;
    } else if (!isApproved) {
      statusColor = const Color(0xFFF59E0B);
      statusLabel = 'PENDING';
      statusIcon = Icons.pending_actions;
    } else if (isOnline) {
      statusColor = const Color(0xFF16A34A);
      statusLabel = 'ONLINE';
      statusIcon = Icons.circle;
    } else {
      statusColor = const Color(0xFF94A3B8);
      statusLabel = 'OFFLINE';
      statusIcon = Icons.circle_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: approvalStatus == 'pending'
            ? Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Top row
            Row(
              children: [
                // Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFEA6E21).withValues(alpha: 0.8),
                        const Color(0xFFEA6E21),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(initials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(name,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B))),
                          ),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color:
                                      statusColor.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon,
                                    size: 8, color: statusColor),
                                const SizedBox(width: 4),
                                Text(statusLabel,
                                    style: TextStyle(
                                        color: statusColor,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(phone,
                          style: const TextStyle(
                              color: Color(0xFF64748B), fontSize: 13)),
                      Text(email,
                          style: const TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Stats row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statItem(Icons.local_shipping_outlined, '$deliveries',
                      'Deliveries', const Color(0xFF6366F1)),
                  _vertDivider(),
                  _statItem(Icons.currency_rupee,
                      earnings.toStringAsFixed(0), 'Earned',
                      const Color(0xFF16A34A)),
                  _vertDivider(),
                  _statItem(Icons.calendar_today_outlined, joinDate, 'Joined',
                      const Color(0xFF0EA5E9)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Action buttons — context-aware
            _buildActionRow(rider, tab: tab, riderId: riderId,
                isApproved: isApproved, approvalStatus: approvalStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow(
    Map<String, dynamic> rider, {
    required _RiderTab tab,
    required String riderId,
    required bool isApproved,
    required String approvalStatus,
  }) {
    final isPending = approvalStatus == 'pending';
    final isRejected = approvalStatus == 'rejected';

    return Row(
      children: [
        // Approve button — shown for pending riders everywhere
        if (isPending || isRejected) ...[
          Expanded(
            child: _actionBtn(
              label: 'Approve',
              icon: Icons.check_circle_outline,
              color: const Color(0xFF16A34A),
              onTap: () => _approveRider(riderId),
            ),
          ),
          const SizedBox(width: 10),
        ],

        // Reject button — shown for pending riders
        if (isPending) ...[
          Expanded(
            child: _actionBtn(
              label: 'Reject',
              icon: Icons.cancel_outlined,
              color: const Color(0xFFDC2626),
              isOutline: true,
              onTap: () => _rejectRider(rider),
            ),
          ),
          const SizedBox(width: 10),
        ],

        // Remove button — always shown
        Expanded(
          child: _actionBtn(
            label: 'Remove',
            icon: Icons.delete_outline,
            color: Colors.red.shade300,
            isOutline: true,
            onTap: () => _removeRider(rider),
          ),
        ),
      ],
    );
  }

  Widget _statItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 9,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _vertDivider() {
    return Container(width: 1, height: 36, color: const Color(0xFFE2E8F0));
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isOutline = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isOutline ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isOutline ? color.withValues(alpha: 0.5) : color),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: isOutline ? color : Colors.white),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: isOutline ? color : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

enum _RiderTab { pending, active, all }
