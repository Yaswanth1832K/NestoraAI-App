import 'package:flutter/material.dart';
import 'package:house_rental/core/widgets/shimmer_container.dart';

/// Skeleton shimmer placeholder for listing cards. Used during loading states.
class ListingCardSkeleton extends StatelessWidget {
  final double? width;

  const ListingCardSkeleton({super.key, this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 280,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Skeleton
          const ShimmerContainer(
            height: 250,
            width: double.infinity,
            borderRadius: 16,
          ),
          const SizedBox(height: 12),
          // Price Skeleton
          const ShimmerContainer(
            height: 24,
            width: 80,
            borderRadius: 4,
          ),
          const SizedBox(height: 8),
          // Title Skeleton
          const ShimmerContainer(
            height: 18,
            width: double.infinity,
            borderRadius: 4,
          ),
          const SizedBox(height: 8),
          // Location Skeleton
          const ShimmerContainer(
            height: 14,
            width: 120,
            borderRadius: 4,
          ),
        ],
      ),
    );
  }
}
