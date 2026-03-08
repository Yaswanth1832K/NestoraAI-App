import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import 'package:house_rental/core/widgets/nestora_image.dart';
import 'package:house_rental/core/theme/app_spacing.dart';
import 'package:intl/intl.dart';
import 'package:house_rental/core/theme/app_colors.dart';
import 'package:house_rental/features/ai_services/presentation/providers/ai_providers.dart';

class ListingCard extends ConsumerStatefulWidget {
  final ListingEntity listing;
  final bool isCompact;
  final bool isVerticalFeed;
  final double? width;
  final EdgeInsetsGeometry? margin;
  final bool showFavoriteButton;
  final Widget? actionButton;
  final VoidCallback? onTap;
  final String heroPrefix;

  const ListingCard({
    super.key,
    required this.listing,
    this.isCompact = false,
    this.isVerticalFeed = false,
    this.width,
    this.margin,
    this.showFavoriteButton = true,
    this.actionButton,
    this.onTap,
    this.heroPrefix = 'listing',
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
    final primaryColor = AppColors.primary;
    
    final textColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final subTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    // Fetch owner details
    final ownerProfile = ref.watch(userProfileProvider(widget.listing.ownerId));

    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmall = screenWidth < 360;
    
    final cardWidth = widget.width ?? 
        (widget.isVerticalFeed 
            ? double.infinity 
            : (widget.isCompact 
                ? (isVerySmall ? 180.0 : 200.0) 
                : (isVerySmall ? screenWidth * 0.8 : 300.0)));

    return GestureDetector(
      onTap: widget.onTap ?? () {
        rootNavigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (_) => ListingDetailsPage(
              listing: widget.listing,
              heroPrefix: widget.heroPrefix,
            ),
          ),
        );
      },
      child: AnimatedContainer(
        duration: 200.ms,
        curve: Curves.easeOutCubic,
        width: cardWidth,
        margin: widget.margin ?? EdgeInsets.only(right: AppSpacing.s16, bottom: AppSpacing.s24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: AspectRatio(
                    aspectRatio: widget.isCompact ? 1.2 : 1.5,
                    child: Hero(
                      tag: '${widget.heroPrefix}_image_${widget.listing.id}',
                      child: _buildImageGallery(isDark),
                    ),
                  ),
                ),
                
                // Overlay Gradient
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                        stops: const [0.0, 0.3, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),

                // Favorite Button
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: _isToggling ? null : () => _toggleFavorite(context),
                    child: GlassContainer(
                      padding: const EdgeInsets.all(8),
                      borderRadius: BorderRadius.circular(50),
                      opacity: 0.2,
                      blur: 10,
                      child: AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border_rounded,
                              color: isFavorite ? Colors.redAccent : Colors.white,
                              size: 18,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Bottom Left Badge (Status)
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: AppSpacing.s8),
                        Text(
                          widget.listing.status.toUpperCase(),
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.textPrimaryLight, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Info Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Hero(
                          tag: '${widget.heroPrefix}_title_${widget.listing.id}',
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              widget.listing.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      AppSpacing.h8,
                      if (widget.listing.averageRating > 0)
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                            AppSpacing.h4,
                            Text(
                              widget.listing.averageRating.toStringAsFixed(1),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                            ),
                          ],
                        ),
                    ],
                  ),
                  AppSpacing.v4,
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 14, color: (primaryColor).withOpacity(0.6)),
                      AppSpacing.h4,
                      Expanded(
                        child: Text(
                          widget.listing.city,
                          style: TextStyle(fontSize: 13, color: subTextColor, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.v12,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('MONTHLY RENT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: subTextColor.withOpacity(0.5), letterSpacing: 1)),
                            AppSpacing.v4,
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Hero(
                                  tag: '${widget.heroPrefix}_price_${widget.listing.id}',
                                  child: Material(
                                    color: Colors.transparent,
                                    child: Text(
                                      '₹${NumberFormat('#,##,###').format(widget.listing.price)}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: primaryColor,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Consumer(
                                  builder: (context, ref, _) {
                                    final prediction = ref.watch(listingPredictedPriceProvider(widget.listing));
                                    return prediction.when(
                                      data: (predictedPrice) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.auto_awesome_rounded, size: 8, color: AppColors.primary),
                                            const SizedBox(width: 4),
                                            Text(
                                              '₹${NumberFormat('#,##,###').format(predictedPrice)}',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      loading: () => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Shimmer.fromColors(
                                          baseColor: Colors.grey.withOpacity(0.3),
                                          highlightColor: Colors.grey.withOpacity(0.1),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.auto_awesome_rounded, size: 8),
                                              const SizedBox(width: 4),
                                              const Text(
                                                'Refining...',
                                                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      error: (_, __) => const SizedBox.shrink(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Owner Mini Profile
                      ownerProfile.maybeWhen(
                        data: (user) => Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border: Border.all(color: (primaryColor).withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundImage: user?.photoUrl != null ? CachedNetworkImageProvider(user!.photoUrl!) : null,
                                child: user?.photoUrl == null ? const Icon(Icons.person, size: 12) : null,
                              ),
                              AppSpacing.h8,
                              Text(
                                user?.displayName?.split(' ').first ?? 'Host',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor.withOpacity(0.7)),
                              ),
                              AppSpacing.h4,
                            ],
                          ),
                        ),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
      ),
    ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOut)
               .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut),
    );
  }

  Widget _buildImageGallery(bool isDark) {
    final urls = widget.listing.allImages.isNotEmpty ? widget.listing.allImages : _fallbackPool;
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: urls.length.clamp(1, 4),
          itemBuilder: (context, index) {
            return NestoraImage(
              imageUrl: urls[index],
              width: double.infinity,
              height: double.infinity,
            );
          },
        ),
        if (urls.length > 1)
          Positioned(
            bottom: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                urls.length.clamp(1, 4),
                (index) => AnimatedContainer(
                  duration: 300.ms,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentImageIndex == index ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == index 
                        ? Colors.white 
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static const _fallbackPool = [
    'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=800&q=80',
    'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=800&q=80',
    'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800&q=80',
    'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800&q=80',
  ];

  Future<void> _toggleFavorite(BuildContext context) async {
    final authState = ref.read(authStateProvider);
    if (authState.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to save favorites')));
      return;
    }

    HapticFeedback.lightImpact();
    _animationController.forward().then((_) => _animationController.reverse());
    // Adding a secondary subtle "pop" for better tactile feel
    Future.delayed(100.ms, () => HapticFeedback.selectionClick());

    setState(() => _isToggling = true);
    final result = await ref.read(favoritesNotifierProvider.notifier).toggleFavorite(widget.listing);

    if (mounted) {
      setState(() => _isToggling = false);
      result.fold(
        (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: ${failure.message}'))),
        (_) {},
      );
    }
  }
}
