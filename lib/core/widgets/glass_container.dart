import 'package:flutter/material.dart';
import 'package:house_rental/core/theme/app_colors.dart';

class GlassContainer extends StatelessWidget {
  final double? width;
  final double? height;
  final Widget child;
  final double blur;
  final double opacity;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Border? border;

  const GlassContainer({
    super.key,
    this.width,
    this.height,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.color,
    this.borderRadius,
    this.padding,
    this.margin,
    this.border,
  });

  /// Factory constructor for standard glass look that adapts to theme
  factory GlassContainer.standard({
    Key? key,
    required Widget child,
    required BuildContext context,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = 16,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassContainer(
      key: key,
      width: width,
      height: height,
      blur: 20, // Increased blur for a more premium glass effect
      opacity: isDark ? 0.8 : 0.4, // Increased opacity in dark mode for better visibility
      color: isDark ? AppColors.surfaceDark : Colors.white, // Use dark surface color in dark mode
      padding: padding,
      margin: margin,
      borderRadius: BorderRadius.circular(borderRadius),
      child: child,
    );
  }

  double _safe(double? val, [double def = 0.0]) {
    if (val == null || val.isNaN || val.isInfinite) return def;
    return val;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = color ?? (isDark ? AppColors.surfaceDark : Colors.white);
    final safeRadius = borderRadius ?? BorderRadius.circular(20);

    return Container(
      width: width != null ? _safe(width) : null,
      height: height != null ? _safe(height) : null,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(_safe(opacity, 0.1)),
        borderRadius: safeRadius,
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.1 : 0.05),
          width: 0.5,
        ),
        boxShadow: AppColors.softShadow,
      ),
      child: child,
    );
  }
}
