import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:house_rental/features/notifications/domain/entities/notification_entity.dart';
import 'package:house_rental/features/notifications/presentation/providers/notification_providers.dart';
import 'package:uuid/uuid.dart';

import 'package:house_rental/features/search/presentation/providers/search_providers.dart';
import 'package:house_rental/features/search/presentation/providers/search_history_providers.dart';
import 'package:house_rental/features/listings/presentation/providers/listings_providers.dart';
import 'package:house_rental/features/home/presentation/widgets/listing_card.dart';
import 'package:house_rental/features/listings/presentation/widgets/filter_bottom_sheet.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/listings/domain/repositories/listing_repository.dart';
import 'package:house_rental/main.dart';
import 'package:house_rental/core/providers/firebase_provider.dart';
import 'package:house_rental/features/listings/presentation/pages/post_property_page.dart';
import 'package:go_router/go_router.dart';
import 'package:house_rental/core/router/app_router.dart';
import 'package:house_rental/core/widgets/glass_container.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

/// Debounce delay before firing Firestore/API search (reduces reads).
const Duration _kSearchDebounce = Duration(milliseconds: 300);

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchController = TextEditingController();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _lastWords = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _searchController.addListener(_onSearchTextChanged);
  }

  void _onSearchTextChanged() {
    _debounceTimer?.cancel();
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      ref.read(searchProvider.notifier).clearResults();
      return;
    }
    _debounceTimer = Timer(_kSearchDebounce, () {
      _performSearch(query: query);
    });
  }

  Future<void> _listen() async {
    if (!_isListening) {
      var status = await Permission.microphone.request();
      if (status.isGranted) {
        bool available = await _speech.initialize(
          onStatus: (val) {
            if (val == 'done' || val == 'notListening') {
              setState(() => _isListening = false);
              if (_searchController.text.isNotEmpty) {
                _performSearch();
              }
            }
          },
          onError: (val) => print('Speech Error: $val'),
        );
        if (available) {
          setState(() => _isListening = true);
          _speech.listen(
            onResult: (val) => setState(() {
              _lastWords = val.recognizedWords;
              _searchController.text = _lastWords;
            }),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required for voice search')),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _performSearch({String? query}) async {
    if (ref.read(searchProvider).isLoading) return;
    
    final searchText = query ?? _searchController.text.trim();
    if (searchText.isNotEmpty) {
      if (query != null) {
        _searchController.text = query;
      }
      await ref.read(searchProvider.notifier).search(searchText);
      await ref.read(searchHistoryProvider.notifier).addQuery(searchText);

      // Send Notification for Search Activity (Non-blocking)
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        try {
          final uuid = const Uuid();
          await ref.read(addNotificationUseCaseProvider)(
            user.uid,
            NotificationEntity(
              id: uuid.v4(),
              title: "Search Activity",
              body: "You searched for: '$searchText'",
              timestamp: DateTime.now(),
              type: 'system',
              isRead: false,
            ),
          );
        } catch (e) {
          debugPrint("Notification Error (Search): $e");
        }
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Search Explore',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5),
        ),
        actions: [
          _buildActionIcon(Icons.tune_rounded, () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const FilterBottomSheet(),
            );
          }),
          const SizedBox(width: 8),
          _buildActionIcon(Icons.add_home_rounded, () => context.push(AppRouter.postProperty)),
          const SizedBox(width: 20),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'search_bar',
                  child: GlassContainer.standard(
                    context: context,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    borderRadius: 20,
                    child: Row(
                      children: [
                        Icon(
                          _isListening ? Icons.mic_rounded : Icons.search_rounded,
                          color: _isListening ? Colors.red : Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText: _isListening ? 'Listening...' : 'Search near you...',
                              hintStyle: TextStyle(color: Theme.of(context).hintColor.withOpacity(0.5), fontWeight: FontWeight.w500),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onChanged: (val) => setState(() {}),
                            onSubmitted: (_) => _performSearch(),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(searchProvider.notifier).clearResults();
                              setState(() {});
                            },
                          ),
                        IconButton(
                          icon: Icon(
                            _isListening ? Icons.stop_circle_rounded : Icons.mic_none_rounded,
                            color: _isListening ? Colors.red : Theme.of(context).primaryColor,
                          ),
                          onPressed: _listen,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Try "Apartment with pool" or "2BHK near city center"',
                    style: TextStyle(
                      color: Theme.of(context).hintColor.withOpacity(0.4), 
                      fontSize: 12, 
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Recent Searches UI
                ref.watch(searchHistoryProvider).maybeWhen(
                  data: (history) {
                    if (history.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recent Searches',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: history.length,
                            itemBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildGlassChip(
                                label: history[index],
                                icon: Icons.history_rounded,
                                onTap: () => _performSearch(query: history[index]),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildActiveFilters(ref),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final filter = ref.watch(searchFilterProvider);
                final isFiltered = _isFilterActive(filter);
                
                if (isFiltered && _searchController.text.isEmpty) {
                  return ref.watch(filteredListingsProvider).when(
                    data: (listings) {
                      if (listings.isEmpty) return _buildInfoState(Icons.filter_list_off_rounded, 'No matches found');
                      return _buildResultsList('Filtered Properties', listings);
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => _buildInfoState(Icons.error_outline_rounded, 'Search Error: $e'),
                  );
                }

                final searchState = ref.watch(searchProvider);
                return searchState.when(
                  data: (listings) {
                    if (listings.isEmpty && _searchController.text.isEmpty) {
                      final recommendationsState = ref.watch(recommendationsProvider);
                      return recommendationsState.when(
                        data: (recListings) {
                          if (recListings.isEmpty) return _buildInfoState(Icons.search_rounded, 'Discover your next home');
                          return _buildResultsList('Suggested for you', recListings);
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => _buildInfoState(Icons.home_rounded, 'Discover your next home'),
                      );
                    }

                    if (listings.isEmpty) return _buildInfoState(Icons.search_off_rounded, 'No properties match your search');
                    
                    return _buildResultsList('Search Results', listings);
                  },
                  error: (err, stack) => _buildInfoState(Icons.error_outline_rounded, 'Something went wrong: $err'),
                  loading: () => _buildLoadingState(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: GlassContainer.standard(
        context: context,
        borderRadius: 40,
        padding: EdgeInsets.zero,
        child: IconButton(
          icon: Icon(icon, size: 22),
          onPressed: onTap,
        ),
      ),
    );
  }

  Widget _buildGlassChip({required String label, required IconData icon, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: GlassContainer.standard(
        context: context,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        borderRadius: 15,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(String title, List listings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
        ),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: listings.length,
            itemBuilder: (context, index) => ListingCard(listing: listings[index], isVerticalFeed: true),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Theme.of(context).hintColor.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.w800, 
              color: Theme.of(context).hintColor.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(strokeWidth: 3),
          const SizedBox(height: 24),
          Text(
            'Finding the best matches...',
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  bool _isFilterActive(ListingFilter filter) {
    return filter.minPrice != null || 
           filter.maxPrice != null || 
           filter.bedrooms != null || 
           filter.bathrooms != null || 
           filter.furnishing != null || 
           (filter.amenities != null && filter.amenities!.isNotEmpty);
  }

  Widget _buildActiveFilters(WidgetRef ref) {
    final filter = ref.watch(searchFilterProvider);
    if (!_isFilterActive(filter)) return const SizedBox.shrink();

    final List<String> chips = [];
    if (filter.minPrice != null || filter.maxPrice != null) {
      chips.add('₹${filter.minPrice?.toInt() ?? 0} - ₹${filter.maxPrice?.toInt() ?? 'Max'}');
    }
    if (filter.bedrooms != null) chips.add('${filter.bedrooms} BHK');
    if (filter.bathrooms != null) chips.add('${filter.bathrooms} Bath');
    if (filter.furnishing != null) chips.add(filter.furnishing!);
    if (filter.amenities != null) chips.addAll(filter.amenities!);

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.tune_rounded, size: 18, color: Theme.of(context).primaryColor),
            );
          }
          final chipLabel = chips[index - 1];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GlassContainer.standard(
              context: context,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              borderRadius: 10,
              child: Center(
                child: Text(
                  chipLabel,
                  style: TextStyle(
                    fontSize: 10, 
                    fontWeight: FontWeight.w800, 
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


