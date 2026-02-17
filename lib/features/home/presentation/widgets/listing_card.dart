import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';
import 'package:house_rental/features/listings/presentation/providers/favorites_notifier.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/listings/presentation/pages/listing_details_page.dart';
import 'package:house_rental/main.dart';
import 'package:house_rental/core/theme/theme_provider.dart';

class ListingCard extends ConsumerStatefulWidget {
  final ListingEntity listing;
  final bool isCompact;
  final bool isVerticalFeed;
  final EdgeInsetsGeometry? margin;
  final bool showFavoriteButton;
  final Widget? actionButton;
  final VoidCallback? onTap;

  const ListingCard({
    super.key,
    required this.listing,
    this.isCompact = false,
    this.isVerticalFeed = false,
    this.margin,
    this.showFavoriteButton = true,
    this.actionButton,
    this.onTap,
  });

  @override
  ConsumerState<ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends ConsumerState<ListingCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesNotifierProvider);
    final isFavorite = favorites.value?.contains(widget.listing.id) ?? false;
    
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF222222);
    final subTextColor = isDark ? Colors.grey.shade400 : const Color(0xFF717171);

    return GestureDetector(
      onTap: widget.onTap ?? () {
        rootNavigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (_) => ListingDetailsPage(listing: widget.listing),
          ),
        );
      },
      child: Container(
        margin: widget.margin ?? const EdgeInsets.only(bottom: 24),
        color: Colors.transparent, // Flat design
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image and Favorite Button
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 1.05, // 20:19 aspect ratio (standard listing)
                    child: Image.network(
                      widget.listing.allImages.isNotEmpty ? widget.listing.allImages.first : 'https://placeholder.com/400x300',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                if (widget.actionButton != null)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: widget.actionButton!,
                  )
                else if (widget.showFavoriteButton)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: _isToggling ? null : () => _toggleFavorite(context),
                      child: AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: isFavorite ? const Color(0xFFFF385C) : Colors.white, // Airbnb Red or White
                              size: 26,
                              shadows: const [
                                Shadow(blurRadius: 2, color: Colors.black26),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                Positioned(
                   top: 12,
                   left: 12,
                   child: Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     decoration: const BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.all(Radius.circular(4)),
                     ),
                     child: const Text(
                       'Guest favourite',
                       style: TextStyle(
                         fontSize: 12,
                         fontWeight: FontWeight.bold,
                         color: Colors.black,
                       ),
                     ),
                   ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Text Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.listing.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.listing.city} • ${widget.listing.bedrooms} Beds', // simplified location
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Mar 1 - 6', // Date range placeholder
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '£${widget.listing.price.toInt()}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            TextSpan(
                              text: ' night',
                              style: TextStyle(
                                fontSize: 16,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Rating
                if (widget.listing.averageRating > 0)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.star, size: 14, color: textColor),
                      const SizedBox(width: 4),
                      Text(
                        widget.listing.averageRating.toStringAsFixed(1),
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w400,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(BuildContext context) async {
    final authState = ref.read(authStateProvider);
    if (authState.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to save favorites')),
      );
      return;
    }

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Trigger animation
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // Set loading state
    setState(() {
      _isToggling = true;
    });

    // Call toggle
    final result = await ref.read(favoritesNotifierProvider.notifier).toggleFavorite(widget.listing);

    // Clear loading state
    if (mounted) {
      setState(() {
        _isToggling = false;
      });

      // Handle errors
      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update favorites: ${failure.message}'),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () => _toggleFavorite(context),
              ),
            ),
          );
        },
        (_) {
          // Success - no need to show anything, the UI updates automatically
        },
      );
    }
  }
}
