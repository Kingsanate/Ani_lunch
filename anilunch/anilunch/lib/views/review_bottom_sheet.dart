import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewBottomSheet extends StatefulWidget {
  final Map<String, dynamic> item;
  const ReviewBottomSheet({Key? key, required this.item}) : super(key: key);

  @override
  State<ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<ReviewBottomSheet> {
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to leave a review.')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userName = user.userMetadata?['full_name'] ?? user.email?.split('@')[0] ?? 'Anonymous';
      final productId = widget.item['product_id']?.toString() ?? widget.item['id']?.toString() ?? '';

      await Supabase.instance.client.from('product_reviews').insert({
        'product_id': productId,
        'user_id': user.id,
        'user_name': userName,
        'rating': _rating,
        'comment': _commentController.text.trim(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review submitted successfully!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit review: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemName = widget.item['name'] ?? 'Product';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Review $itemName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C1A0E))),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('How was the food?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: const Color(0xFFFFB800),
                  size: 40,
                ),
                onPressed: () => setState(() => _rating = index + 1),
              );
            }),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _commentController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Share your thoughts about this dish...',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFF15A24)),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF15A24),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Submit Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
