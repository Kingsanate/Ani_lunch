import '../main.dart';
import 'dart:async';
import 'dart:convert';
import 'package:anilunch_core/anilunch_core.dart' hide ApiClient;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../admin_theme.dart';
import '../core/cache/admin_cache.dart';
import '../core/providers/api_provider.dart';
import '../services/api_client.dart';

class MenuManagementView extends StatefulWidget {
  const MenuManagementView({super.key});

  @override
  State<MenuManagementView> createState() => _MenuManagementViewState();
}

class _MenuManagementViewState extends State<MenuManagementView> {
  final _nameController     = TextEditingController();
  final _subtitleController = TextEditingController();
  final _priceController    = TextEditingController();

  String _selectedCategory = 'Beef';
  String _filterCategory   = 'All';
  String _mainTab          = 'Meat';

  List<Map<String, dynamic>> _menuItems   = [];
  List<Map<String, dynamic>> _lunchItems  = [];
  List<Map<String, dynamic>> _categoriesList = [];
  bool _isLoading = true;
  StreamSubscription<WsEvent>? _menuChannel;

  // Image upload state
  Uint8List? _selectedImageBytes;
  String?    _selectedImageName;
  Uint8List? _selectedImageBytes2;
  String?    _selectedImageName2;
  Uint8List? _selectedImageBytes3;
  String?    _selectedImageName3;
  bool _isUploading = false;

  // Lunch option controls (preserved from previous implementation)
  static const List<String> _allRiceOptions = ['White Rice', 'Brown Rice', 'Jadoh', 'No Rice'];
  static const List<String> _allMeatOptions = ['Chicken', 'Beef', 'Pork', 'Fish'];
  List<String> _selectedRiceOptions = List.from(_allRiceOptions);
  List<String> _selectedMeatOptions = List.from(_allMeatOptions);

  final _picker = ImagePicker();

