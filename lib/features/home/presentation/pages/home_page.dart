import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/features/listings/presentation/providers/listings_providers.dart';
import 'package:house_rental/features/home/presentation/widgets/listing_card.dart';
import 'package:house_rental/features/listings/presentation/widgets/filter_bottom_sheet.dart';
import 'package:house_rental/features/listings/domain/repositories/listing_repository.dart';
import 'package:house_rental/core/theme/app_colors.dart';
import 'package:house_rental/core/theme/theme_provider.dart';
import 'package:house_rental/core/router/app_router.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/notifications/domain/entities/notification_entity.dart';
import 'package:house_rental/features/notifications/presentation/providers/notification_providers.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';

// Mapping categories to Icons (using Standard Icons for now)
final List<Map<String, dynamic>> categories = [
  {'name': 'Apartments', 'icon': Icons.apartment},
  {'name': 'Villas', 'icon': Icons.house},
  {'name': 'PG', 'icon': Icons.bedroom_parent},
  {'name': 'Near College', 'icon': Icons.school},
  {'name': 'Budget', 'icon': Icons.savings},
  {'name': 'Luxury', 'icon': Icons.diamond},
  {'name': 'Trending', 'icon': Icons.local_fire_department},
  {'name': 'New', 'icon': Icons.new_releases},
];

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    _categoryFilter = 'Apartments';
    
    // Trigger "Home Page Access" Notification once per session/visit (Non-blocking)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        try {
          final uuid = const Uuid();
          await ref.read(addNotificationUseCaseProvider)(
            user.uid,
            NotificationEntity(
              id: uuid.v4(),
              title: "Exploring Properties",
              body: "You've accessed the main property feed. Happy hunting!",
              timestamp: DateTime.now(),
              type: 'system',
              isRead: false,
            ),
          );
        } catch (e) {
          debugPrint("Notification Error (Home Access): $e");
        }
      }
    });
  }

  String _categoryFilter = 'Apartments';
  
  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(filteredListingsProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 24, color: isDark ? Colors.white : Colors.black),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => context.push(AppRouter.search),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Where to?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            Text(
                              'Anywhere • Any week • Add guests',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey.shade400 : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Theme Toggle Button
                    InkWell(
                      onTap: () {
                        ref.read(themeProvider.notifier).toggleTheme();
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                        ),
                        child: Icon(
                          isDark ? Icons.light_mode : Icons.dark_mode,
                          size: 16,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Filter Button
                    InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const FilterBottomSheet(),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                        ),
                        child: Icon(Icons.tune, size: 16, color: isDark ? Colors.white : Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Categories
            Container(
              height: 80,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = _categoryFilter == category['name'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _categoryFilter = category['name'];
                      });
                      _applyCategoryFilter(category['name']);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            category['icon'] as IconData,
                            size: 28,
                            color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category['name'] as String,
                            style: TextStyle(
                              color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.grey,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 2,
                            width: 30, // Approximate width
                            color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Listings Feed
            Expanded(
              child: listingsAsync.when(
                data: (listings) {
                  if (listings.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No properties found',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    itemCount: listings.length,
                    itemBuilder: (context, index) {
                      return ListingCard(
                        listing: listings[index],
                        isVerticalFeed: true,
                        margin: const EdgeInsets.only(bottom: 32),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (err, stack) => Center(
                  child: Text(
                    'Error loading listings',
                    style: TextStyle(color: Colors.red.shade300),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyCategoryFilter(String category) {
    ListingFilter newFilter = ref.read(searchFilterProvider);
    // Add custom filtering logic here if needed
    // ref.read(searchFilterProvider.notifier).state = newFilter;
  }
}
