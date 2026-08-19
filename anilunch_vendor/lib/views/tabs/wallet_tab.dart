import 'package:flutter/material.dart';
import '../../vendor_theme.dart';
import '../../services/supabase_service.dart';

class WalletTab extends StatefulWidget {
  final String vendorId;
  const WalletTab({super.key, required this.vendorId});

  @override
  State<WalletTab> createState() => _WalletTabState();
}

class _WalletTabState extends State<WalletTab> {
  bool _isLoading = true;
  double _totalSales = 0.0;
  // Mocking total withdrawals for now since we don't have a table for it yet
  final double _totalWithdrawals = 1200.00; 

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final sales = await SupabaseService.getTotalSales(widget.vendorId);
    
    if (mounted) {
      setState(() {
        _totalSales = sales;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VendorTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: VendorTheme.textDark, size: 20),
          onPressed: () {},
        ),
        title: Text(
          'Monthly Account Statement',
          style: VendorTheme.headingSmall,
        ),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: VendorTheme.primary))
        : RefreshIndicator(
            onRefresh: _loadData,
            color: VendorTheme.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Controls Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: VendorTheme.cardBg,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Oct 1 - Oct 31, 2023', // Mock date
                              style: VendorTheme.bodySmall.copyWith(
                                color: VendorTheme.textDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.calendar_today_outlined, size: 14, color: VendorTheme.textMuted),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: VendorTheme.primary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: VendorTheme.softShadow,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Download PDF',
                              style: VendorTheme.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.download_outlined, size: 16, color: Colors.white),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Summary Cards
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: VendorTheme.cardDecoration(),
                    child: Column(
                      children: [
                        Text(
                          'Total Sales',
                          style: VendorTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '+₹${_totalSales.toStringAsFixed(2)}',
                          style: VendorTheme.headingLarge.copyWith(
                            color: VendorTheme.primary,
                            fontSize: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: VendorTheme.cardDecoration(),
                    child: Column(
                      children: [
                        Text(
                          'Total Withdrawals',
                          style: VendorTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '-₹${_totalWithdrawals.toStringAsFixed(2)}',
                          style: VendorTheme.headingLarge.copyWith(
                            fontSize: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Withdraw Button
                  InkWell(
                    onTap: () {
                      // Handle withdraw
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Ink(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: VendorTheme.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: VendorTheme.softShadow,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.account_balance, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Withdraw Funds',
                            style: VendorTheme.headingSmall.copyWith(color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_outward, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Transactions List (Mocked for now since backend lacks table)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Recent Transactions', style: VendorTheme.headingMedium),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTransactionItem(
                    icon: Icons.storefront,
                    title: 'Sales',
                    subtitle: 'Order #8942',
                    time: '2:45 PM',
                    amount: '+₹45.50',
                    isPositive: true,
                  ),
                  _buildTransactionItem(
                    icon: Icons.payments_outlined,
                    title: 'Fee',
                    subtitle: 'Platform Fee',
                    time: '1:15 PM',
                    amount: '-₹2.00',
                    isPositive: false,
                  ),
                  _buildTransactionItem(
                    icon: Icons.account_balance,
                    title: 'Withdrawal',
                    subtitle: 'Bank Transfer',
                    time: '9:00 AM',
                    amount: '-₹1,200.00',
                    isPositive: false,
                  ),
                  
                  const SizedBox(height: 32), // bottom padding
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildTransactionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required String amount,
    required bool isPositive,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16),
      decoration: VendorTheme.cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: VendorTheme.greyBg,
            child: Icon(icon, color: VendorTheme.textDark, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: VendorTheme.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      subtitle,
                      style: VendorTheme.bodySmall,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      time,
                      style: VendorTheme.bodySmall.copyWith(
                        color: VendorTheme.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: VendorTheme.headingSmall.copyWith(
              color: isPositive ? VendorTheme.primary : VendorTheme.textDark,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
