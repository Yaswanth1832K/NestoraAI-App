import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/features/listings/presentation/providers/favorites_notifier.dart';
import 'package:house_rental/features/listings/presentation/providers/listings_providers.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';
import 'package:house_rental/features/ai_services/presentation/providers/ai_providers.dart';
import 'package:house_rental/features/ai_services/presentation/ai_assistant_sheet.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/chat/presentation/providers/chat_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:house_rental/core/router/app_router.dart';
import 'package:house_rental/features/listings/domain/entities/review_entity.dart';
import 'package:house_rental/features/listings/presentation/providers/review_providers.dart';
import 'package:house_rental/features/visit_requests/domain/entities/visit_request_entity.dart';
import 'package:house_rental/features/visit_requests/presentation/providers/visit_request_providers.dart';
import 'package:house_rental/features/location/commute_provider.dart';
import 'package:house_rental/main.dart';
import 'package:house_rental/core/theme/theme_provider.dart';
import 'package:house_rental/features/chat/presentation/pages/chat_page.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:house_rental/core/widgets/glass_container.dart';

class ListingDetailsPage extends ConsumerStatefulWidget {
  final ListingEntity listing;

  const ListingDetailsPage({
    super.key,
    required this.listing,
  });

  @override
  ConsumerState<ListingDetailsPage> createState() => _ListingDetailsPageState();
}

