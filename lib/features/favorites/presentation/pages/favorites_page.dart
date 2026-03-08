import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:house_rental/core/router/app_router.dart';
import 'package:house_rental/core/theme/app_colors.dart';
import 'package:house_rental/core/widgets/glass_container.dart';
import 'package:house_rental/features/listings/presentation/providers/favorites_notifier.dart';
import 'package:house_rental/features/home/presentation/widgets/listing_card.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoriteListingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(
          'Wishlists',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: -1),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20, top: 8, bottom: 8),
            child: GlassContainer.standard(
              context: context,
              borderRadius: 15,
              padding: EdgeInsets.zero,
              child: IconButton(
                icon: const Icon(Icons.search_rounded, size: 22),
                onPressed: () => context.push(AppRouter.search),
              ),
            ),
          ),
        ],
      ),
      body: favoritesAsync.when(
        data: (listings) {
          if (listings.isEmpty) {
            return _buildEmptyState(context);
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Center(
              child: ConstrainedBox(
                // Match the 1100 px max-width used across the home page
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Count header ───────────────────────────
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16, top: 8),
                        child: Row(
                          children: [
                            Text(
                              '${listings.length} saved ${listings.length == 1 ? 'property' : 'properties'}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => context.push(AppRouter.search),
                              child: Text(
                                'Browse more',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      LayoutBuilder(
                        builder: (context, constraints) {
                          final w = constraints.maxWidth;
                          if (w <= 0) return const SizedBox.shrink(); // Guard against 0-width crashes

                          final cols = w > 700 ? 4 : (w > 450 ? 2 : 1);
                          final spacing = 12.0;
                          final cardWidth = (w - (cols - 1) * spacing) / cols;
                          
                          // Ensure childAspectRatio is valid
                          final itemHeight = (cols == 1 ? 420.0 : 380.0);
                          final aspectRatio = (cardWidth / itemHeight).clamp(0.1, 2.0);

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              crossAxisSpacing: spacing,
                              mainAxisSpacing: spacing,
                              childAspectRatio: aspectRatio,
                            ),
                            itemCount: listings.length,
                            itemBuilder: (context, index) {
                              return ListingCard(
                                listing: listings[index],
                                isVerticalFeed: true,
                                margin: const EdgeInsets.all(2), // Slight margin for shadow
                                heroPrefix: 'favorites',
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(
                  'Could not load saved homes\n$err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => ref.refresh(favoriteListingsProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GlassContainer.standard(
              context: context,
              padding: const EdgeInsets.all(30),
              borderRadius: 40,
              child: Icon(
                Icons.favorite_rounded,
                size: 50,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'No saved homes yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start exploring and save your favorite\nproperties to view them here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).hintColor.withOpacity(0.6),
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go(AppRouter.home),
                icon: const Icon(Icons.explore_rounded),
                label: const Text(
                  'Explore Properties',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
