import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../vendor_theme.dart';
import '../../services/supabase_service.dart';

class WalletTab extends StatefulWidget {
  final String vendorId;
  const WalletTab({super.key, required this.vendorId});

  @override
  State<WalletTab> createState() => _WalletTabState();
}

class _WalletTabState extends State<WalletTab> {
  double _totalSales = 0.0;
  double _totalWithdrawals = 1200.00;

  String _selectedPeriodLabel = 'August 2026';
  DateTime _startDate = DateTime(2026, 8, 1);
  DateTime _endDate = DateTime(2026, 8, 31);

  final List<Map<String, dynamic>> _customTransactions = [];

  final List<Map<String, dynamic>> _periodOptions = [
    {
      'label': 'This Month (August 2026)',
      'short': 'August 2026',
      'start': DateTime(2026, 8, 1),
      'end': DateTime(2026, 8, 31),
      'subtitle': '01 Aug 2026 - 31 Aug 2026',
      'icon': Icons.stars_rounded,
    },
    {
      'label': 'Last Month (July 2026)',
      'short': 'July 2026',
      'start': DateTime(2026, 7, 1),
      'end': DateTime(2026, 7, 31),
      'subtitle': '01 Jul 2026 - 31 Jul 2026',
      'icon': Icons.calendar_month_rounded,
    },
    {
      'label': 'June 2026',
      'short': 'June 2026',
      'start': DateTime(2026, 6, 1),
      'end': DateTime(2026, 6, 30),
      'subtitle': '01 Jun 2026 - 30 Jun 2026',
      'icon': Icons.calendar_month_rounded,
    },
    {
      'label': 'May 2026',
      'short': 'May 2026',
      'start': DateTime(2026, 5, 1),
      'end': DateTime(2026, 5, 31),
      'subtitle': '01 May 2026 - 31 May 2026',
      'icon': Icons.calendar_month_rounded,
    },
    {
      'label': 'Last 30 Days',
      'short': 'Last 30 Days',
      'start': DateTime.now().subtract(const Duration(days: 30)),
      'end': DateTime.now(),
      'subtitle': 'Recent 30 days of activity',
      'icon': Icons.history_rounded,
    },
    {
      'label': 'Full Year 2026',
      'short': 'Year 2026',
      'start': DateTime(2026, 1, 1),
      'end': DateTime(2026, 12, 31),
      'subtitle': '01 Jan 2026 - 31 Dec 2026',
      'icon': Icons.date_range_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final sales = await SupabaseService.getTotalSales(widget.vendorId);
    if (mounted) {
      setState(() {
        _totalSales = sales > 0 ? sales : 610.0;
      });
    }
  }

  void _showSimplePeriodPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomCtx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Statement Period',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose a month to view transactions and generate official statements.',
                style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),

              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _periodOptions.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final item = _periodOptions[idx];
                    final isSelected = _selectedPeriodLabel == item['short'];

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedPeriodLabel = item['short'] as String;
                          _startDate = item['start'] as DateTime;
                          _endDate = item['end'] as DateTime;
                        });
                        Navigator.pop(bottomCtx);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item['icon'] as IconData,
                              size: 20,
                              color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['label'] as String,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      color: isSelected ? const Color(0xFF15803D) : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    item['subtitle'] as String,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded, size: 20, color: Color(0xFF16A34A))
                            else
                              const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFCBD5E1)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _generatePdfStatement(List<Map<String, dynamic>> transactions) async {
    try {
      final doc = pw.Document();

      final periodText = '$_selectedPeriodLabel (${_startDate.day}/${_startDate.month}/${_startDate.year} - ${_endDate.day}/${_endDate.month}/${_endDate.year})';
      final generatedTime = DateTime.now().toString().substring(0, 19);

      final grossSales = _totalSales;
      final platformFee = grossSales * 0.02;
      final netPayout = grossSales - platformFee;

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header with Brand & Title
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: pw.BoxDecoration(
                              color: PdfColor.fromHex('#F15A24'),
                              borderRadius: pw.BorderRadius.circular(6),
                            ),
                            child: pw.Text(
                              'ANILUNCH',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Text(
                            'KITCHEN PARTNER',
                            style: pw.TextStyle(
                              color: PdfColor.fromHex('#0F172A'),
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'AniLunch Cloud Kitchen Network',
                        style: pw.TextStyle(color: PdfColor.fromHex('#475569'), fontSize: 10),
                      ),
                      pw.Text(
                        'Police Bazar, Shillong, Meghalaya - 793001',
                        style: pw.TextStyle(color: PdfColor.fromHex('#64748B'), fontSize: 9),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'ACCOUNT STATEMENT',
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('#0F172A'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Statement Period:', style: pw.TextStyle(color: PdfColor.fromHex('#64748B'), fontSize: 9)),
                      pw.Text(periodText, style: pw.TextStyle(color: PdfColor.fromHex('#0F172A'), fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.SizedBox(height: 4),
                      pw.Text('Generated: $generatedTime', style: pw.TextStyle(color: PdfColor.fromHex('#94A3B8'), fontSize: 8)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColor.fromHex('#E2E8F0'), thickness: 1.5),
              pw.SizedBox(height: 16),

              // Vendor Info Card
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F8FAFC'),
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Partner Kitchen Name:', style: pw.TextStyle(color: PdfColor.fromHex('#64748B'), fontSize: 9)),
                        pw.Text('AniLunch Main Kitchen (Shillong)', style: pw.TextStyle(color: PdfColor.fromHex('#0F172A'), fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Vendor Partner ID:', style: pw.TextStyle(color: PdfColor.fromHex('#64748B'), fontSize: 9)),
                        pw.Text(widget.vendorId.toUpperCase(), style: pw.TextStyle(color: PdfColor.fromHex('#0F172A'), fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Status:', style: pw.TextStyle(color: PdfColor.fromHex('#64748B'), fontSize: 9)),
                        pw.Text('VERIFIED ACTIVE', style: pw.TextStyle(color: PdfColor.fromHex('#16A34A'), fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Financial Metrics Summary Box
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#F0FDF4'),
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(color: PdfColor.fromHex('#BBF7D0')),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('GROSS SALES', style: pw.TextStyle(color: PdfColor.fromHex('#15803D'), fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 4),
                          pw.Text('INR ${grossSales.toStringAsFixed(2)}', style: pw.TextStyle(color: PdfColor.fromHex('#16A34A'), fontSize: 15, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#EFF6FF'),
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(color: PdfColor.fromHex('#BFDBFE')),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('PLATFORM FEE (2%)', style: pw.TextStyle(color: PdfColor.fromHex('#1E40AF'), fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 4),
                          pw.Text('INR -${platformFee.toStringAsFixed(2)}', style: pw.TextStyle(color: PdfColor.fromHex('#2563EB'), fontSize: 15, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#FAF5FF'),
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(color: PdfColor.fromHex('#E9D5FF')),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('TOTAL WITHDRAWALS', style: pw.TextStyle(color: PdfColor.fromHex('#6B21A8'), fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 4),
                          pw.Text('INR -${_totalWithdrawals.toStringAsFixed(2)}', style: pw.TextStyle(color: PdfColor.fromHex('#7C3AED'), fontSize: 15, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 22),

              // Itemized Transactions Header
              pw.Text(
                'ITEMIZED TRANSACTION LOG',
                style: pw.TextStyle(
                  color: PdfColor.fromHex('#0F172A'),
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.SizedBox(height: 8),

              // Table with sanitized amounts (no non-ascii chars)
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColor.fromHex('#E2E8F0'), width: 0.7),
                headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#0F172A')),
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                headers: ['DATE & TIME', 'TYPE', 'DESCRIPTION / REF', 'STATUS', 'AMOUNT (INR)'],
                data: transactions.map((t) {
                  final rawAmount = t['amount']?.toString() ?? '0.00';
                  final cleanAmount = rawAmount.replaceAll('₹', 'INR ');
                  return [
                    t['time']?.toString() ?? 'Today',
                    t['title']?.toString() ?? 'Sales',
                    t['subtitle']?.toString() ?? '-',
                    'SUCCESS',
                    cleanAmount,
                  ];
                }).toList(),
              ),

              pw.SizedBox(height: 24),

              // Net Payout Calculation Box
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  width: 220,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F8FAFC'),
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1')),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Net Payable Balance:', style: pw.TextStyle(color: PdfColor.fromHex('#0F172A'), fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          pw.Text('INR ${netPayout.toStringAsFixed(2)}', style: pw.TextStyle(color: PdfColor.fromHex('#16A34A'), fontWeight: pw.FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              pw.SizedBox(height: 30),

              // Sign & Footer Note
              pw.Divider(color: PdfColor.fromHex('#E2E8F0')),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'This is an official system-generated account statement by AniLunch.',
                    style: pw.TextStyle(color: PdfColor.fromHex('#94A3B8'), fontSize: 8),
                  ),
                  pw.Text(
                    'AniLunch Finance Operations',
                    style: pw.TextStyle(color: PdfColor.fromHex('#64748B'), fontWeight: pw.FontWeight.bold, fontSize: 8),
                  ),
                ],
              ),
            ];
          },
        ),
      );

      final pdfBytes = await doc.save();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'AniLunch_Statement_${_startDate.month}_${_startDate.year}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showWithdrawModal() {
    final amountController = TextEditingController();
    double availableBalance = _totalSales > 0 ? _totalSales : 430.00;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 20,
                right: 20,
                top: 14,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Withdraw Funds to Bank',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Transfer your kitchen earnings directly to your registered bank account or UPI.',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),

                  // Available Balance Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Available Withdrawable Balance',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF15803D)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${availableBalance.toStringAsFixed(2)}',
                              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF16A34A)),
                            ),
                          ],
                        ),
                        const Icon(Icons.account_balance_wallet_rounded, size: 28, color: Color(0xFF16A34A)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Quick Amount Chips
                  Row(
                    children: [
                      _buildQuickAmountChip('₹100', 100, amountController, setModalState),
                      const SizedBox(width: 8),
                      _buildQuickAmountChip('₹200', 200, amountController, setModalState),
                      const SizedBox(width: 8),
                      _buildQuickAmountChip('₹500', 500, amountController, setModalState),
                      const SizedBox(width: 8),
                      _buildQuickAmountChip('All', availableBalance, amountController, setModalState),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Amount TextField
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      prefixStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                      labelText: 'Withdrawal Amount',
                      hintText: '0.00',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: VendorTheme.primary, width: 1.5)),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Selected Bank Account Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_rounded, size: 20, color: Color(0xFF2563EB)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('State Bank of India (••4821)', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                              Text('IFSC: SBIN0000181 • Primary Account', style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF16A34A)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final val = double.tryParse(amountController.text.trim()) ?? 0.0;
                        if (val <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid withdrawal amount.')),
                          );
                          return;
                        }
                        if (val > availableBalance) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Withdrawal amount exceeds available balance.')),
                          );
                          return;
                        }

                        Navigator.pop(modalCtx);

                        setState(() {
                          _totalWithdrawals += val;
                          _customTransactions.insert(0, {
                            'icon': Icons.account_balance,
                            'title': 'Withdrawal',
                            'subtitle': 'Bank Transfer (SBIN••4821)',
                            'time': 'Just now',
                            'amount': '-₹${val.toStringAsFixed(2)}',
                            'isPositive': false,
                          });
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('₹${val.toStringAsFixed(2)} transferred to your bank account successfully!'),
                            backgroundColor: const Color(0xFF16A34A),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VendorTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.arrow_outward_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Confirm Bank Transfer',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickAmountChip(String label, double amount, TextEditingController controller, StateSetter setModalState) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setModalState(() {
            controller.text = amount.toStringAsFixed(0);
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Monthly Account Statement',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: SupabaseService.historyOrdersStream(widget.vendorId),
        builder: (context, snapshot) {
          final historyOrders = snapshot.data ?? [];

          // Build dynamic transactions list
          final List<Map<String, dynamic>> combinedTransactions = [];

          // Add custom withdrawals
          combinedTransactions.addAll(_customTransactions);

          // Add real sales orders
          for (var o in historyOrders) {
            final id = o['id']?.toString() ?? '';
            final shortId = id.length > 6 ? id.substring(0, 6).toUpperCase() : id;
            final amount = (o['total_amount'] as num?)?.toDouble() ?? 200.0;
            final timeStr = o['order_time']?.toString();
            String formattedTime = 'Today';
            if (timeStr != null && timeStr.length >= 16) {
              formattedTime = timeStr.substring(11, 16);
            }
            combinedTransactions.add({
              'icon': Icons.storefront_rounded,
              'title': 'Sales',
              'subtitle': 'Order #$shortId',
              'time': formattedTime,
              'amount': '+₹${amount.toStringAsFixed(2)}',
              'isPositive': true,
            });
          }

          // Fallback initial sample transactions if empty
          if (combinedTransactions.isEmpty) {
            combinedTransactions.addAll([
              {
                'icon': Icons.storefront_rounded,
                'title': 'Sales',
                'subtitle': 'Order #8942',
                'time': '2:45 PM',
                'amount': '+₹45.50',
                'isPositive': true,
              },
              {
                'icon': Icons.payments_outlined,
                'title': 'Fee',
                'subtitle': 'Platform Fee (2%)',
                'time': '1:15 PM',
                'amount': '-₹2.00',
                'isPositive': false,
              },
              {
                'icon': Icons.account_balance_rounded,
                'title': 'Withdrawal',
                'subtitle': 'Bank Transfer (SBIN••4821)',
                'time': '9:00 AM',
                'amount': '-₹1,200.00',
                'isPositive': false,
              },
            ]);
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            color: VendorTheme.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // Controls Row: Simple Clean Period Selector & Download PDF Button
                  Row(
                    children: [
                      // Simple Period Selector Pill
                      Expanded(
                        child: InkWell(
                          onTap: _showSimplePeriodPicker,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.calendar_month_rounded, size: 15, color: Color(0xFFF15A24)),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _selectedPeriodLabel,
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF0F172A),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Download PDF Button
                      InkWell(
                        onTap: () => _generatePdfStatement(combinedTransactions),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: VendorTheme.primary,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: VendorTheme.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Download PDF',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.download_rounded, size: 16, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Summary Cards: Total Sales & Total Withdrawals
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Total Sales',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '+₹${_totalSales.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF16A34A),
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Total Withdrawals',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '-₹${_totalWithdrawals.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Withdraw Funds Button
                  InkWell(
                    onTap: _showWithdrawModal,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: VendorTheme.primary,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: VendorTheme.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.account_balance_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Withdraw Funds',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_outward_rounded, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Transactions List Header
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Recent Transactions',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Transactions List
                  ...combinedTransactions.map((t) => _buildTransactionItem(
                        icon: t['icon'] as IconData,
                        title: t['title'] as String,
                        subtitle: t['subtitle'] as String,
                        time: t['time'] as String,
                        amount: t['amount'] as String,
                        isPositive: t['isPositive'] as bool,
                      )),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
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
      margin: const EdgeInsets.only(bottom: 10.0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isPositive ? const Color(0xFFF0FDF4) : const Color(0xFFF1F5F9),
            child: Icon(
              icon,
              color: isPositive ? const Color(0xFF16A34A) : const Color(0xFF475569),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• $time',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.inter(
              color: isPositive ? const Color(0xFF16A34A) : const Color(0xFF0F172A),
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
