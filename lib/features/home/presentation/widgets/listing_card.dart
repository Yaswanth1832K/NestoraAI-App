import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';
import 'package:house_rental/features/listings/presentation/providers/favorites_notifier.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/listings/presentation/pages/listing_details_page.dart';
import 'package:house_rental/main.dart';
import 'package:house_rental/core/widgets/glass_container.dart';
import 'package:intl/intl.dart';
import 'package:house_rental/core/theme/app_colors.dart';
import 'package:house_rental/features/ai_services/presentation/providers/ai_providers.dart';

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
    final primaryColor = Theme.of(context).primaryColor;
    
    final textColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final subTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    // Fetch owner details for avatar
    final ownerProfile = ref.watch(userProfileProvider(widget.listing.ownerId));

    return GestureDetector(
      onTap: widget.onTap ?? () {
        rootNavigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (_) => ListingDetailsPage(listing: widget.listing),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: widget.isVerticalFeed ? double.infinity : null,
        margin: widget.margin ?? EdgeInsets.only(right: AppColors.s24, bottom: AppColors.s32),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  child: SizedBox(
                    height: widget.isCompact ? 160 : 220,
                    width: double.infinity,
                    child: _buildImageGallery(isDark),
                  ),
                ),
                // Dot indicators
                Positioned(
                  bottom: 8,
                  right: 12,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (i) {
                      final active = _currentImageIndex == i;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(left: 4),
                        width: active ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active ? Colors.white : Colors.white54,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),
                
                // Top Gradient for contrast
                Positioned(
                  top: 0, left: 0, right: 0, height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(0.3), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                
                // Favorite Button (Top Right)
                Positioned(
                  top: AppColors.s16,
                  right: AppColors.s16,
                  child: GestureDetector(
                    onTap: _isToggling ? null : () => _toggleFavorite(context),
                    child: Container(
                      padding: EdgeInsets.all(AppColors.s8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceLight2 : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      child: AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border_rounded,
                              color: isFavorite ? primaryColor : AppColors.textPrimaryLight,
                              size: 20,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Availability Badge (Bottom Left)
                Positioned(
                  bottom: AppColors.s16,
                  left: AppColors.s16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.backgroundDark.withOpacity(0.8) : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(
                            color: widget.listing.status == ListingEntity.statusAvailable ? AppColors.success : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.listing.status.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimaryLight,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            Padding(
              padding: EdgeInsets.all(AppColors.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Owner Row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.listing.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      SizedBox(width: AppColors.s8),
                      // Owner Avatar
                      ownerProfile.when(
                        data: (user) => CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.surfaceLight2,
                          backgroundImage: user?.photoUrl != null ? CachedNetworkImageProvider(user!.photoUrl!) : null,
                          child: user?.photoUrl == null ? Icon(Icons.person, size: 14, color: AppColors.textSecondaryLight) : null,
                        ),
                        loading: () => const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: AppColors.s8),
                  
                  // Location & Rating Row
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: subTextColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${widget.listing.city}',
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (widget.listing.averageRating > 0) ...[
                        const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          widget.listing.averageRating.toStringAsFixed(1),
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  SizedBox(height: AppColors.s16),
                  
                  // Price Tag (Dominant)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '₹${NumberFormat('#,##,###').format(widget.listing.price)}',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              TextSpan(
                                text: ' / month',
                                style: TextStyle(
                                  color: primaryColor.withOpacity(0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // AI Price Prediction Badge
                      ref.watch(listingPredictedPriceProvider(widget.listing)).when(
                        data: (predictedPrice) {
                          final isFair = widget.listing.price <= predictedPrice * 1.1;
                          final priceStr = NumberFormat.compactCurrency(
                            symbol: '₹',
                            decimalDigits: 0,
                            locale: 'en_IN',
                          ).format(predictedPrice);
                          
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isFair ? Colors.orange.shade300 : Colors.red.shade300,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isFair ? 'FAIR PRICE' : 'OVERPRICED',
                                  style: TextStyle(
                                    color: isFair ? Colors.orange : Colors.red,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  'AI Expects: $priceStr',
                                  style: TextStyle(
                                    color: isFair ? Colors.orange.withOpacity(0.8) : Colors.red.withOpacity(0.8),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A large, diverse pool of curated Unsplash house/apartment photos.
  static const _fallbackPool = [
    'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=800&q=80',
    'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=800&q=80',
    'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800&q=80',
    'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800&q=80',
    'https://images.unsplash.com/photo-1416331108676-a22ccb276e35?w=800&q=80',
    'https://images.unsplash.com/photo-1523217582562-09d0def993a6?w=800&q=80',
    'https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=800&q=80',
    'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=800&q=80',
    'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800&q=80',
    'https://images.unsplash.com/photo-1513584684374-8bab748fbf90?w=800&q=80',
    'https://images.unsplash.com/photo-1600047509807-ba8f99d2cdde?w=800&q=80',
    'https://images.unsplash.com/photo-1556020685-ae41abfc9365?w=800&q=80',
    'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&q=80',
    'https://images.unsplash.com/photo-1504615755583-2916b52192a3?w=800&q=80',
    'https://images.unsplash.com/photo-1583608205776-bfd35f0d9f83?w=800&q=80',
    'https://images.unsplash.com/photo-1464146072230-91cabc968266?w=800&q=80',
    'https://images.unsplash.com/photo-1571939228382-b2f2b585ce15?w=800&q=80',
    'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800&q=80',
    'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800&q=80',
    'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?w=800&q=80',
    'https://images.unsplash.com/photo-1559767949-0faa5c7e9992?w=800&q=80',
    'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=800&q=80',
    'https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=800&q=80',
    'https://images.unsplash.com/photo-1617806118233-18e1de247200?w=800&q=80',
  ];

  /// Returns exactly 3 unique image URLs for this card.
  /// Starts from the listing's own images (de-duped), then fills gaps
  /// from the fallback pool using a deterministic offset from the listing id
  /// so every card gets a different set of fallbacks.
  List<String> _buildThreeImages() {
    // De-duplicate listing images while preserving order.
    final seen = <String>{};
    final unique = widget.listing.allImages.where((u) => u.isNotEmpty && seen.add(u)).toList();

    final result = unique.take(3).toList();

    if (result.length < 3) {
      // Deterministic offset based on listing id hash so cards differ from each other.
      final offset = widget.listing.id.hashCode.abs() % _fallbackPool.length;
      var idx = offset;
      while (result.length < 3) {
        final candidate = _fallbackPool[idx % _fallbackPool.length];
        if (!result.contains(candidate)) result.add(candidate);
        idx++;
      }
    }

    return result;
  }

  Widget _buildImageGallery(bool isDark) {
    final urls = _buildThreeImages();
    final placeholder = Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFEBEBEB),
      highlightColor: isDark ? const Color(0xFF222222) : const Color(0xFFF5F5F5),
      child: Container(color: Colors.white),
    );

    return PageView.builder(
      controller: _pageController,
      physics: const BouncingScrollPhysics(),
      itemCount: urls.length,
      itemBuilder: (context, index) {
        return CachedNetworkImage(
          imageUrl: urls[index],
          fit: BoxFit.cover,
          placeholder: (_, __) => placeholder,
          errorWidget: (_, __, ___) => Container(
            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
            child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
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

    HapticFeedback.mediumImpact();
    _animationController.forward().then((_) => _animationController.reverse());

    setState(() => _isToggling = true);
    final result = await ref.read(favoritesNotifierProvider.notifier).toggleFavorite(widget.listing);

    if (mounted) {
      setState(() => _isToggling = false);
      result.fold(
        (failure) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: ${failure.message}')),
        ),
        (_) {},
      );
    }
  }
}