  // ── Toast notification ─────────────────────────────────────────────────────
  void _showToast({required String title, required String message, bool isError = false}) {
    final accent = isError ? AdminTheme.danger : AdminTheme.success;
    final icon   = isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded;
    rootScaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(milliseconds: 3000),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        content: Container(
          decoration: BoxDecoration(
            color: AdminTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border(left: BorderSide(color: accent, width: 3)),
            boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.12), blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: accent)),
                const SizedBox(height: 1),
                Text(message, style: AdminTheme.body),
              ])),
            ]),
          ),
        ),
      ));
  }

  // ── Data fetching ──────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _subscribeToMenu();
  }

  Future<void> _fetchMenuInitial() async {
    try {
      final categoriesData = await AdminCache.instance.fetchCacheFirst(
        entityType: 'menus',
        fetcher: () async => ApiClient.fetchMenus(),
      );
      final data = await AdminCache.instance.fetchCacheFirst(
        entityType: 'menu_items',
        fetcher: () async => ApiClient.fetchItems(),
      );
      final lunchRaw = await AniApi.instance.api.client.get<List<dynamic>>('/api/v1/catalog/meal_products').catchError((_) => <dynamic>[]);
      final lunchData = lunchRaw.cast<Map<String, dynamic>>();

      if (mounted) {
        setState(() {
          _categoriesList = List<Map<String, dynamic>>.from(categoriesData);
          _menuItems      = List<Map<String, dynamic>>.from(data);
          _lunchItems     = List<Map<String, dynamic>>.from(lunchData);
          _isLoading      = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeToMenu() {
    _fetchMenuInitial();
    final realtime = AniApi.instance.realtime;
    if (!realtime.isConnected) return;
    realtime.join('admin');
    _menuChannel = realtime.events.listen((event) {
      _fetchMenuInitial();
    });
  }

  @override
  void dispose() {
    _menuChannel?.cancel();
    _nameController.dispose();
    _subtitleController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // ── Image helpers ──────────────────────────────────────────────────────────
  Future<void> _pickImage(int index) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() { 
        if (index == 1) { _selectedImageBytes = bytes; _selectedImageName = image.name; }
        else if (index == 2) { _selectedImageBytes2 = bytes; _selectedImageName2 = image.name; }
        else if (index == 3) { _selectedImageBytes3 = bytes; _selectedImageName3 = image.name; }
      });
    }
  }

  Future<String?> _uploadImage(Uint8List bytes, String fileName, String folder, String bucket) async {
    try {
      final b64 = base64Encode(bytes);
      return 'data:image/jpeg;base64,$b64';
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────
  Future<void> _deleteMenuItem(Map<String, dynamic> item) async {
    final isLunch = _mainTab == 'Lunch';
    final title   = isLunch ? item['name'] : item['item_title'];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Item?', style: AdminTheme.sectionTitle),
        content: Text('Remove "$title" from the menu?', style: AdminTheme.body),
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

    if (confirm != true) return;
    try {
      if (isLunch) {
        await AniApi.instance.api.client.delete('/api/v1/catalog/meal_products/${item['id']}').catchError((_) => null);
      } else {
        await ApiClient.deleteItem(item['id'].toString());
      }
      if (mounted) {
        setState(() {
          if (isLunch) { _lunchItems.removeWhere((i) => i['id'] == item['id']); }
          else { _menuItems.removeWhere((i) => i['id'] == item['id']); }
        });
        _showToast(title: 'Deleted', message: '"$title" has been removed.');
      }
    } catch (_) {
      if (mounted) _showToast(title: 'Delete Failed', message: 'Something went wrong.', isError: true);
    }
  }

  // ── Add / Edit modal ───────────────────────────────────────────────────────
  void _showAddEditModal({Map<String, dynamic>? item}) {
    final isLunch   = _mainTab == 'Lunch';
    final isEditing = item != null;

    if (isEditing) {
      _nameController.text     = (isLunch ? item['name'] : item['item_title']) ?? '';
      _subtitleController.text = (isLunch ? item['description'] : item['item_info']) ?? '';
      _priceController.text    = ((isLunch ? item['price'] : item['item_price']) ?? 0).toString();
      _selectedCategory = (!isLunch) ? (item['menus']?['menu_title'] ?? item['category']) : null;
      _selectedImageBytes = null;
      _selectedImageName  = null;
      _selectedImageBytes2 = null;
      _selectedImageName2  = null;
      _selectedImageBytes3 = null;
      _selectedImageName3  = null;
      if (isLunch) {
        final riceRaw = item['rice_options'];
        _selectedRiceOptions = riceRaw is List ? List<String>.from(riceRaw) : List.from(_allRiceOptions);
        final meatRaw = item['meat_options'];
        _selectedMeatOptions = meatRaw is List ? List<String>.from(meatRaw) : List.from(_allMeatOptions);
      }
    } else {
      _nameController.clear();
      _subtitleController.clear();
      _priceController.clear();
      if (!isLunch) _selectedCategory = _categoriesList.isNotEmpty ? (_categoriesList.first['menu_title'] ?? 'Beef') : 'Beef';
      _selectedImageBytes = null;
      _selectedImageName  = null;
      _selectedImageBytes2 = null;
      _selectedImageName2  = null;
      _selectedImageBytes3 = null;
      _selectedImageName3  = null;
      if (isLunch) {
        _selectedRiceOptions = List.from(_allRiceOptions);
        _selectedMeatOptions = List.from(_allMeatOptions);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            height: MediaQuery.of(ctx).size.height * 0.88,
            decoration: const BoxDecoration(
              color: AdminTheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                // Handle + header
                Center(child: Container(margin: const EdgeInsets.only(top: 10, bottom: 0), width: 36, height: 4,
                    decoration: BoxDecoration(color: AdminTheme.border, borderRadius: BorderRadius.circular(2)))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(isEditing ? 'Edit Item' : 'Add New Item', style: AdminTheme.sectionTitle),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, size: 18, color: AdminTheme.textMuted),
                      padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                    ),
                  ]),
                ),
                const Divider(color: AdminTheme.border, height: 1),
                // Scrollable body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        AdminTheme.sectionLabel('Images (Up to 3)'),
                        _buildImageUploadArea(
                          setModalState, 
                          existingUrl: isEditing ? (isLunch ? item['image_url'] : item['thumbnail_url']) : null,
                          existingUrl2: isEditing ? (isLunch ? item['image_url_2'] : item['thumbnail_url_2']) : null,
                          existingUrl3: isEditing ? (isLunch ? item['image_url_3'] : item['thumbnail_url_3']) : null,
                        ),
                        const SizedBox(height: 12),
                        // Name
                        AdminTheme.sectionLabel('Name'),
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(fontSize: 13),
                          decoration: AdminTheme.inputDecoration(isLunch ? 'e.g. Khasi Thali' : 'e.g. Beef Curry'),
                        ),
                        const SizedBox(height: 10),
                        // Description
                        AdminTheme.sectionLabel('Description'),
                        TextField(
                          controller: _subtitleController,
                          style: const TextStyle(fontSize: 13),
                          decoration: AdminTheme.inputDecoration(isLunch ? 'e.g. Complete meal' : 'e.g. Delicious beef curry'),
                        ),
                        const SizedBox(height: 10),
                        // Price
                        AdminTheme.sectionLabel('Price (₹)'),
                        TextField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 13),
                          decoration: AdminTheme.inputDecoration('e.g. 120'),
                        ),
                        const SizedBox(height: 10),
                        // Category (Meat only)
                        if (!isLunch) ...[
                          AdminTheme.sectionLabel('Category'),
                          _buildCategorySelector(setModalState),
                          const SizedBox(height: 10),
                        ],
                        // Rice & Meat options (Lunch only)
                        if (isLunch) ...[
                          AdminTheme.sectionLabel('Rice Options'),
                          _buildOptionToggles(
                            options: _allRiceOptions,
                            selected: _selectedRiceOptions,
                            onToggle: (opt) {
                              setModalState(() {
                                if (_selectedRiceOptions.contains(opt)) {
                                  _selectedRiceOptions.remove(opt);
                                } else {
                                  _selectedRiceOptions.add(opt);
                                }
                              });
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 10),
                          AdminTheme.sectionLabel('Meat Options'),
                          _buildOptionToggles(
                            options: _allMeatOptions,
                            selected: _selectedMeatOptions,
                            onToggle: (opt) {
                              setModalState(() {
                                if (_selectedMeatOptions.contains(opt)) {
                                  _selectedMeatOptions.remove(opt);
                                } else {
                                  _selectedMeatOptions.add(opt);
                                }
                              });
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 10),
                        ],
                        // Save button
                        const SizedBox(height: 6),
                        _isUploading
                            ? const Center(child: CircularProgressIndicator(color: AdminTheme.primary, strokeWidth: 2))
                            : SizedBox(
                                width: double.infinity,
                                height: 42,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (_nameController.text.isEmpty || _priceController.text.isEmpty) return;
                                    setModalState(() => _isUploading = true);
                                    try {
                                      String? finalUrl = isEditing ? (isLunch ? item['image_url'] : item['thumbnail_url']) : null;
                                      String? finalUrl2 = isEditing ? (isLunch ? item['image_url_2'] : item['thumbnail_url_2']) : null;
                                      String? finalUrl3 = isEditing ? (isLunch ? item['image_url_3'] : item['thumbnail_url_3']) : null;
                                      
                                      final bucket = isLunch ? 'meal-products' : 'items';
                                      final folder = isLunch ? 'meal-products' : _selectedCategory.toLowerCase();
                                      
                                      if (_selectedImageBytes != null && _selectedImageName != null) {
                                        final uploaded = await _uploadImage(_selectedImageBytes!, _selectedImageName!, folder, bucket);
                                        if (uploaded != null) finalUrl = uploaded;
                                      }
                                      if (_selectedImageBytes2 != null && _selectedImageName2 != null) {
                                        final uploaded = await _uploadImage(_selectedImageBytes2!, _selectedImageName2!, folder, bucket);
                                        if (uploaded != null) finalUrl2 = uploaded;
                                      }
                                      if (_selectedImageBytes3 != null && _selectedImageName3 != null) {
                                        final uploaded = await _uploadImage(_selectedImageBytes3!, _selectedImageName3!, folder, bucket);
                                        if (uploaded != null) finalUrl3 = uploaded;
                                      }

                                      Map<String, dynamic> data;

                                      if (isLunch) {
                                        data = {
                                          'name': _nameController.text,
                                          'description': _subtitleController.text,
                                          'price': int.tryParse(_priceController.text) ?? 0,
                                          'image_url': finalUrl,
                                          'image_url_2': finalUrl2,
                                          'image_url_3': finalUrl3,
                                          'is_available': true,
                                          'rice_options': _selectedRiceOptions,
                                          'meat_options': _selectedMeatOptions,
                                          'updated_at': DateTime.now().toIso8601String(),
                                        };
                                      } else {
                                        String? menuId;
                                        if (_categoriesList.isNotEmpty) {
                                          menuId = _categoriesList.firstWhere(
                                              (m) => m['menu_title'] == _selectedCategory,
                                              orElse: () => _categoriesList.first)['id'];
                                        }
                                        data = {
                                          'item_title': _nameController.text,
                                          'item_info': _subtitleController.text,
                                          'item_price': int.tryParse(_priceController.text) ?? 0,
                                          'thumbnail_url': finalUrl,
                                          'thumbnail_url_2': finalUrl2,
                                          'thumbnail_url_3': finalUrl3,
                                          'status': 'available',
                                          'menu_id': menuId,
                                        };
                                      }

                                      if (isEditing) {
                                        if (isLunch) {
                                          await AniApi.instance.api.client.put('/api/v1/catalog/meal_products/${item['id']}', body: data).catchError((_) => null);
                                        } else {
                                          data['id'] = item['id'];
                                          await ApiClient.saveItem(data);
                                        }
                                      } else {
                                        if (isLunch) {
                                          await AniApi.instance.api.client.post('/api/v1/catalog/meal_products', body: data).catchError((_) => null);
                                        } else {
                                          await ApiClient.saveItem(data);
                                        }
                                      }

                                      if (!ctx.mounted) return;
                                      if (mounted) {
                                        final savedName = _nameController.text;
                                        final wasEditing = isEditing;
                                        Navigator.pop(ctx);
                                        setState(() => _isUploading = false);
                                        await _fetchMenuInitial();
                                        Future.microtask(() => _showToast(
                                          title: wasEditing ? 'Item Updated' : 'Item Saved',
                                          message: wasEditing ? '$savedName has been updated.' : '$savedName added to the menu.',
                                        ));
                                      }
                                    } catch (e) {
                                      debugPrint('Save error: $e');
                                      if (mounted) {
                                        setModalState(() => _isUploading = false);
                                        _showToast(title: 'Save Failed', message: 'Could not save item. Try again.', isError: true);
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AdminTheme.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: Text(isEditing ? 'Update Item' : 'Save Item',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Modal sub-widgets ──────────────────────────────────────────────────────
  Widget _buildImageUploadArea(StateSetter setModalState, {String? existingUrl, String? existingUrl2, String? existingUrl3}) {
    return Row(
      children: [
        Expanded(child: _buildSingleImageUpload(setModalState, 1, _selectedImageBytes, existingUrl)),
        const SizedBox(width: 8),
        Expanded(child: _buildSingleImageUpload(setModalState, 2, _selectedImageBytes2, existingUrl2)),
        const SizedBox(width: 8),
        Expanded(child: _buildSingleImageUpload(setModalState, 3, _selectedImageBytes3, existingUrl3)),
      ],
    );
  }

  Widget _buildSingleImageUpload(StateSetter setModalState, int index, Uint8List? bytes, String? existingUrl) {
    return InkWell(
      onTap: () async { await _pickImage(index); setModalState(() {}); },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: AdminTheme.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AdminTheme.border, width: 0.8),
        ),
        child: bytes != null
            ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.memory(bytes, fit: BoxFit.cover))
            : existingUrl != null && existingUrl.isNotEmpty
                ? Stack(fit: StackFit.expand, children: [
                    ClipRRect(borderRadius: BorderRadius.circular(10),
                        child: Image.network(existingUrl, fit: BoxFit.cover,
                            errorBuilder: (e1, e2, e3) => const Icon(Icons.broken_image_outlined, color: AdminTheme.textMuted, size: 28))),
                    ClipRRect(borderRadius: BorderRadius.circular(10),
                        child: Container(color: Colors.black.withValues(alpha: 0.28),
                          child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.camera_alt_outlined, color: Colors.white, size: 20),
                            SizedBox(height: 4),
                            Text('Change', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
                          ]))),
                  ])
                : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.add_a_photo_outlined, color: AdminTheme.textMuted, size: 24),
                    const SizedBox(height: 6),
                    Text('Image $index', style: const TextStyle(color: AdminTheme.textMuted, fontSize: 11)),
                  ]),
      ),
    );
  }

  Widget _buildCategorySelector(StateSetter setModalState) {
    final cats = _categoriesList.isNotEmpty
        ? _categoriesList.map((e) => e['menu_title'] as String).toList()
        : ['Beef', 'Pork', 'Chicken', 'Fish'];
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: cats.map((cat) {
        final isSel = _selectedCategory == cat;
        return GestureDetector(
          onTap: () => setModalState(() => _selectedCategory = cat),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSel ? AdminTheme.primary.withValues(alpha: 0.10) : AdminTheme.bg,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: isSel ? AdminTheme.primary : AdminTheme.border, width: isSel ? 1.5 : 0.8),
            ),
            child: Text(cat, style: TextStyle(color: isSel ? AdminTheme.primary : AdminTheme.textBody, fontWeight: isSel ? FontWeight.w700 : FontWeight.w500, fontSize: 12)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOptionToggles({
    required List<String> options,
    required List<String> selected,
    required void Function(String) onToggle,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: options.map((opt) {
        final isSel = selected.contains(opt);
        return GestureDetector(
          onTap: () => onToggle(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSel ? AdminTheme.primary.withValues(alpha: 0.09) : AdminTheme.bg,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: isSel ? AdminTheme.primary : AdminTheme.border, width: isSel ? 1.5 : 0.8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(isSel ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  size: 13, color: isSel ? AdminTheme.primary : AdminTheme.textMuted),
              const SizedBox(width: 5),
              Text(opt, style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                  color: isSel ? AdminTheme.primary : AdminTheme.textBody)),
            ]),
          ),
        );
      }).toList(),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final filteredItems = _mainTab == 'Lunch'
        ? _lunchItems
        : (_filterCategory == 'All'
            ? _menuItems
            : _menuItems.where((i) => (i['menus']?['menu_title'] ?? i['category']) == _filterCategory).toList());

    return Scaffold(
      backgroundColor: AdminTheme.bg,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, bottom: 0, left: 4, right: 16),
            decoration: const BoxDecoration(color: AdminTheme.surface, border: Border(bottom: BorderSide(color: AdminTheme.border, width: 0.8))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Builder(builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu_rounded, color: AdminTheme.dark, size: 20),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    constraints: const BoxConstraints(),
                  )),
                  const Expanded(child: Text('Menu Manager', style: AdminTheme.pageTitle)),
                  AdminTheme.primaryButton(
                    label: 'Add Item',
                    icon: Icons.add_rounded,
                    small: true,
                    onTap: () => _showAddEditModal(),
                  ),
                ]),
                // ── Main tabs ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(children: [
                    _tabBtn('Meat'),
                    const SizedBox(width: 8),
                    _tabBtn('Lunch'),
                  ]),
                ),
                // ── Category filter (Meat only) ────────────────────────────
                if (_mainTab == 'Meat')
                  _buildCategoryFilter()
                else
                  const SizedBox(height: 10),
              ],
            ),
          ),
          // ── List ──────────────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AdminTheme.primary, strokeWidth: 2))
                : filteredItems.isEmpty
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 52, height: 52, decoration: BoxDecoration(color: AdminTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.restaurant_menu_rounded, color: AdminTheme.primary, size: 24)),
                        const SizedBox(height: 10),
                        const Text('No items found', style: AdminTheme.sectionTitle),
                        const SizedBox(height: 4),
                        const Text('Tap "Add Item" to get started.', style: AdminTheme.body),
                      ]))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
                        itemCount: filteredItems.length,
                        itemBuilder: (_, i) => _buildItemCard(filteredItems[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _tabBtn(String title) {
    final isSel = _mainTab == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mainTab = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSel ? AdminTheme.dark : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSel ? AdminTheme.dark : AdminTheme.border, width: 0.8),
          ),
          child: Center(child: Text(title, style: TextStyle(
            color: isSel ? Colors.white : AdminTheme.textBody,
            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ))),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final cats = ['All'];
    if (_categoriesList.isNotEmpty) {
      cats.addAll(_categoriesList.map((e) => e['menu_title'] as String));
    } else {
      cats.addAll(['Beef', 'Pork', 'Chicken', 'Fish']);
    }
    return SizedBox(
      height: 44,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        scrollDirection: Axis.horizontal,
        itemCount: cats.length,
        itemBuilder: (_, i) {
          final cat = cats[i];
          final isSel = _filterCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _filterCategory = cat),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isSel ? AdminTheme.dark : AdminTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSel ? AdminTheme.dark : AdminTheme.border, width: 0.8),
              ),
              child: Text(cat, style: TextStyle(
                color: isSel ? Colors.white : AdminTheme.textBody,
                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              )),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final isLunch       = _mainTab == 'Lunch';
    final title         = isLunch ? item['name'] : item['item_title'];
    final description   = isLunch ? item['description'] : item['item_info'];
    final categoryBadge = isLunch ? null : (item['menus']?['menu_title'] ?? item['category']);
    final price         = isLunch ? item['price'] : item['item_price'];
    final image         = isLunch ? item['image_url'] : item['thumbnail_url'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: AdminTheme.cardDecoration(),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              image ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=80&h=80&fit=crop',
              width: 54, height: 54, fit: BoxFit.cover,
              errorBuilder: (e1, e2, e3) => Container(width: 54, height: 54,
                color: AdminTheme.bg, child: const Icon(Icons.image_outlined, color: AdminTheme.textMuted, size: 22)),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(title ?? '', style: AdminTheme.cardTitle, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (categoryBadge != null && categoryBadge.toString().trim().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AdminTheme.dark.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(5)),
                      child: Text(categoryBadge.toString().toUpperCase(), style: AdminTheme.micro.copyWith(color: AdminTheme.dark)),
                    ),
                ]),
                const SizedBox(height: 2),
                Text(description?.toString() ?? '', style: AdminTheme.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('₹$price', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AdminTheme.primary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Action buttons
          Column(children: [
            _actionBtn(Icons.edit_outlined, AdminTheme.info, () => _showAddEditModal(item: item)),
            const SizedBox(height: 6),
            _actionBtn(Icons.delete_outline_rounded, AdminTheme.danger, () => _deleteMenuItem(item)),
          ]),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(7), border: Border.all(color: color.withValues(alpha: 0.15), width: 0.8)),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}