class _ListingDetailsPageState extends ConsumerState<ListingDetailsPage> {
  double? predictedPrice;
  bool _isLoading = true;
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _fetchPrediction();
  }

  Future<void> _fetchPrediction() async {
    final useCase = ref.read(predictPriceUseCaseProvider);
    final result = await useCase(
      city: widget.listing.city,
      sqft: widget.listing.sqft,
      bedrooms: widget.listing.bedrooms,
      bathrooms: widget.listing.bathrooms,
    );
    
    if (mounted) {
      result.fold(
        (failure) => setState(() {
          _isLoading = false;
        }),
        (price) => setState(() {
          predictedPrice = price;
          _isLoading = false;
        }),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _contactOwner() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to contact the owner')),
      );
      return;
    }

    if (user.uid == widget.listing.ownerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot chat with yourself')),
      );
      return;
    }

    final result = await ref.read(getOrCreateChatRoomUseCaseProvider)(
      renterId: user.uid,
      ownerId: widget.listing.ownerId,
      listingId: widget.listing.id,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open chat: ${failure.message}')),
        );
      },
      (chatRoom) {
        rootNavigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (_) => ChatPage(
              chatRoomId: chatRoom.id,
              title: widget.listing.title,
            ),
          ),
        );
      },
    );
  }

  void _showAIAssistant() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AIAssistantSheet(listing: widget.listing),
    );
  }

  void _showReviewModal() {
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to write a review')),
      );
      return;
    }

    double selectedRating = 5.0;
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Keeps the underlying screen slightly visible if needed
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return GlassContainer.standard(
          context: context,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Write a Review',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () => setState(() => selectedRating = index + 1.0),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  hintText: 'Share your experience...',
                  hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () => _submitReview(selectedRating, commentController.text),
                  child: const Text('Submit Review', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _submitReview(double rating, String comment) async {
    final user = ref.read(authStateProvider).value;
    if (user == null || comment.isEmpty) return;

    final review = ReviewEntity(
      id: const Uuid().v4(),
      listingId: widget.listing.id,
      listingTitle: widget.listing.title,
      ownerId: widget.listing.ownerId,
      reviewerId: user.uid,
      reviewerName: user.displayName ?? 'Anonymous',
      rating: rating,
      comment: comment,
      bookingId: '', // Default empty string since booking is not strictly tied to reviews in this flow yet
      createdAt: DateTime.now(),
    );

    final result = await ref.read(addReviewUseCaseProvider)(review);

    if (!mounted) return;
    Navigator.pop(context);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add review: ${failure.message}')),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review added successfully!'), backgroundColor: Colors.green),
        );
      },
    );
  }

  void _scheduleVisit() {
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to schedule a visit')),
      );
      return;
    }

    if (user.uid == widget.listing.ownerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot schedule a visit for your own property')),
      );
      return;
    }

    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    final TextEditingController messageController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final colorScheme = Theme.of(context).colorScheme;
          
          return GlassContainer.standard(
            context: context,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Schedule a Visit',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                ),
                const SizedBox(height: 24),
                
                // Date Picker Trigger
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.calendar_today, color: colorScheme.primary),
                  ),
                  title: Text('Select Date', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  subtitle: Text(
                    DateFormat('EEEE, MMM dd, yyyy').format(selectedDate),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: colorScheme.copyWith(
                              primary: colorScheme.primary,
                              surface: colorScheme.surface,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setModalState(() => selectedDate = picked);
                    }
                  },
                ),
                Divider(color: colorScheme.outline.withOpacity(0.1)),
                
                // Time Picker Trigger
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.access_time, color: colorScheme.primary),
                  ),
                  title: Text('Select Time', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  subtitle: Text(
                    selectedTime.format(context),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: colorScheme.copyWith(
                              primary: colorScheme.primary,
                              surface: colorScheme.surface,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setModalState(() => selectedTime = picked);
                    }
                  },
                ),
                const SizedBox(height: 24),
                
                Text(
                  'Message (Optional)',
                  style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: messageController,
                    maxLines: 3,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Any specific questions or requirements?',
                      hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () => _confirmVisit(
                      selectedDate, 
                      selectedTime, 
                      messageController.text
                    ),
                    child: const Text(
                      'Confirm Schedule',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmVisit(DateTime date, TimeOfDay time, String message) async {
    final user = ref.read(authStateProvider).value;
    if (user == null || !mounted) return;

    final String timeString = "${time.hour}:${time.minute.toString().padLeft(2, '0')}";

    final request = VisitRequestEntity(
      id: const Uuid().v4(),
      listingId: widget.listing.id,
      listingTitle: widget.listing.title,
      listingImage: widget.listing.allImages.isNotEmpty ? widget.listing.allImages.first : '',
      ownerId: widget.listing.ownerId,
      tenantId: user.uid,
      tenantName: user.displayName ?? 'Interested Tenant',
      date: date,
      time: timeString,
      message: message,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    // Close the modal
    Navigator.pop(context);

    final result = await ref.read(createVisitRequestUseCaseProvider)(request);

    if (!mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to schedule visit: ${failure.message}')),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visit request sent to owner!'),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
  }

  void _showFullScreenImage(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          images: widget.listing.allImages,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Widget _buildCommuteSection(bool isDark, Color textColor, Color subTextColor) {
    final uid = ref.watch(authStateProvider).value?.uid;
    final profileAsync = uid != null ? ref.watch(userProfileProvider(uid)) : null;
    final destination = profileAsync?.valueOrNull?.destination?.trim();
    if (destination == null || destination.isEmpty) return const SizedBox.shrink();

    final commuteAsync = ref.watch(commuteTimeProvider((lat: widget.listing.latitude, lng: widget.listing.longitude, destination: destination)));
    return commuteAsync.when(
      data: (duration) {
        if (duration == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.blue.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.directions_car, size: 20, color: Theme.of(context).primaryColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '~$duration to your destination',
                    style: TextStyle(fontSize: 14, color: textColor, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: subTextColor)),
            const SizedBox(width: 10),
            Text('Checking commute...', style: TextStyle(fontSize: 13, color: subTextColor)),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildNearbyPriceSection(bool isDark, Color textColor, Color subTextColor) {
    final nearbyAsync = ref.watch(nearbyListingsProvider(widget.listing));
    return nearbyAsync.when(
      data: (nearby) {
        if (nearby.isEmpty) return const SizedBox.shrink();
        final avg = nearby.map((e) => e.price).reduce((a, b) => a + b) / nearby.length;
        final diff = (widget.listing.price - avg) / avg;
        final percent = (diff * 100).round().abs();
        Color chipColor;
        String label;
        if (diff > 0.1) {
          chipColor = Colors.orange;
          label = '$percent% above nearby average';
        } else if (diff < -0.1) {
          chipColor = Colors.green;
          label = '$percent% below nearby average';
        } else {
          chipColor = Colors.grey;
          label = 'In line with nearby (${nearby.length} similar)';
        }
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: chipColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: chipColor.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.compare_arrows, size: 18, color: chipColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildTrustSafetyWarning(bool isDark, Color textColor) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.orange.withOpacity(0.1) : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trust & Safety',
                  style: TextStyle(
                    fontSize: 15, 
                    fontWeight: FontWeight.bold, 
                    color: isDark ? Colors.orange.shade300 : Colors.orange.shade900
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This listing has been flagged for review. Avoid sharing contact details or making advance payments outside the app.',
                  style: TextStyle(
                    fontSize: 13, 
                    color: isDark ? Colors.orange.shade200.withOpacity(0.8) : Colors.orange.shade900
                  ),
                ),
                if (widget.listing.fraudSignals?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 6),
                  ...(widget.listing.fraudSignals!.take(3).map((s) => Text(
                    '• $s', 
                    style: TextStyle(
                      fontSize: 12, 
                      color: isDark ? Colors.orange.shade200.withOpacity(0.6) : Colors.orange.shade800
                    )
                  ))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealIndicator(double predicted) {
    final actual = widget.listing.price;

    String label;
    Color color;

    if (actual < 0.9 * predicted) {
      label = 'GREAT DEAL';
      color = Colors.green;
    } else if (actual > 1.1 * predicted) {
      label = 'OVERPRICED';
      color = Colors.red;
    } else {
      label = 'FAIR PRICE';
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesNotifierProvider).value ?? {};
    final isFavorite = favorites.contains(widget.listing.id);
    
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            actions: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white.withOpacity(0.4),
                child: IconButton(
                  iconSize: 24,
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? const Color(0xFFFF385C) : Colors.white.withOpacity(0.9),
                  ),
                  onPressed: () {
                    final user = ref.read(authStateProvider).value;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please log in to save favorites')),
                      );
                      return;
                    }
                    ref.read(favoritesNotifierProvider.notifier).toggleFavorite(widget.listing).then((result) {
                      result.fold(
                        (failure) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to save to cloud: ${failure.message}')),
                          );
                        },
                        (_) => null,
                      );
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.listing.allImages.isEmpty
                      ? Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.home_work, size: 80, color: Colors.grey),
                        )
                      : PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) => setState(() => _currentPage = index),
                          itemCount: widget.listing.allImages.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () => _showFullScreenImage(index),
                              child: CachedNetworkImage(
                                imageUrl: widget.listing.allImages[index],
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Shimmer.fromColors(
                                  baseColor: Colors.grey.shade300,
                                  highlightColor: Colors.grey.shade100,
                                  child: Container(
                                    color: Colors.white,
                                  ),
                                ),
                                errorWidget: (context, url, error) {
                                  debugPrint('Error loading gallery image $index: $error');
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.error),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                  if (widget.listing.allImages.length > 1)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.listing.allImages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: _currentPage == index
                                  ? Theme.of(context).primaryColor
                                  : Colors.white.withOpacity(0.7),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Gradient overlay for better text visibility (if needed in title)
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black38,
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black38,
                        ],
                        stops: [0, 0.3, 0.7, 1],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${widget.listing.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      if (predictedPrice != null)
                        _buildDealIndicator(predictedPrice!),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // ... AI Analysis (omitted for brevity as it uses overlay colors)
                  
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.listing.title,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                        ),
                      ),
                      if (widget.listing.reviewCount > 0)
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 24),
                            const SizedBox(width: 4),
                            Text(
                              widget.listing.averageRating.toStringAsFixed(1),
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                            ),
                            Text(
                              ' (${widget.listing.reviewCount})',
                              style: TextStyle(fontSize: 16, color: subTextColor),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 18, color: subTextColor),
                      const SizedBox(width: 4),
                      Text(
                        widget.listing.city,
                        style: TextStyle(fontSize: 16, color: subTextColor),
                      ),
                    ],
                  ),
                  _buildCommuteSection(isDark, textColor, subTextColor),
                  _buildNearbyPriceSection(isDark, textColor, subTextColor),
                  Divider(height: 32, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                  Text(
                    'Features',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoIcon(Icons.king_bed, '${widget.listing.bedrooms} Beds', textColor),
                      _buildInfoIcon(Icons.bathtub, '${widget.listing.bathrooms} Baths', textColor),
                      _buildInfoIcon(Icons.square_foot, '${widget.listing.sqft} sqft', textColor),
                    ],
                  ),
                  if (widget.listing.isSuspicious) ...[
                    _buildTrustSafetyWarning(isDark, textColor),
                    const SizedBox(height: 16),
                  ],
                  if (widget.listing.aiSummaryBullets != null && widget.listing.aiSummaryBullets!.isNotEmpty) ...[
                    Text(
                      'Highlights',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    ...widget.listing.aiSummaryBullets!.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ', style: TextStyle(fontSize: 16, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                          Expanded(child: Text(b, style: TextStyle(fontSize: 15, color: isDark ? Colors.grey.shade300 : Colors.black87))),
                        ],
                      ),
                    )),
                    const SizedBox(height: 20),
                  ],
                  Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.listing.description,
                    style: TextStyle(fontSize: 16, color: isDark ? Colors.grey.shade300 : Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Amenities',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.listing.amenities.map((a) => Chip(
                      label: Text(a, style: TextStyle(color: textColor)),
                      backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    )).toList(),
                  ),
                  Divider(height: 48, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                  _buildReviewsSection(textColor, subTextColor),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(surfaceColor, textColor, subTextColor),
    );
  }

  Widget _buildReviewsSection(Color textColor, Color subTextColor) {
    final reviewsAsync = ref.watch(reviewsStreamProvider(widget.listing.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            Text(
              'Reviews',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            ),
        const SizedBox(height: 12),
        reviewsAsync.when(
          data: (reviews) {
            if (reviews.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No reviews yet. Be the first to review!',
                    style: TextStyle(color: subTextColor, fontStyle: FontStyle.italic),
                  ),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                return _buildReviewTile(review, textColor, subTextColor);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Text('Error loading reviews: $err', style: TextStyle(color: textColor)),
        ),
      ],
    );
  }

  Widget _buildReviewTile(ReviewEntity review, Color textColor, Color subTextColor) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                review.reviewerName,
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    size: 14,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('MMM dd, yyyy').format(review.createdAt),
            style: TextStyle(fontSize: 12, color: subTextColor),
          ),
          const SizedBox(height: 8),
          Text(review.comment, style: TextStyle(color: textColor)),
        ],
      ),
    );
  }


  Widget? _buildBottomBar(Color surfaceColor, Color textColor, Color subTextColor) {
    final user = ref.watch(authStateProvider).value;
    if (user?.uid == widget.listing.ownerId) return null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹${widget.listing.price.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                ),
                Text(
                  '/ month',
                  style: TextStyle(fontSize: 12, color: subTextColor),
                ),
              ],
            ),
            const SizedBox(width: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _contactOwner,
                      child: const Text(
                        'Contact Owner',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Theme.of(context).primaryColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _scheduleVisit,
                      child: Text(
                        'Schedule Visit',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.smart_toy, size: 18),
                      label: const Text(
                        'Ask AI',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.purple.shade300),
                        foregroundColor: Colors.purple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _showAIAssistant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _showReviewModal,
                      child: Text(
                        'Write a Review',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceInfoColumn(String label, String value, {Color? color}) {
    // ... no major changes needed here as it's inside the AI card with specific background
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoIcon(IconData icon, String label, Color textColor) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor)),
      ],
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: CachedNetworkImage(
                imageUrl: images[index],
                placeholder: (context, url) => const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }
}
