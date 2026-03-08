import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/home/presentation/widgets/listing_card.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';
import 'package:house_rental/features/listings/presentation/providers/listings_providers.dart';
import 'package:house_rental/core/theme/theme_provider.dart';
import 'package:house_rental/core/widgets/glass_container.dart';

class OwnerPropertiesScreen extends ConsumerStatefulWidget {
  const OwnerPropertiesScreen({super.key});

  @override
  ConsumerState<OwnerPropertiesScreen> createState() => _OwnerPropertiesScreenState();
}

class _OwnerPropertiesScreenState extends ConsumerState<OwnerPropertiesScreen> {
  
  Future<void> _deleteListing(String listingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Property'),
        content: const Text('Are you sure you want to delete this property? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await ref.read(deleteListingUseCaseProvider)(listingId);
    
    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: ${failure.message}')),
          );
        }
      },
      (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Property deleted successfully')),
          );
        }
      },
    );
  }

  Future<void> _updateStatus(ListingEntity listing, String newStatus) async {
    final updatedListing = listing.copyWith(status: newStatus, updatedAt: DateTime.now());
    final result = await ref.read(updateListingUseCaseProvider)(updatedListing);
    
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: ${failure.message}')),
      ),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Property marked as ${newStatus == ListingEntity.statusRented ? 'Rented' : 'Available'}')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;

    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    if (user == null) {
        return Scaffold(
            body: Center(child: Text("Please login to view your properties", style: TextStyle(color: isDark ? Colors.white : Colors.black))),
        );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("My Properties", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          GlassContainer.standard(
            context: context,
            borderRadius: 40,
            padding: EdgeInsets.zero,
            child: IconButton(
              icon: const Icon(Icons.add_rounded, size: 24),
              onPressed: () => context.push(AppRouter.postProperty),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRouter.postProperty),
        icon: const Icon(Icons.add_home_work_rounded, color: Colors.white),
        label: const Text("List Property", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      body: ref.watch(getMyListingsProvider(user.uid)).when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text("Error: $error", style: const TextStyle(color: Colors.red))),
        data: (listings) {
          final total = listings.length;
          final available = listings.where((l) => l.status == ListingEntity.statusAvailable || l.status == 'active').length;
          final rented = listings.where((l) => l.status == ListingEntity.statusRented).length;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildDashboard(total, available, rented, isDark),
              ),
              if (listings.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(isDark),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final listing = listings[index];
                        return _buildListingItem(listing, isDark);
                      },
                      childCount: listings.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDashboard(int total, int available, int rented, bool isDark) {
    final primaryColor = Theme.of(context).primaryColor;
    return Container(
      margin: const EdgeInsets.all(20),
      child: GlassContainer.standard(
        context: context,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        borderRadius: 30,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem("Total", total.toString(), null, isDark ? Colors.white : Colors.black),
            _buildStatItem("Available", available.toString(), Icons.check_circle_rounded, Colors.green),
            _buildStatItem("Rented", rented.toString(), Icons.vpn_key_rounded, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData? icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: color.withOpacity(0.8), size: 14),
              const SizedBox(width: 6),
            ],
            Text(
              value,
              style: TextStyle(
                fontSize: 28, 
                fontWeight: FontWeight.w900, 
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: -1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10, 
            color: isDark ? Colors.white54 : Colors.black54, 
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.home_work_rounded, size: 64, color: isDark ? Colors.white12 : Colors.black12),
          ),
          const SizedBox(height: 24),
          Text(
            "No properties listed",
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38, 
              fontSize: 18, 
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingItem(ListingEntity listing, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Stack(
        children: [
          ListingCard(
            listing: listing,
            showFavoriteButton: false,
            margin: EdgeInsets.zero,
            isVerticalFeed: true,
            heroPrefix: 'owner_properties',
            onTap: () {
              context.push(
                AppRouter.propertyRequests,
                extra: {
                  'listingId': listing.id,
                  'title': listing.title,
                },
              );
            },
          ),
          Positioned(
            top: 12,
            right: 12,
            child: GlassContainer.standard(
              context: context,
              borderRadius: 40,
              padding: EdgeInsets.zero,
              child: PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz_rounded, color: Colors.white, size: 20),
                padding: EdgeInsets.zero,
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                offset: const Offset(0, 40),
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteListing(listing.id);
                  } else if (value == 'edit') {
                    context.push(
                      AppRouter.postProperty,
                      extra: listing,
                    );
                  } else if (value == 'mark_rented') {
                    _updateStatus(listing, ListingEntity.statusRented);
                  } else if (value == 'mark_available') {
                    _updateStatus(listing, ListingEntity.statusAvailable);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, color: Theme.of(context).primaryColor, size: 18),
                        const SizedBox(width: 12),
                        const Text('Edit Details', style: TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  if (listing.status != ListingEntity.statusRented)
                    const PopupMenuItem<String>(
                      value: 'mark_rented',
                      child: Row(
                        children: [
                          Icon(Icons.key_off_rounded, color: Colors.orange, size: 18),
                          const SizedBox(width: 12),
                          Text('Mark as Rented', style: TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  if (listing.status == ListingEntity.statusRented)
                    const PopupMenuItem<String>(
                      value: 'mark_available',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                          const SizedBox(width: 12),
                          Text('Mark Available', style: TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_forever_rounded, color: Colors.red, size: 18),
                        const SizedBox(width: 12),
                        Text('Delete Listing', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
