import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lunch_provider.dart';

class CustomizationBottomSheet extends StatefulWidget {
  final Map<String, dynamic> product;

  const CustomizationBottomSheet({super.key, required this.product});

  @override
  State<CustomizationBottomSheet> createState() => _CustomizationBottomSheetState();
}

class _CustomizationBottomSheetState extends State<CustomizationBottomSheet> {
  late String _selectedRice;
  late Map<String, int> _meatQuantities;
  
  late List<String> _riceOptions;
  late List<String> _meatOptions;

  @override
  void initState() {
    super.initState();
    final rawRice = widget.product['rice_options'] as List<dynamic>?;
    _riceOptions = rawRice != null ? rawRice.cast<String>() : ['White Rice', 'Brown Rice', 'Jadoh', 'No Rice'];
        
    final rawMeat = widget.product['meat_options'] as List<dynamic>?;
    _meatOptions = rawMeat != null ? rawMeat.cast<String>() : ['Chicken', 'Beef', 'Pork', 'Fish'];

    _selectedRice = _riceOptions.isNotEmpty ? _riceOptions.first : '';
    
    _meatQuantities = {};
    for (int i = 0; i < _meatOptions.length; i++) {
      _meatQuantities[_meatOptions[i]] = (i == 0) ? 1 : 0;
    }
  }

  int _calculateFinalPrice(int basePrice) {
    int totalMeatPieces = _meatQuantities.values.fold(0, (sum, val) => sum + val);
    int extraMeatCount = totalMeatPieces > 1 ? totalMeatPieces - 1 : 0;
    return basePrice + (extraMeatCount * 20);
  }

  void _addToCart(int finalPrice, Map<String, dynamic> product) {
    int totalMeatPieces = _meatQuantities.values.fold(0, (sum, val) => sum + val);
    if (totalMeatPieces == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least 1 meat piece.'), backgroundColor: Colors.red));
      return;
    }

    final meatStrings = _meatQuantities.entries
        .where((e) => e.value > 0)
        .map((e) => '${e.value}x ${e.key}')
        .toList();
    final selectedMeatStr = meatStrings.join(', ');

    final customizations = {
      'Rice': _selectedRice,
      'Meat': selectedMeatStr,
    };
    
    context.read<LunchProvider>().addToCart(
      product, 
      customizations: customizations,
      customPrice: finalPrice,
    );
    
    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Customized Thali added to cart!'),
        backgroundColor: Color(0xFF4CAF50),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildRadioOption(String title, String selectedValue, Function(String) onChanged) {
    final isSelected = title == selectedValue;
    return GestureDetector(
      onTap: () => onChanged(title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF5F2) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFF15A24) : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected 
              ? [BoxShadow(color: const Color(0xFFF15A24).withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFFF15A24) : Colors.grey.shade400,
                  width: isSelected ? 4 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFFF15A24) : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 2),
              const Icon(Icons.check_circle, color: Color(0xFFF15A24), size: 14),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityOption(String title) {
    final quantity = _meatQuantities[title] ?? 0;
    final isSelected = quantity > 0;
    
    return GestureDetector(
      onTap: () {
        if (quantity == 0) {
          setState(() => _meatQuantities[title] = 1);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF5F2) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFF15A24) : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected 
              ? [BoxShadow(color: const Color(0xFFF15A24).withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFFF15A24) : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isSelected ? const Color(0xFFFFDED4) : Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      if (quantity > 0) {
                        setState(() => _meatQuantities[title] = quantity - 1);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(Icons.remove, size: 14, color: quantity > 0 ? const Color(0xFFF15A24) : Colors.grey),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text('$quantity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.black87 : Colors.grey)),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() => _meatQuantities[title] = quantity + 1);
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.add, size: 14, color: Color(0xFFF15A24)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LunchProvider>();
    final product = provider.products.firstWhere(
      (p) => p['id'] == widget.product['id'],
      orElse: () => widget.product,
    );

    final basePrice = product['discount_price'] ?? product['item_price'] ?? product['price'] ?? 150;
    final finalPrice = _calculateFinalPrice((basePrice as num).toInt());
    final name = product['name']?.toString() ?? 'Khasi Thali';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
        minHeight: MediaQuery.of(context).size.height * 0.25,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Header
                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C1A0E))),
                const SizedBox(height: 2),
                Text('₹$basePrice base price', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFF15A24))),
                const SizedBox(height: 6),
                const Text('Customize your meal according to your preference.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Rice
                    if (_riceOptions.isNotEmpty)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Choose Your Rice', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            const Text('Required • Select One', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            const SizedBox(height: 12),
                            ..._riceOptions.map((rice) => _buildRadioOption(rice, _selectedRice, (val) => setState(() => _selectedRice = val))),
                          ],
                        ),
                      ),
                    if (_riceOptions.isNotEmpty && _meatOptions.isNotEmpty)
                      const SizedBox(width: 12),
                    // Section 2: Meat
                    if (_meatOptions.isNotEmpty)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Choose Your Meat', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            const Text('1 included • +₹20 per extra', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            const SizedBox(height: 12),
                            ..._meatOptions.map((meat) => _buildQuantityOption(meat)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Live Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Order Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      if (_riceOptions.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Rice:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            Text(_selectedRice, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (_meatOptions.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Meat:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            Expanded(
                              child: Text(
                                _meatQuantities.entries.where((e) => e.value > 0).map((e) => '${e.value}x ${e.key}').join(', '), 
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                textAlign: TextAlign.right,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                      ],
                      if (_meatOptions.isEmpty && _riceOptions.isEmpty)
                        const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text('₹$finalPrice', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFF15A24))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          
          // Sticky Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      Text('₹$finalPrice', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C1A0E))),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: InkWell(
                      onTap: () => _addToCart(finalPrice, product),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF57C00), Color(0xFFF15A24)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFFF15A24).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Add Customized Thali',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
