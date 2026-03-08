import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:house_rental/core/theme/app_colors.dart';
import 'package:house_rental/core/theme/app_spacing.dart';

class NestoraEmptyState extends StatelessWidget {
  final String title;
  final String description;
  final String? lottieAsset;
  final IconData? icon;
  final VoidCallback? onActionPressed;
  final String? actionLabel;

  const NestoraEmptyState({
    super.key,
    required this.title,
    required this.description,
    this.lottieAsset,
    this.icon,
    this.onActionPressed,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (lottieAsset != null)
                Lottie.asset(
                  lottieAsset!,
                  height: 200,
                  repeat: true,
                )
              else if (icon != null)
                Icon(
                  icon,
                  size: 80,
                  color: isDark ? Colors.white12 : Colors.black12,
                )
              else
                const Icon(
                  Icons.search_off_rounded,
                  size: 80,
                  color: Colors.grey,
                ),
              AppSpacing.v4,
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  letterSpacing: -0.5,
                ),
              ),
              AppSpacing.v8,
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  height: 1.5,
                ),
              ),
              if (onActionPressed != null && actionLabel != null) ...[
                AppSpacing.v32,
                ElevatedButton(
                  onPressed: onActionPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(actionLabel!, style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
