import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';
import 'package:house_rental/features/listings/presentation/providers/favorites_notifier.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/listings/presentation/pages/listing_details_page.dart';
import 'package:house_rental/main.dart';

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
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

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
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentImageIndex && mounted) setState(() => _currentImageIndex = page);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesNotifierProvider);
    final isFavorite = favorites.value?.contains(widget.listing.id) ?? false;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // In the new precise UI, the feed is white background, dark text (or dark background, light text)
    final textColor = isDark ? Colors.white : const Color(0xFF222222);
    final subTextColor = isDark ? Colors.grey.shade400 : const Color(0xFF717171);

    // If used in a horizontal scroll (what we want for the redesign), we need to enforce a width. 
    // We'll use 280 for average screen sizes, allowing part of the next card to peek out.
    final cardWidth = widget.isVerticalFeed ? null : 280.0;

    return GestureDetector(
      onTap: widget.onTap ?? () {
        rootNavigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (_) => ListingDetailsPage(listing: widget.listing),
          ),
        );
      },
      child: Container(
        width: cardWidth,
        margin: widget.margin ?? const EdgeInsets.only(right: 16),
        color: Colors.transparent, // Flat design
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Swipeable image gallery and Favorite Button
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: _buildImageGallery(isDark),
                  ),
                ),
                // Gradient overlay for better top icon/badge visibility
                Positioned(
                  top: 0, left: 0, right: 0, height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(0.3), Colors.transparent],
                      ),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                    ),
                  ),
                ),
                if (widget.actionButton != null)
                  Positioned(
                    top: 12,
                    right: 12,
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
                              size: 28,
                              shadows: const [
                                Shadow(blurRadius: 4, color: Colors.black45),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                if (widget.listing.allImages.length > 1)
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.listing.allImages.length.clamp(0, 10),
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 4,
                          width: _currentImageIndex == i ? 12 : 4,
                          decoration: BoxDecoration(
                            color: _currentImageIndex == i
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                // "Guest favourite" badge
                Positioned(
                   top: 12,
                   left: 12,
                   child: Container(
                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(20),
                       boxShadow: const [
                         BoxShadow(blurRadius: 4, color: Colors.black26),
                       ],
                     ),
                     child: const Text(
                       'Guest favourite',
                       style: TextStyle(
                         fontSize: 12,
                         fontWeight: FontWeight.w600,
                         color: Colors.black,
                         fontFamily: 'Inter',
                       ),
                     ),
                   ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Text Details
            Text(
              widget.listing.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '₹${widget.listing.price.toInt()}/mo',
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.listing.averageRating > 0)
                  Row(
                    children: [
                      Text(' • ', style: TextStyle(color: subTextColor, fontSize: 14)),
                      Icon(Icons.star_rounded, size: 16, color: textColor),
                      const SizedBox(width: 2),
                      Text(
                        widget.listing.averageRating.toStringAsFixed(1),
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
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

  Widget _buildImageGallery(bool isDark) {
    final urls = widget.listing.allImages;
    if (urls.isEmpty) {
      return Container(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
        child: Icon(Icons.home_rounded, size: 48, color: Colors.grey.shade500),
      );
    }
    if (urls.length == 1) {
      return CachedNetworkImage(
        imageUrl: urls.first,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (_, __, ___) => Container(
          color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
          child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
        ),
      );
    }
    return PageView.builder(
      controller: _pageController,
      itemCount: urls.length,
      itemBuilder: (context, index) {
        return CachedNetworkImage(
          imageUrl: urls[index],
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (_, __, ___) => Container(
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
            child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
          ),
        );
      },
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
