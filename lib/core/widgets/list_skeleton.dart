import 'package:flutter/material.dart';
import 'package:house_rental/core/widgets/shimmer_container.dart';
import 'package:house_rental/core/theme/app_spacing.dart';

class ListSkeleton extends StatelessWidget {
  final int itemCount;
  final bool hasAvatar;
  final EdgeInsetsGeometry? padding;

  const ListSkeleton({
    super.key,
    this.itemCount = 6,
    this.hasAvatar = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding ?? const EdgeInsets.all(AppSpacing.s24),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s24),
          child: Row(
            children: [
              if (hasAvatar)
                const ShimmerContainer(
                  width: 56,
                  height: 56,
                  borderRadius: 28,
                ),
              const SizedBox(width: AppSpacing.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerContainer(
                      width: double.infinity,
                      height: 16,
                      borderRadius: 4,
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    ShimmerContainer(
                      width: MediaQuery.of(context).size.width * 0.5,
                      height: 12,
                      borderRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
