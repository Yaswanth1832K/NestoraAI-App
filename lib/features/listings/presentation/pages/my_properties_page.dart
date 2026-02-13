import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/home/presentation/widgets/listing_card.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';
import 'package:house_rental/features/listings/presentation/providers/listings_providers.dart';
import 'package:house_rental/features/listings/presentation/pages/post_property_page.dart';
import 'package:house_rental/main.dart'; // For rootNavigatorKey

class MyPropertiesPage extends ConsumerStatefulWidget {
  const MyPropertiesPage({super.key});

  @override
  ConsumerState<MyPropertiesPage> createState() => _MyPropertiesPageState();
}

class _MyPropertiesPageState extends ConsumerState<MyPropertiesPage> {
  bool _isLoading = true;
  List<ListingEntity> _myListings = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMyListings();
  }

  Future<void> _fetchMyListings() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ref.read(getMyListingsUseCaseProvider)(user.uid);
      result.fold(
        (failure) {
          if (mounted) {
            setState(() {
              _error = failure.message;
              _isLoading = false;
            });
          }
        },
        (listings) {
          if (mounted) {
            setState(() {
              _myListings = listings;
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Optimistic update
    final previousList = List<ListingEntity>.from(_myListings);
    setState(() {
      _myListings.removeWhere((l) => l.id == listingId);
    });

    final result = await ref.read(deleteListingUseCaseProvider)(listingId);
    
    result.fold(
      (failure) {
        // Revert on failure
        if (mounted) {
          setState(() {
            _myListings = previousList;
          });
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Properties')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Please login to view your properties'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Navigate to login or just show snackbar as this is a protected tab usually
                },
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );
    }

    final isOwnerAsync = ref.watch(isOwnerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('My Properties', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          isOwnerAsync.when(
            data: (isOwner) => isOwner
                ? IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    tooltip: 'Post New Property',
                    onPressed: () {
                      rootNavigatorKey.currentState!.push(
                        MaterialPageRoute(builder: (_) => const PostPropertyPage()),
                      ).then((_) => _fetchMyListings()); // Refresh on return
                    },
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
              : _myListings.isEmpty
                  ? Center(
                      child: isOwnerAsync.when(
                        data: (isOwner) => Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.home_work_outlined, size: 80, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              isOwner
                                  ? "You haven't posted any properties yet"
                                  : "You don't have any properties",
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            const SizedBox(height: 24),
                            if (isOwner)
                              ElevatedButton.icon(
                                onPressed: () {
                                  rootNavigatorKey.currentState!.push(
                                    MaterialPageRoute(builder: (_) => const PostPropertyPage()),
                                  ).then((_) => _fetchMyListings());
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Post Property'),
                              )
                            else
                              Text(
                                'Only property owners can post listings',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                              ),
                          ],
                        ),
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) => const Text(
                          'Error loading user role',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchMyListings,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: _myListings.length,
                        itemBuilder: (context, index) {
                          final listing = _myListings[index];
                          return ListingCard(
                            listing: listing,
                            showFavoriteButton: false, // Hide favorite button
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            actionButton: Container( // Custom 3-dot menu
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: Colors.white),
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    _deleteListing(listing.id);
                                  } else if (value == 'edit') {
                                    rootNavigatorKey.currentState!.push(
                                      MaterialPageRoute(
                                        builder: (_) => PostPropertyPage(existingListing: listing),
                                      ),
                                    ).then((_) => _fetchMyListings());
                                  }
                                },
                                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                  const PopupMenuItem<String>(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, color: Colors.blue),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
