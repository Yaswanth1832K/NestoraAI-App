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
    final searchState = ref.watch(searchProvider);
    final recommendationsState = ref.watch(recommendationsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Search Homes',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: Theme.of(context).colorScheme.onSurface),
            tooltip: 'Filters',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const FilterBottomSheet(),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.add_home, color: Theme.of(context).colorScheme.onSurface),
            tooltip: 'Post Property',
            onPressed: () {
              rootNavigatorKey.currentState!.push(
                MaterialPageRoute(builder: (_) => const PostPropertyPage()),
              );
            },
          ),
          Consumer(
            builder: (context, ref, child) {
              final authState = ref.watch(authStateProvider);
              return authState.maybeWhen(
                data: (user) => IconButton(
                  icon: Icon(user == null ? Icons.account_circle_outlined : Icons.account_circle, 
                    color: user == null ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.primary),
                  tooltip: user == null ? 'Quick Login' : 'Logout',
                  onPressed: () async {
                    if (user == null) {
                      try {
                        await ref.read(firebaseAuthProvider).signInAnonymously();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Logged in as Guest')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Login failed: $e')),
                          );
                        }
                      }
                    } else {
                      await ref.read(firebaseAuthProvider).signOut();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Logged out')),
                        );
                      }
                    }
                  },
                ),
                orElse: () => const SizedBox.shrink(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: _isListening ? 'Listening...' : 'Try: 2bhk near college under 15000',
                          hintStyle: TextStyle(color: Theme.of(context).colorScheme.outline),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          prefixIcon: Icon(
                            _isListening ? Icons.mic : Icons.search,
                            color: _isListening ? Colors.red : Theme.of(context).colorScheme.outline,
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_searchController.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref.read(searchProvider.notifier).clearResults();
                                    setState(() {});
                                  },
                                ),
                              IconButton(
                                icon: Icon(
                                  _isListening ? Icons.mic : Icons.mic_none,
                                  color: _isListening ? Colors.red : Theme.of(context).primaryColor,
                                ),
                                onPressed: _listen,
                              ),
                            ],
                          ),
                        ),
                        onChanged: (val) => setState(() {}),
                        onSubmitted: (_) => _performSearch(),
                      ),
                    ),
                    if (!_isListening) ...[
                      const SizedBox(width: 10),
                      IconButton.filled(
                        style: IconButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                        onPressed: searchState.isLoading ? null : _performSearch,
                        icon: searchState.isLoading 
                          ? const SizedBox(
                              width: 20, 
                              height: 20, 
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.search, color: Colors.white),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Search in natural language (AI powered)',
                  style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                // Recent Searches UI
                ref.watch(searchHistoryProvider).maybeWhen(
                  data: (history) {
                    if (history.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Searches',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: history.map((query) => ActionChip(
                            label: Text(query),
                            onPressed: () => _performSearch(query: query),
                            avatar: Icon(Icons.history, size: 16, color: Theme.of(context).primaryColor),
                            backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                            side: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
                            labelStyle: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface),
                          )).toList(),
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildActiveFilters(ref),
          ),
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final filter = ref.watch(searchFilterProvider);
                final isFiltered = _isFilterActive(filter);
                
                if (isFiltered && _searchController.text.isEmpty) {
                  return ref.watch(filteredListingsProvider).when(
                    data: (listings) {
                      if (listings.isEmpty) return const Center(child: Text('No properties match your filters'));
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('Filtered Properties', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: listings.length,
                              itemBuilder: (context, index) => ListingCard(listing: listings[index]),
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  );
                }

                return searchState.when(
              data: (listings) {
                if (listings.isEmpty && _searchController.text.isEmpty) {
                  // Show Recommendations when not searching
                  return recommendationsState.when(
                    data: (recListings) {
                      if (recListings.isEmpty) {
                        return const Center(child: Text('Type to search for homes'));
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Text(
                              'Recommended for you',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: recListings.length,
                              itemBuilder: (context, index) => ListingCard(listing: recListings[index]),
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Center(child: Text('Type to search for homes')),
                  );
                }

                if (listings.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No properties found for your search',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try increasing budget or changing keywords',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: listings.length,
                  itemBuilder: (context, index) => ListingCard(listing: listings[index]),
                );
              },
              error: (err, stack) => Center(
                child: Card(
                  color: Colors.red.shade50,
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Search Error',
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$err',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Searching for your dream home...'),
                  ],
                ),
              ),
            );
          },
        ),
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
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          const Icon(Icons.tune, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          ...chips.map((c) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              label: Text(c, style: const TextStyle(fontSize: 11)),
            ),
          )),
        ],
      ),
    );
  }
}


