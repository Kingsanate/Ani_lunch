import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin_theme.dart';
import '../core/cache/admin_cache.dart';
import '../services/api_client.dart';

class DailyDealsManagementView extends StatefulWidget {
  const DailyDealsManagementView({super.key});

  @override
  State<DailyDealsManagementView> createState() => _DailyDealsManagementViewState();
}

class _DailyDealsManagementViewState extends State<DailyDealsManagementView> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _deals = [];

  @override
  void initState() {
    super.initState();
    _fetchDeals();
  }

  Future<void> _fetchDeals() async {
    try {
      final data = await AdminCache.instance.fetchCacheFirst(
        entityType: 'daily_deals',
        fetcher: () async => ApiClient.fetchDeals(),
      );
      if (mounted) setState(() { _deals = List<Map<String, dynamic>>.from(data); _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDealSheet({Map<String, dynamic>? deal}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DealEditorSheet(
        deal: deal,
        onSave: (data) async {
          setState(() => _isLoading = true);
          try {
            if (deal != null) data['id'] = deal['id'];
            await ApiClient.saveDeal(data);
            _fetchDeals();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Deal saved!'), backgroundColor: AdminTheme.success),
              );
            }
          } catch (e) {
            if (mounted) { setState(() => _isLoading = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
          }
        },
      ),
    );
  }

  void _deleteDeal(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Deal?', style: AdminTheme.sectionTitle),
        content: const Text('This deal will be removed from the customer app.', style: AdminTheme.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.danger, foregroundColor: Colors.white, elevation: 0),
            child: const Text('Delete', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await ApiClient.deleteDeal(int.parse(id));
        _fetchDeals();
      } catch (_) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Color _parseColor(String? hex) {
    try {
      String h = hex ?? '0xFFF15A24';
      if (h.startsWith('#')) h = '0xFF${h.substring(1)}';
      return Color(int.parse(h));
    } catch (_) { return const Color(0xFFF15A24); }
  }

  IconData _parseIcon(String? name) {
    switch (name) {
      case 'delivery_dining_rounded': return Icons.delivery_dining_rounded;
      case 'savings_rounded': return Icons.savings_rounded;
      case 'star_rounded': return Icons.star_rounded;
      case 'local_offer_rounded': return Icons.local_offer_rounded;
      case 'bolt_rounded': return Icons.bolt_rounded;
      default: return Icons.percent_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.bg,
      body: Column(
        children: [
          AdminTheme.pageHeader(
            context: context,
            title: 'Daily Deals',
            action: AdminTheme.primaryButton(label: 'Add Deal', icon: Icons.add_rounded, onTap: _showDealSheet, small: true),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AdminTheme.primary, strokeWidth: 2))
                : _deals.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                        itemCount: _deals.length,
                        itemBuilder: (_, i) => _buildDealCard(_deals[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 56, height: 56, decoration: BoxDecoration(color: AdminTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.local_offer_rounded, color: AdminTheme.primary, size: 26)),
        const SizedBox(height: 12),
        const Text('No Deals Yet', style: AdminTheme.sectionTitle),
        const SizedBox(height: 4),
        const Text('Add a deal to show promotions on the customer app.', style: AdminTheme.body),
        const SizedBox(height: 16),
        AdminTheme.primaryButton(label: 'Create First Deal', onTap: _showDealSheet),
      ]),
    );
  }

  Widget _buildDealCard(Map<String, dynamic> deal) {
    final isActive = deal['is_active'] == true;
    final cardColor = _parseColor(deal['color_hex']?.toString());
    final icon = _parseIcon(deal['icon_name']?.toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: AdminTheme.cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(deal['title'] ?? '', style: AdminTheme.cardTitle),
                const SizedBox(height: 2),
                Text(deal['subtitle'] ?? '', style: AdminTheme.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isActive ? AdminTheme.success.withValues(alpha: 0.10) : AdminTheme.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(isActive ? 'Active' : 'Inactive',
                        style: TextStyle(color: isActive ? AdminTheme.success : AdminTheme.danger, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                  if (deal['tag_text'] != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: cardColor.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(5)),
                      child: Text(deal['tag_text'].toString(), style: TextStyle(color: cardColor, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ]),
              ],
            ),
          ),
          Column(children: [
            _iconBtn(Icons.edit_outlined, AdminTheme.info, () => _showDealSheet(deal: deal)),
            const SizedBox(height: 6),
            _iconBtn(Icons.delete_outline_rounded, AdminTheme.danger, () => _deleteDeal(deal['id'].toString())),
          ]),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(7)),
        child: Icon(icon, color: color, size: 14),
      ),
    );
  }
}

// ── Deal Editor Sheet ─────────────────────────────────────────────────────────
class DealEditorSheet extends StatefulWidget {
  final Map<String, dynamic>? deal;
  final Function(Map<String, dynamic>) onSave;
  const DealEditorSheet({super.key, this.deal, required this.onSave});

  @override
  State<DealEditorSheet> createState() => _DealEditorSheetState();
}

class _DealEditorSheetState extends State<DealEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _tagController;
  late String _colorHex;
  late String _iconName;
  late bool _isActive;

  final _colors = [
    {'name': 'Orange', 'hex': '0xFFF15A24', 'color': const Color(0xFFF15A24)},
    {'name': 'Yellow', 'hex': '0xFFFFB800', 'color': const Color(0xFFFFB800)},
    {'name': 'Green', 'hex': '0xFF8CC63F', 'color': const Color(0xFF8CC63F)},
    {'name': 'Red', 'hex': '0xFFE53935', 'color': const Color(0xFFE53935)},
    {'name': 'Blue', 'hex': '0xFF1E88E5', 'color': const Color(0xFF1E88E5)},
    {'name': 'Purple', 'hex': '0xFF8E24AA', 'color': const Color(0xFF8E24AA)},
  ];

  final _icons = [
    {'name': 'Percent', 'id': 'percent_rounded', 'icon': Icons.percent_rounded},
    {'name': 'Delivery', 'id': 'delivery_dining_rounded', 'icon': Icons.delivery_dining_rounded},
    {'name': 'Savings', 'id': 'savings_rounded', 'icon': Icons.savings_rounded},
    {'name': 'Star', 'id': 'star_rounded', 'icon': Icons.star_rounded},
    {'name': 'Offer', 'id': 'local_offer_rounded', 'icon': Icons.local_offer_rounded},
    {'name': 'Flash', 'id': 'bolt_rounded', 'icon': Icons.bolt_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.deal?['title'] ?? '');
    _subtitleController = TextEditingController(text: widget.deal?['subtitle'] ?? '');
    _tagController = TextEditingController(text: widget.deal?['tag_text'] ?? 'Today Only');
    _colorHex = widget.deal?['color_hex'] ?? '0xFFF15A24';
    _iconName = widget.deal?['icon_name'] ?? 'percent_rounded';
    _isActive = widget.deal?['is_active'] ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selColor = _colors.firstWhere((c) => c['hex'] == _colorHex, orElse: () => _colors.first);
    final selIcon = _icons.firstWhere((i) => i['id'] == _iconName, orElse: () => _icons.first);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(margin: const EdgeInsets.only(top: 10, bottom: 8), width: 36, height: 4, decoration: BoxDecoration(color: AdminTheme.border, borderRadius: BorderRadius.circular(2)))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.deal == null ? 'Create Deal' : 'Edit Deal', style: AdminTheme.sectionTitle),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, size: 18, color: AdminTheme.textMuted), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                ],
              ),
            ),
            const Divider(color: AdminTheme.border, height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Live preview
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: (selColor['color'] as Color).withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: (selColor['color'] as Color).withValues(alpha: 0.20)),
                        ),
                        child: Row(children: [
                          Container(width: 38, height: 38, decoration: BoxDecoration(color: selColor['color'] as Color, borderRadius: BorderRadius.circular(9)),
                            child: Icon(selIcon['icon'] as IconData, color: Colors.white, size: 18)),
                          const SizedBox(width: 12),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(_titleController.text.isEmpty ? 'Deal Title' : _titleController.text, style: AdminTheme.cardTitle),
                            Text(_subtitleController.text.isEmpty ? 'Subtitle' : _subtitleController.text, style: AdminTheme.body),
                          ]),
                        ]),
                      ),
                      const SizedBox(height: 14),
                      AdminTheme.sectionLabel('Title'),
                      TextFormField(
                        controller: _titleController,
                        onChanged: (_) => setState(() {}),
                        decoration: AdminTheme.inputDecoration('e.g. 20% OFF'),
                        style: const TextStyle(fontSize: 13),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      AdminTheme.sectionLabel('Subtitle'),
                      TextFormField(
                        controller: _subtitleController,
                        onChanged: (_) => setState(() {}),
                        decoration: AdminTheme.inputDecoration('Short description'),
                        style: const TextStyle(fontSize: 13),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      AdminTheme.sectionLabel('Tag Text'),
                      TextFormField(
                        controller: _tagController,
                        decoration: AdminTheme.inputDecoration('e.g. Today Only'),
                        style: const TextStyle(fontSize: 13),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      AdminTheme.sectionLabel('Color'),
                      Wrap(spacing: 8, children: _colors.map((c) {
                        final isSel = _colorHex == c['hex'];
                        return GestureDetector(
                          onTap: () => setState(() => _colorHex = c['hex'] as String),
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: c['color'] as Color,
                              shape: BoxShape.circle,
                              border: isSel ? Border.all(color: Colors.black26, width: 2.5) : null,
                              boxShadow: isSel ? [BoxShadow(color: (c['color'] as Color).withValues(alpha: 0.4), blurRadius: 6)] : null,
                            ),
                            child: isSel ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
                          ),
                        );
                      }).toList()),
                      const SizedBox(height: 14),
                      AdminTheme.sectionLabel('Icon'),
                      Wrap(spacing: 8, children: _icons.map((i) {
                        final isSel = _iconName == i['id'];
                        final c = selColor['color'] as Color;
                        return GestureDetector(
                          onTap: () => setState(() => _iconName = i['id'] as String),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: isSel ? c : AdminTheme.bg,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(color: isSel ? c : AdminTheme.border, width: isSel ? 1.5 : 0.8),
                            ),
                            child: Icon(i['icon'] as IconData, color: isSel ? Colors.white : AdminTheme.textMuted, size: 20),
                          ),
                        );
                      }).toList()),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: AdminTheme.bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AdminTheme.border, width: 0.8)),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Active on App', style: AdminTheme.cardTitle),
                          Switch(value: _isActive, onChanged: (v) => setState(() => _isActive = v), activeTrackColor: AdminTheme.primary.withValues(alpha: 0.5), activeThumbColor: AdminTheme.primary),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              widget.onSave({
                                'title': _titleController.text.trim(),
                                'subtitle': _subtitleController.text.trim(),
                                'tag_text': _tagController.text.trim(),
                                'color_hex': _colorHex,
                                'icon_name': _iconName,
                                'is_active': _isActive,
                              });
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminTheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(widget.deal == null ? 'Create Deal' : 'Save Changes', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
