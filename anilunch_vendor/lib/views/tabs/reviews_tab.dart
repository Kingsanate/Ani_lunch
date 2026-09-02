import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReviewsTab extends StatefulWidget {
  final String vendorId;
  const ReviewsTab({super.key, required this.vendorId});

  @override
  State<ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<ReviewsTab> {
  String _selectedRatingFilter = 'all'; // all | 5 | 4 | 3

  final List<Map<String, dynamic>> _sampleReviews = [
    {
      'id': 'rev-1',
      'customer': 'Banbha Syiem',
      'rating': 5.0,
      'time': '2 hours ago',
      'dish': 'Khasi Thali',
      'comment':
          'The beef curry was extremely tender and authentic! The Jadoh and salad complemented it perfectly. Arrived hot and neatly packed.',
      'likes': 4,
      'verified': true,
    },
    {
      'id': 'rev-2',
      'customer': 'Daphisha Marbaniang',
      'rating': 5.0,
      'time': 'Yesterday',
      'dish': 'Khasi Thali',
      'comment':
          'Best lunch in Shillong! Meat portions were generous (3 large pieces) and the spicy chutney was phenomenal.',
      'likes': 7,
      'verified': true,
    },
    {
      'id': 'rev-3',
      'customer': 'Ksanbor Lyngdoh',
      'rating': 4.0,
      'time': '2 days ago',
      'dish': 'Signature Lunch Box',
      'comment':
          'Very flavorful and fresh food. Would love a slightly larger rice portion next time, but overall great quality!',
      'likes': 2,
      'verified': true,
    },
    {
      'id': 'rev-4',
      'customer': 'Iawanbha Tariang',
      'rating': 5.0,
      'time': '3 days ago',
      'dish': 'Khasi Thali',
      'comment':
          'Proper home-style cooking. The meat was cooked with authentic local spices. Fast delivery by the rider too.',
      'likes': 5,
      'verified': true,
    },
    {
      'id': 'rev-5',
      'customer': 'Meban Kharkongor',
      'rating': 4.0,
      'time': '5 days ago',
      'dish': 'Indian Thali',
      'comment':
          'Delicious dal and paneer curry. Loved the fresh packaging. Will definitely order again for office lunch.',
      'likes': 3,
      'verified': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredReviews = _selectedRatingFilter == 'all'
        ? _sampleReviews
        : _sampleReviews
            .where((r) => (r['rating'] as num).toInt().toString() == _selectedRatingFilter)
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Customer Reviews & Feedback',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: false,
      ),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Rating Summary Header Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Container(
                padding: const EdgeInsets.all(16),
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
                child: Row(
                  children: [
                    // Score Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFCD34D)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 24, color: Color(0xFFD97706)),
                              const SizedBox(width: 4),
                              Text(
                                '4.9',
                                style: GoogleFonts.inter(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF92400E),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'out of 5.0',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Rating stats
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Overall Kitchen Rating',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Based on 48 verified customer orders',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildMiniBadge(Icons.thumb_up_rounded, '98% Positive', const Color(0xFF16A34A), const Color(0xFFF0FDF4)),
                              const SizedBox(width: 8),
                              _buildMiniBadge(Icons.restaurant_rounded, 'Top Rated', const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Rating Filter Chips - Responsive Row for Mobile
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: Row(
                children: [
                  _buildFilterPill('all', 'All', 48, hasStar: false),
                  const SizedBox(width: 6),
                  _buildFilterPill('5', '5', 42, hasStar: true),
                  const SizedBox(width: 6),
                  _buildFilterPill('4', '4', 5, hasStar: true),
                  const SizedBox(width: 6),
                  _buildFilterPill('3', '≤3', 1, hasStar: true),
                ],
              ),
            ),
          ),

          // Reviews List
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final review = filteredReviews[index];
                  return _buildReviewCard(review);
                },
                childCount: filteredReviews.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(IconData icon, String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String key, String label, int count, {bool hasStar = false}) {
    final isSelected = _selectedRatingFilter == key;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedRatingFilter = key),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4, offset: const Offset(0, 2))]
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 2, offset: const Offset(0, 1))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasStar) ...[
                Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: isSelected ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                ),
                const SizedBox(width: 2),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                ),
              ),
              const SizedBox(width: 3),
              Text(
                '($count)',
                style: GoogleFonts.robotoMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final customer = review['customer'] as String;
    final rating = (review['rating'] as num).toDouble();
    final time = review['time'] as String;
    final dish = review['dish'] as String;
    final comment = review['comment'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Rating & Time
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: const Color(0xFFF15A24).withValues(alpha: 0.12),
                child: Text(
                  customer.isNotEmpty ? customer[0].toUpperCase() : 'C',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: const Color(0xFFF15A24),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          customer,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded, size: 13, color: Color(0xFF2563EB)),
                      ],
                    ),
                    Text(
                      time,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Star Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFD97706)),
                    const SizedBox(width: 3),
                    Text(
                      rating.toStringAsFixed(1),
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Dish tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.restaurant_menu_rounded, size: 12, color: Color(0xFF475569)),
                const SizedBox(width: 5),
                Text(
                  'Ordered: $dish',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Comment
          Text(
            comment,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              height: 1.45,
              color: const Color(0xFF1E293B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
