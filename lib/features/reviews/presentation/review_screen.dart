import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:house_rental/core/widgets/glass_container.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/reviews/domain/entities/review_entity.dart';
import 'package:house_rental/features/reviews/presentation/providers/review_providers.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final String listingId;
  final String listingTitle;
  final String ownerId;
  final String bookingId;

  const ReviewScreen({
    super.key,
    required this.listingId,
    required this.listingTitle,
    required this.ownerId,
    required this.bookingId,
  });

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final review = ReviewEntity(
        id: Uuid().v4(),
        listingId: widget.listingId,
        listingTitle: widget.listingTitle,
        ownerId: widget.ownerId,
        reviewerId: user.uid,
        reviewerName: user.displayName ?? 'Anonymous',
        bookingId: widget.bookingId,
        rating: _rating.toDouble(),
        comment: _commentController.text.trim(),
        createdAt: DateTime.now(),
      );

      final result = await ref.read(addReviewUseCaseProvider)(review);

      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        result.fold(
          (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Failed to submit review: ${failure.message}"),
                backgroundColor: colorScheme.error,
              ),
            );
          },
          (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Thank you for your review!"),
                backgroundColor: colorScheme.primary,
              ),
            );
            Navigator.pop(context);
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Write a Review',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: -1),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "How was your stay at ${widget.listingTitle}?",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: 12),
            Text(
              "Your authentic feedback helps the community find their perfect home.",
              style: TextStyle(
                color: Theme.of(context).hintColor.withOpacity(0.6),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 40),
            GlassContainer.standard(
              context: context,
              padding: const EdgeInsets.all(24),
              borderRadius: 30,
              child: Column(
                children: [
                  const Text(
                    "Overall Experience",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final isSelected = index < _rating;
                      return GestureDetector(
                        onTap: () => setState(() => _rating = index + 1),
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 200),
                          scale: isSelected ? 1.1 : 1.0,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: isSelected ? Colors.amber : Theme.of(context).hintColor.withOpacity(0.2),
                              size: 44,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getRatingText(_rating).toUpperCase(),
                    style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              "Share your thoughts",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: 16),
            GlassContainer.standard(
              context: context,
              padding: EdgeInsets.zero,
              borderRadius: 24,
              child: TextField(
                controller: _commentController,
                maxLines: 5,
                style: const TextStyle(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: "What did you love about the place?",
                  hintStyle: TextStyle(color: Theme.of(context).hintColor.withOpacity(0.4)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Submit Review", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1: return "Poor";
      case 2: return "Fair";
      case 3: return "Good";
      case 4: return "Very Good";
      case 5: return "Excellent";
      default: return "";
    }
  }
}
