import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class NestoraImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool usePlaceholder;
  final String? semanticLabel;
  final bool isCircle;

  const NestoraImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.usePlaceholder = true,
    this.semanticLabel,
    this.isCircle = false,
  });

  static const List<String> _fallbackPool = [
    'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=1200&q=80',
    'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=1200&q=80',
    'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=1200&q=80',
    'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=1200&q=80',
    'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=1200&q=80',
  ];

  String _getDeterministicFallback(String seed) {
    final index = seed.hashCode.abs() % _fallbackPool.length;
    return _fallbackPool[index];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl.isEmpty ? _getDeterministicFallback(imageUrl) : imageUrl,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 500),
      fadeOutDuration: const Duration(milliseconds: 300),
      placeholder: usePlaceholder
          ? (context, url) => Shimmer.fromColors(
                baseColor: isDark ? const Color(0xFF17171A) : const Color(0xFFE2E8F0),
                highlightColor: isDark ? const Color(0xFF1C1C21) : const Color(0xFFF1F5F9),
                period: const Duration(milliseconds: 1500),
                child: Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: borderRadius ?? BorderRadius.zero,
                  ),
                ),
              )
          : null,
      errorWidget: (context, url, error) {
        // Deterministic fallback based on the failed URL
        final fallbackUrl = _getDeterministicFallback(url);
        return CachedNetworkImage(
          imageUrl: fallbackUrl,
          width: width,
          height: height,
          fit: fit,
          placeholder: (context, url) => Container(color: isDark ? Colors.black12 : Colors.grey[100]),
          errorWidget: (context, url, error) => Container(
            color: isDark ? Colors.grey[900] : Colors.grey[200],
            child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
          ),
        );
      },
    );

    if (isCircle) {
      return Container(
        width: width,
        height: height,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        clipBehavior: Clip.antiAlias,
        child: imageWidget,
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
