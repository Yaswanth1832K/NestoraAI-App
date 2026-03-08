import 'package:flutter/material.dart';
import 'package:house_rental/core/theme/app_colors.dart';

class ServiceCategorySection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool isDark;

  const ServiceCategorySection({
    super.key,
    required this.title,
    required this.children,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppColors.s24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              Text(
                'View All',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isSmall = screenWidth < 360;
            final listHeight = isSmall ? 300.0 : 340.0;
            
            return SizedBox(
              height: listHeight,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppColors.s24),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: children.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) => children[index],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
