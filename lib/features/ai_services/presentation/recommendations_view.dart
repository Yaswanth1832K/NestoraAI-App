import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';
import 'package:house_rental/features/listings/presentation/providers/listings_providers.dart';
import 'package:house_rental/features/home/presentation/widgets/listing_card.dart';
import 'package:house_rental/core/theme/theme_provider.dart';
import 'package:house_rental/features/ai_services/presentation/providers/ai_providers.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/core/providers/firebase_provider.dart';
import 'package:house_rental/core/widgets/glass_container.dart';
import 'package:house_rental/core/theme/app_colors.dart';

class RecommendationsView extends ConsumerStatefulWidget {
  const RecommendationsView({super.key});

  @override
  ConsumerState<RecommendationsView> createState() => _RecommendationsViewState();
}

class _RecommendationsViewState extends ConsumerState<RecommendationsView> {
  bool _isLoading = true;
  String? _error;
  List<ListingEntity> _recommendedListings = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRecommendations();
    });
  }

  Future<void> _fetchRecommendations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final allListingsResult = await ref.read(getListingsUseCaseProvider)();
    
    if (!mounted) return;

    allListingsResult.fold(
      (failure) {
        setState(() {
          _error = 'Failed to load properties for analysis: ${failure.message}';
          _isLoading = false;
        });
      },
      (listings) async {
        if (listings.isEmpty) {
          setState(() {
            _error = 'No properties available to recommend from.';
            _isLoading = false;
          });
          return;
        }

        try {
          // Fetch user preferences from Firestore
          final user = ref.read(authStateProvider).value;
          String userPreferences = "Looking for a good rental property.";
          
          if (user != null) {
            final doc = await ref.read(firestoreProvider).collection('users').doc(user.uid).get();
            if (doc.exists && doc.data()?['rentalPreferences'] != null) {
              final prefs = doc.data()!['rentalPreferences'] as Map<String, dynamic>;
              final budgetMin = prefs['budgetMin'] ?? 500;
              final budgetMax = prefs['budgetMax'] ?? 3000;
              final propertyType = prefs['propertyType'] ?? 'Apartment';
              final location = prefs['location'] ?? 'anywhere';
              final bedrooms = prefs['bedrooms'] ?? 1;
              final amenitiesList = (prefs['amenities'] as Map<String, dynamic>?)
                  ?.entries
                  .where((e) => e.value == true)
                  .map((e) => e.key)
                  .toList() ?? [];
              
              userPreferences = "I am looking for a $propertyType in $location. "
                  "My budget is between \$$budgetMin and \$$budgetMax. "
                  "I need at least $bedrooms bedrooms. "
                  "Preferred amenities: ${amenitiesList.isEmpty ? 'none specific' : amenitiesList.join(', ')}.";
            } else if (user.displayName != null) {
               userPreferences = "I am ${user.displayName}. Looking for a great place to stay.";
            }
          }
          
          // Build properties list for AI as a proper JSON-encodable list
          final availableProperties = listings.map((l) => {
            'id': l.id,
            'title': l.title,
            'city': l.city,
            'price': l.price,
            'bedrooms': l.bedrooms,
            'amenities': l.amenities.join(', '),
          }).toList();

          final result = await ref.read(getRecommendationsUseCaseProvider)({
            'preferences': userPreferences,
            'properties': jsonEncode(availableProperties),
          });

          if (!mounted) return;

          result.fold(
            (failure) {
              debugPrint('AI Recommendation failed: ${failure.message}');
              setState(() {
                // Fallback: show first 5 listings if AI fails
                _recommendedListings = listings.take(5).toList();
                _isLoading = false;
              });
            },
            (aiResponse) {
              // Parse AI response to find matching IDs
              final recommended = listings.where((listing) {
                return aiResponse.contains(listing.id);
              }).toList();

              setState(() {
                // If AI matched nothing or returned garbage, show top 5 high-rated listings
                _recommendedListings = recommended.isNotEmpty 
                  ? recommended 
                  : (List<ListingEntity>.from(listings)..sort((a,b) => b.averageRating.compareTo(a.averageRating))).take(5).toList();
                _isLoading = false;
              });
            },
          );
        } catch (e) {
             debugPrint('Unexpected error in AI Fetch: $e');
             setState(() {
                _recommendedListings = listings.take(5).toList();
                _isLoading = false;
              });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? Colors.white : AppColors.textPrimaryLight;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 24),
              Text(
                "AI is searching for your perfect home...",
                style: TextStyle(
                  color: textColor.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _fetchRecommendations,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Try Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            const Text(
              'AI Recommendations',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ],
        ),
        backgroundColor: bg,
        centerTitle: false,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassContainer.standard(
              context: context,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.insights_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      "Based on your profile, we've curated homes that match your unique lifestyle.",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recommendedListings.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: ListingCard(
                    listing: _recommendedListings[index],
                    isVerticalFeed: true,
                    margin: EdgeInsets.zero,
                    heroPrefix: 'recommendations',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
