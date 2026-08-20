import 'dart:async';
import 'package:anilunch_core/anilunch_core.dart' hide ApiClient;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin_theme.dart';
import '../core/cache/admin_cache.dart';
import '../core/providers/api_provider.dart';
import '../services/api_client.dart';

class OrderManagementView extends StatefulWidget {
  const OrderManagementView({super.key});

  @override
  State<OrderManagementView> createState() => _OrderManagementViewState();
}

class _OrderManagementViewState extends State<OrderManagementView> {
  List<Map<String, dynamic>> _orders = [];
  Map<String, Map<String, dynamic>> _itemsCache = {};
  Map<String, String> _usersCache = {};
  String _searchQuery = '';
  // Status filter: null = All
  String? _statusFilter;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  StreamSubscription<WsEvent>? _ordersChannel;

  // Extended status labels for the full food delivery lifecycle
  static const List<Map<String, String?>> _filterTabs = [
    {'label': 'All', 'value': null},
    {'label': 'Pending', 'value': 'pending'},
    {'label': 'Preparing', 'value': 'preparing'},
    {'label': 'Ready', 'value': 'ready_for_pickup'},
    {'label': 'On the Way', 'value': 'accepted'},
    {'label': 'Done', 'value': 'delivered'},
  ];

  @override
  void initState() {
    super.initState();
    _subscribeToOrders();
    _prefetchUsers();
  }

  Future<void> _prefetchUsers() async {
    final data = await ApiClient.fetchUsers();
    if (mounted) {
      setState(() {
        _usersCache = {
          for (final u in data) u['id'].toString(): (u['name'] ?? u['email'] ?? 'Customer').toString()
        };
      });
    }
  }

  List<Map<String, dynamic>> _sortOrders(List<Map<String, dynamic>> list) {
    list.sort((a, b) {
      final tA = DateTime.tryParse(a['order_time']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final tB = DateTime.tryParse(b['order_time']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return tB.compareTo(tA);
    });
    return list;
  }

  void _subscribeToOrders() async {
    try {
      final data = await AdminCache.instance.fetchCacheFirst(
        entityType: 'orders',
        fetcher: () async => ApiClient.fetchOrders(),
      );
      if (mounted) setState(() { _orders = _sortOrders(List<Map<String, dynamic>>.from(data)); _isLoading = false; });
      _prefetchItems();
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }

    final realtime = AniApi.instance.realtime;
    if (!realtime.isConnected) return;
    realtime.join('admin');
    _ordersChannel = realtime.events.listen((event) async {
      if (event.orderEvent == null || !mounted) return;
      final data = await ApiClient.fetchOrders();
      if (!mounted) return;
      final wasNew = data.length > _orders.length;
      setState(() => _orders = _sortOrders(List<Map<String, dynamic>>.from(data)));
      if (wasNew) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🔔 New order received!'), backgroundColor: AdminTheme.info),
        );
      }
    });
  }

  Future<void> _prefetchItems() async {
    final data = await ApiClient.fetchItems();
    if (mounted) setState(() { _itemsCache = { for (final item in data) item['id'].toString(): Map<String, dynamic>.from(item) }; });
  }

