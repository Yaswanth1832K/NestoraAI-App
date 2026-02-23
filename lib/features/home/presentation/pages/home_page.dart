import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/features/listings/presentation/providers/paginated_listings_notifier.dart';
import 'package:house_rental/features/home/presentation/widgets/listing_card.dart';
import 'package:house_rental/features/home/presentation/widgets/listing_card_skeleton.dart';
import 'package:house_rental/core/theme/theme_provider.dart';
import 'package:house_rental/core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:house_rental/features/home/presentation/widgets/home_services_view.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';

import 'package:house_rental/features/roommate/presentation/pages/roommate_feed_screen.dart';

// New specialized categories matching the requested UI
final List<Map<String, dynamic>> categories = [
  {'name': 'Homes', 'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'isNew': false},
  {'name': 'Roommates', 'icon': Icons.people_outline, 'activeIcon': Icons.people, 'isNew': false},
  {'name': 'Experiences', 'icon': Icons.hot_tub_outlined, 'activeIcon': Icons.hot_tub, 'isNew': true},
  {'name': 'Services', 'icon': Icons.room_service_outlined, 'activeIcon': Icons.room_service, 'isNew': true},
];

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String _categoryFilter = 'Homes';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paginatedListingsProvider.notifier).loadInitial();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      ref.read(paginatedListingsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final paginatedState = ref.watch(paginatedListingsProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // dynamic based on theme
      body: SafeArea(
        child: Column(
          children: [
            // Pill-shaped Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: GestureDetector(
                onTap: () => context.push(AppRouter.search),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade900 : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 20, color: isDark ? Colors.white : Colors.black),
                      const SizedBox(width: 8),
                      Text(
                        'Start your search',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Categories Row
            Container(
              height: 90,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: categories.map((category) {
                  final isSelected = _categoryFilter == category['name'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _categoryFilter = category['name'];
                      });
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isSelected ? category['activeIcon'] as IconData : category['icon'] as IconData,
                              size: 32,
                              color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.grey.shade500,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              category['name'] as String,
                              style: TextStyle(
                                color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.grey.shade500,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Indicator line
                            Container(
                              height: 2,
                              width: 40,
                              color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.transparent,
                            ),
                          ],
                        ),
                        if (category['isNew'] == true)
                          Positioned(
                            top: 8,
                            right: -20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B4965), // Dark blue badge color
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            // Main Content Area
            Expanded(
              child: _categoryFilter == 'Services'
                  ? const HomeServicesView()
                  : _categoryFilter == 'Roommates'
                      ? const RoommateFeedScreen()
                      : _buildHomesFeed(paginatedState),
            ),
          ],
        ),
      ),
      floatingActionButton: _categoryFilter == 'Homes' 
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRouter.map),
              backgroundColor: const Color(0xFF222222), // Dark grey
              foregroundColor: Colors.white,
              icon: const Icon(Icons.map_outlined, size: 20),
              label: const Text('Map', style: TextStyle(fontWeight: FontWeight.bold)),
              elevation: 4,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHomesFeed(PaginatedListingsState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.isLoading && state.items.isEmpty) {
      return _buildSkeletonFeed();
    }

    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => ref.read(paginatedListingsProvider.notifier).loadInitial(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final listings = state.items;
    if (listings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.home_work_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No properties yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check back later or try adjusting your filters.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final half = (listings.length / 2).ceil();
    final popularListings = listings.sublist(0, half);
    final availableListings = listings.sublist(half);

    return RefreshIndicator(
      onRefresh: () => ref.read(paginatedListingsProvider.notifier).loadInitial(),
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHorizontalSection('Popular homes', popularListings.isNotEmpty ? popularListings : listings),
            const SizedBox(height: 32),
            _buildHorizontalSection('Available next', availableListings.isNotEmpty ? availableListings : listings),
            if (state.isLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: SizedBox(height: 32, width: 32, child: CircularProgressIndicator(strokeWidth: 2))),
              )
            else if (state.hasMore)
              const SizedBox(height: 24),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonFeed() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmerColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              height: 24,
              width: 180,
              decoration: BoxDecoration(
                color: shimmerColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 380,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 24),
              itemCount: 4,
              itemBuilder: (_, __) => const ListingCardSkeleton(width: 280),
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              height: 24,
              width: 200,
              decoration: BoxDecoration(
                color: shimmerColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 380,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 24),
              itemCount: 4,
              itemBuilder: (_, __) => const ListingCardSkeleton(width: 280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalSection(String title, List<ListingEntity> properties) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade800
                      : Colors.grey.shade100,
                ),
                child: Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 380, // Ensuring enough vertical space for image (280) + text details (100)
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 24.0),
            itemCount: properties.length,
            itemBuilder: (context, index) {
              return ListingCard(
                listing: properties[index],
                isVerticalFeed: false, // Ensures card width is constrained
              );
            },
          ),
        ),
      ],
    );
  }
}