  List<Map<String, dynamic>> _enrichItems(dynamic rawItems) {
    if (rawItems == null || rawItems is! List) return [];
    return rawItems.map((it) {
      final map = Map<String, dynamic>.from(it);
      final id = (map['id'] ?? map['item_id'] ?? '').toString();
      final cached = _itemsCache[id];
      if (cached != null) {
        map['thumbnail_url'] ??= cached['thumbnail_url'];
        map['item_title'] ??= cached['item_title'];
        map['name'] ??= cached['item_title'];
        map['item_price'] ??= cached['item_price'];
      }
      return map;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _ordersChannel?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount   = _orders.where((o) => (o['status'] ?? '').toString().toLowerCase() == 'pending').length;
    final deliveredCount = _orders.where((o) => (o['status'] ?? '').toString().toLowerCase() == 'delivered').length;
    final acceptedCount  = _orders.where((o) => (o['status'] ?? '').toString().toLowerCase() == 'accepted').length;
    final preparingCount = _orders.where((o) => (o['status'] ?? '').toString().toLowerCase() == 'preparing').length;
    final readyCount     = _orders.where((o) => (o['status'] ?? '').toString().toLowerCase() == 'ready_for_pickup').length;

    return Scaffold(
      backgroundColor: AdminTheme.bg,
      body: Column(
        children: [
          _buildHeader(context, pendingCount, acceptedCount, deliveredCount, preparingCount, readyCount),
          // Status filter tabs
          _buildFilterTabs(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AdminTheme.primary, strokeWidth: 2))
                : _orders.isEmpty
                    ? _buildEmpty()
                    : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: AdminTheme.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Row(
          children: _filterTabs.map((tab) {
            final value = tab['value'];
            final label = tab['label']!;
            final isSelected = _statusFilter == value;
            final color = value == null
                ? AdminTheme.dark
                : _statusColorForFilter(value);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _statusFilter = value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? color : color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? color : color.withValues(alpha: 0.2),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _statusColorForFilter(String status) {
    switch (status.toLowerCase()) {
      case 'pending':         return AdminTheme.warning;
      case 'preparing':       return const Color(0xFF2563EB);
      case 'ready_for_pickup': return const Color(0xFF16A34A);
      case 'accepted':        return const Color(0xFF7C3AED);
      case 'picked_up':       return const Color(0xFF0891B2);
      case 'delivered':       return AdminTheme.success;
      case 'cancelled':       return AdminTheme.danger;
      default:                return AdminTheme.textMuted;
    }
  }

  Widget _buildHeader(BuildContext context, int pending, int accepted, int delivered, int preparing, int ready) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, bottom: 10, left: 4, right: 16),
      decoration: const BoxDecoration(color: AdminTheme.surface, border: Border(bottom: BorderSide(color: AdminTheme.border, width: 0.8))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Builder(builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: AdminTheme.dark, size: 20),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                constraints: const BoxConstraints(),
              )),
              const Expanded(child: Text('Orders', style: AdminTheme.pageTitle)),
              if (pending > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AdminTheme.warning.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20)),
                  child: Row(children: [
                    const Icon(Icons.circle, color: AdminTheme.warning, size: 6),
                    const SizedBox(width: 4),
                    Text('$pending pending', style: const TextStyle(color: AdminTheme.warning, fontSize: 10, fontWeight: FontWeight.w700)),
                  ]),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Stat pills row — full lifecycle
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 12),
            child: Row(
              children: [
                AdminTheme.statPill('Total', _orders.length.toString(), AdminTheme.info),
                const SizedBox(width: 8),
                AdminTheme.statPill('Pending', pending.toString(), AdminTheme.warning),
                const SizedBox(width: 8),
                AdminTheme.statPill('Preparing', preparing.toString(), const Color(0xFF2563EB)),
                const SizedBox(width: 8),
                AdminTheme.statPill('Ready', ready.toString(), const Color(0xFF16A34A)),
                const SizedBox(width: 8),
                AdminTheme.statPill('On the Way', accepted.toString(), const Color(0xFF7C3AED)),
                const SizedBox(width: 8),
                AdminTheme.statPill('Delivered', delivered.toString(), AdminTheme.success),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              decoration: BoxDecoration(color: AdminTheme.bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AdminTheme.border, width: 0.8)),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Search by ID, customer or status…',
                  hintStyle: const TextStyle(color: AdminTheme.textMuted, fontSize: 12),
                  prefixIcon: const Icon(Icons.search_rounded, color: AdminTheme.textMuted, size: 16),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.close_rounded, size: 14, color: AdminTheme.textMuted), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); })
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(color: AdminTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.receipt_long_rounded, color: AdminTheme.primary, size: 28),
        ),
        const SizedBox(height: 12),
        const Text('No Orders Yet', style: AdminTheme.sectionTitle),
        const SizedBox(height: 4),
        const Text('Orders will appear here in real-time.', style: AdminTheme.body),
      ]),
    );
  }

  Widget _buildList() {
    final filtered = _orders.where((o) {
      // Apply status filter
      if (_statusFilter != null) {
        final s = (o['status'] ?? '').toString().toLowerCase();
        if (s != _statusFilter) return false;
      }
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final id = o['id'].toString().toLowerCase();
      final name = (_usersCache[o['user_id']] ?? o['user_name'] ?? o['ordered_by'] ?? '').toString().toLowerCase();
      final status = (o['status'] ?? '').toString().toLowerCase();
      return id.contains(q) || name.contains(q) || status.contains(q);
    }).toList();

    final today = DateTime.now();
    final todayOrders = <Map<String, dynamic>>[];
    final pastOrders = <Map<String, dynamic>>[];
    for (var o in filtered) {
      final t = DateTime.tryParse((o['order_time'] ?? o['created_at'] ?? '').toString())?.toLocal();
      if (t != null && t.year == today.year && t.month == today.month && t.day == today.day) {
        todayOrders.add(o);
      } else {
        pastOrders.add(o);
      }
    }

    final items = <dynamic>[];
    if (todayOrders.isNotEmpty) { items.add("Today's Orders"); items.addAll(todayOrders); }
    if (pastOrders.isNotEmpty) { items.add("Past Orders"); items.addAll(pastOrders); }
    if (items.isEmpty) items.add("_empty_");

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        if (item == "_empty_") return const Center(child: Padding(padding: EdgeInsets.only(top: 50), child: Text('No orders match your search.', style: AdminTheme.body)));
        if (item is String) {
          return Padding(
            padding: EdgeInsets.only(bottom: 8, top: i == 0 ? 0 : 14),
            child: Text(item, style: AdminTheme.sectionTitle),
          );
        }
        final order = item as Map<String, dynamic>;
        return _buildOrderCard(order, _enrichItems(order['items']));
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, List<Map<String, dynamic>> enrichedItems) {
    final status = (order['status'] ?? 'pending').toString().toLowerCase();
    final color = AdminTheme.statusColor(status);
    final bg = AdminTheme.statusBg(status);

    String name = _usersCache[order['user_id']] ?? order['ordered_by'] ?? order['user_name'] ?? 'Customer';
    if (name.contains('@')) name = name.split('@').first;

    final subtotal = (num.tryParse(order['subtotal']?.toString() ?? '0') ?? 0).toDouble();
    final deliveryFee = (num.tryParse(order['delivery_fee']?.toString() ?? '0') ?? 0).toDouble();
    final totalAmount = (num.tryParse(order['total_amount']?.toString() ?? '0') ?? 0).toDouble();
    final displayAmount = subtotal + deliveryFee > 0 ? subtotal + deliveryFee : totalAmount;

    final rawTime = order['order_time'] ?? order['created_at'] ?? '';
    final parsedTime = DateTime.tryParse(rawTime.toString());
    String timeAgo = 'Just now';
    if (parsedTime != null) {
      final diff = DateTime.now().difference(parsedTime.toLocal());
      if (diff.inMinutes < 1) { timeAgo = 'Just now'; }
      else if (diff.inMinutes < 60) { timeAgo = '${diff.inMinutes}m ago'; }
      else if (diff.inHours < 24) { timeAgo = '${diff.inHours}h ago'; }
      else { timeAgo = '${diff.inDays}d ago'; }
    }

    final orderId = order['id'].toString();
    final shortId = orderId.length > 8 ? orderId.substring(0, 8) : orderId;

    final itemsText = enrichedItems.isNotEmpty
        ? enrichedItems.map((it) => it['name'] ?? it['item_title'] ?? 'Item').join(', ')
        : (order['product_ids']?.toString() ?? '—');

    return InkWell(
      onTap: () => _showOrderDetail(order, enrichedItems),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: AdminTheme.cardDecoration(),
        child: Column(
          children: [
            // Row 1: ID + name + time
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AdminTheme.bg, borderRadius: BorderRadius.circular(5), border: Border.all(color: AdminTheme.border, width: 0.8)),
                  child: Text('#$shortId', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10, color: AdminTheme.textBody)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(name, style: AdminTheme.cardTitle, maxLines: 1, overflow: TextOverflow.ellipsis)),
                Text(timeAgo, style: AdminTheme.body),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AdminTheme.border),
            const SizedBox(height: 8),
            // Row 2: items + status
            Row(
              children: [
                Expanded(child: Text(itemsText, style: AdminTheme.body, maxLines: 1, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
                  child: Text(status.toUpperCase(), style: AdminTheme.micro.copyWith(color: color)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Row 3: amount + action button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  const Text('₹', style: TextStyle(fontSize: 11, color: AdminTheme.textMuted)),
                  Text(displayAmount.toStringAsFixed(0), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AdminTheme.primary)),
                ]),
                _buildAdminActionButton(context, status, orderId, color),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Admin can manually advance an order through the full lifecycle
  Widget _buildAdminActionButton(
    BuildContext context,
    String status,
    String orderId,
    Color color,
  ) {
    String? nextStatus;
    String? label;
    IconData? icon;

    switch (status) {
      case 'pending':
        nextStatus = 'preparing';
        label = 'Start Prep';
        icon = Icons.restaurant_rounded;
        break;
      case 'preparing':
        nextStatus = 'ready_for_pickup';
        label = 'Mark Ready';
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'ready_for_pickup':
        nextStatus = 'accepted';
        label = 'Assign Rider';
        icon = Icons.delivery_dining_rounded;
        break;
      case 'accepted':
      case 'picked_up':
        nextStatus = 'delivered';
        label = 'Mark Delivered';
        icon = Icons.local_shipping_rounded;
        break;
      default:
        return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        try {
          final targetStatus = nextStatus!;
          // API-first transition with Supabase fallback.
          if (!await ApiClient.transitionOrder(orderId, targetStatus)) {
            await Supabase.instance.client
                .from('orders')
                .update({'status': targetStatus})
                .eq('id', orderId);
          }
          if (mounted) {
            messenger.showSnackBar(SnackBar(
              content: Text('\u2705 Order updated to ${targetStatus.replaceAll('_', ' ')}'),
              backgroundColor: _statusColorForFilter(targetStatus),
            ));
          }
        } catch (e) {
          if (mounted) {
            messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _statusColorForFilter(nextStatus),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  void _showOrderDetail(Map<String, dynamic> order, List<Map<String, dynamic>> enrichedItems) {
    final status = (order['status'] ?? 'pending').toString().toLowerCase();
    final color = AdminTheme.statusColor(status);
    final bg = AdminTheme.statusBg(status);

    String name = _usersCache[order['user_id']] ?? order['ordered_by'] ?? order['user_name'] ?? 'Customer';
    if (name.contains('@')) name = name.split('@').first;

    final rawTime = order['order_time'] ?? order['created_at'] ?? '';
    final parsedTime = DateTime.tryParse(rawTime.toString());
    String fullTime = rawTime.toString();
    if (parsedTime != null) {
      final l = parsedTime.toLocal();
      fullTime = '${l.day}/${l.month}/${l.year} ${l.hour}:${l.minute.toString().padLeft(2, '0')}';
    }

    final subtotal = (num.tryParse(order['subtotal']?.toString() ?? '0') ?? 0).toDouble();
    final deliveryFee = (num.tryParse(order['delivery_fee']?.toString() ?? '0') ?? 0).toDouble();
    final totalAmount = (num.tryParse(order['total_amount']?.toString() ?? '0') ?? 0).toDouble();
    final displayTotal = subtotal + deliveryFee > 0 ? subtotal + deliveryFee : totalAmount;
    final paymentMethod = order['payment_method']?.toString() ?? 'Card';
    final address = (order['delivery_address'] ?? order['address'] ?? 'Not specified').toString();
    final orderId = order['id'].toString();
    final shortId = orderId.length > 8 ? orderId.substring(0, 8) : orderId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AdminTheme.bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle
              Center(child: Container(margin: const EdgeInsets.only(top: 10, bottom: 16), width: 36, height: 4, decoration: BoxDecoration(color: AdminTheme.border, borderRadius: BorderRadius.circular(2)))),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Order Details', style: AdminTheme.sectionTitle),
                      Text('Order #$shortId', style: AdminTheme.body),
                    ]),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
                      child: Text(status.toUpperCase(), style: AdminTheme.micro.copyWith(color: color)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  children: [
                    Row(children: [
                      Expanded(child: _infoCard(Icons.person_outline_rounded, 'Customer', name)),
                      const SizedBox(width: 10),
                      Expanded(child: _infoCard(Icons.access_time_rounded, 'Time', fullTime)),
                    ]),
                    const SizedBox(height: 10),
                    _infoCard(Icons.location_on_outlined, 'Address', address),
                    const SizedBox(height: 10),
                    _infoCard(Icons.payment_outlined, 'Payment', paymentMethod.toUpperCase()),
                    const SizedBox(height: 16),
                    const Text('Items', style: AdminTheme.sectionTitle),
                    const SizedBox(height: 8),
                    Container(
                      decoration: AdminTheme.cardDecoration(),
                      child: Column(
                        children: enrichedItems.isEmpty
                            ? [const Padding(padding: EdgeInsets.all(14), child: Text('No items data', style: AdminTheme.body))]
                            : enrichedItems.map((it) {
                                final iName = it['name'] ?? it['item_title'] ?? 'Item';
                                final qty = it['quantity'] ?? it['qty'] ?? 1;
                                final price = (num.tryParse(it['price']?.toString() ?? '0') ?? 0).toDouble();
                                final url = it['thumbnail_url'];
                                return Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Row(children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        url != null && url.isNotEmpty ? url : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=80&h=80&fit=crop',
                                        width: 40, height: 40, fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(iName, style: AdminTheme.cardTitle),
                                      Text('Qty: $qty', style: AdminTheme.body),
                                    ])),
                                    Text('₹${price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AdminTheme.dark)),
                                  ]),
                                );
                              }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Bill summary
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AdminTheme.dark, borderRadius: BorderRadius.circular(10)),
                      child: Column(children: [
                        _priceRow('Subtotal', subtotal),
                        const SizedBox(height: 8),
                        _priceRow('Delivery Fee', deliveryFee),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(color: Colors.white12, height: 1)),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Total', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('₹${displayTotal.toStringAsFixed(0)}', style: const TextStyle(color: AdminTheme.primary, fontSize: 18, fontWeight: FontWeight.w800)),
                        ]),
                      ]),
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

  Widget _infoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: AdminTheme.cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, size: 12, color: AdminTheme.textMuted), const SizedBox(width: 5), Text(label, style: AdminTheme.label)]),
        const SizedBox(height: 4),
        Text(value, style: AdminTheme.cardTitle),
      ]),
    );
  }

  Widget _priceRow(String label, double amount) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
    ]);
  }
}
