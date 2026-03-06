import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart' as dartz;
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
import 'package:house_rental/core/theme/app_colors.dart';

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
  bool _isLoadingPrediction = true;

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
        (failure) => setState(() => _isLoadingPrediction = false),
        (price) => setState(() {
          predictedPrice = price;
          _isLoadingPrediction = false;
        }),
      );
    }
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
                
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.calendar_today, color: AppColors.primary),
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
                    );
                    if (picked != null) {
                      setModalState(() => selectedDate = picked);
                    }
                  },
                ),
                
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.access_time, color: AppColors.primary),
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
                    );
                    if (picked != null) {
                      setModalState(() => selectedTime = picked);
                    }
                  },
                ),
                const SizedBox(height: 24),
                
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Any specific questions or requirements?',
                    hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 13),
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDark2 : Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () => _confirmVisit(selectedDate, selectedTime, messageController.text),
                    child: const Text('Confirm Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    if (user == null) return;

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

    Navigator.pop(context);
    final result = await ref.read(createVisitRequestUseCaseProvider)(request);

    if (!mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${failure.message}'))),
      (_) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Visit request sent!'), backgroundColor: Colors.green)),
    );
  }

  void _contactOwner() async {
    final currentUser = ref.read(authStateProvider).value;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to message owner')));
      return;
    }

    if (currentUser.uid == widget.listing.ownerId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This is your own property')));
      return;
    }

    final result = await ref.read(getOrCreateChatRoomUseCaseProvider).call(
      renterId: currentUser.uid,
      ownerId: widget.listing.ownerId,
      listingId: widget.listing.id,
    );
    
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message ?? 'An error occurred'))),
      (chatRoom) => context.push(
        '/chat-detail',
        extra: {
          'chatRoomId': chatRoom.id,
          'title': widget.listing.title,
        },
      ),
    );
  }

  void _openAIAssistant() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => AIAssistantSheet(
          listing: widget.listing,
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final bgColor = isDark ? AppColors.backgroundDark : Colors.white;
    final primaryColor = AppColors.primary;

    final favorites = ref.watch(favoritesNotifierProvider).value ?? {};
    final isFavorite = favorites.contains(widget.listing.id);

    return Scaffold(
      backgroundColor: bgColor,
      bottomNavigationBar: _buildStickyBottomCTA(isDark, textColor, primaryColor),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            stretch: true,
            backgroundColor: bgColor,
            elevation: 0,
            automaticallyImplyLeading: false,
            leadingWidth: 70,
            leading: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
            actions: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, 
                       color: isFavorite ? Colors.redAccent : Colors.white, size: 18),
                  onPressed: () => ref.read(favoritesNotifierProvider.notifier).toggleFavorite(widget.listing),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.white, size: 18),
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 16),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImageGrid(),
              stretchModes: const [StretchMode.zoomBackground],
            ),
          ),

          // ── Content ──
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price & Predicted Price Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('₹${NumberFormat('#,##,###').format(widget.listing.price)}', 
                                   style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: -1.5)),
                              Text('per month', style: TextStyle(fontSize: 12, color: subTextColor, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          
                          if (!_isLoadingPrediction && predictedPrice != null)
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                               decoration: BoxDecoration(
                                 border: Border.all(color: Colors.orange.shade300, width: 1.5),
                                 borderRadius: BorderRadius.circular(20),
                               ),
                               child: const Text('FAIR PRICE', 
                                    style: TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                             ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      Text(widget.listing.title, 
                           style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(widget.listing.city, 
                               style: TextStyle(fontSize: 15, color: subTextColor, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Horizontal Spec Bar (Matches image)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildSpec(Icons.bed_rounded, '${widget.listing.bedrooms} Beds', textColor),
                            _buildSpec(Icons.bathtub_rounded, '${widget.listing.bathrooms} Baths', textColor),
                            _buildSpec(Icons.architecture_rounded, '${widget.listing.sqft.toInt()} sqft', textColor),
                          ],
                        ),
                      ),
                      
                      // Commute Info (Kept as integrated feature)
                      Consumer(
                        builder: (context, ref, _) {
                          final userAsync = ref.watch(currentUserProvider);
                          return userAsync.when(
                            data: (user) {
                              if (user == null || user.destination == null || user.destination!.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              final commuteAsync = ref.watch(commuteTimeProvider((
                                lat: widget.listing.latitude,
                                lng: widget.listing.longitude,
                                destination: user.destination!,
                              )));
                              return commuteAsync.when(
                                data: (time) => Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: GlassContainer.standard(
                                    context: context,
                                    padding: const EdgeInsets.all(16),
                                    borderRadius: 16,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.directions_car_rounded, color: Colors.blueAccent, size: 20),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('To Work', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                            Text(time ?? 'Calculating...', 
                                                 style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: textColor)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          );
                        }
                      ),
                      
                      const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Divider(height: 1)),
                      
                      // Host info
                      Consumer(
                        builder: (context, ref, _) {
                          final hostAsync = ref.watch(userProfileProvider(widget.listing.ownerId));
                          return hostAsync.when(
                            data: (host) => Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Hosted by ${host?.displayName ?? "Host"}', 
                                         style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textColor)),
                                    const SizedBox(height: 4),
                                    Text('${host?.role == "owner" ? "Superhost" : "Verified Host"} · Joined ${host != null ? "recently" : "in 2019"}', 
                                         style: TextStyle(fontSize: 14, color: subTextColor)),
                                  ],
                                ),
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                                  backgroundImage: host?.photoUrl != null ? NetworkImage(host!.photoUrl!) : null,
                                  child: host?.photoUrl == null ? Icon(Icons.person, color: subTextColor) : null,
                                ),
                              ],
                            ),
                            loading: () => const ShimmerHost(),
                            error: (_, __) => Text('Host info unavailable', style: TextStyle(color: subTextColor)),
                          );
                        }
                      ),
                      
                      const SizedBox(height: 32),
                      
                      Text('About this property', 
                           style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor)),
                      const SizedBox(height: 12),
                      Text(widget.listing.description, 
                           style: TextStyle(fontSize: 15, color: textColor.withOpacity(0.85), height: 1.6, fontWeight: FontWeight.w500)),
                      
                      const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Divider(height: 1, color: Colors.white10)),
                      
                      Text('What this place offers', 
                           style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textColor)),
                      const SizedBox(height: 24),
                      _buildAmenityList(textColor),
                      
                      const SizedBox(height: 48),
                      _buildReviewsSection(textColor, subTextColor),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    final images = widget.listing.allImages;
    if (images.isEmpty) return Container(color: Colors.grey.shade200);
    
    return PageView.builder(
      itemCount: images.length,
      itemBuilder: (context, index) {
        return CachedNetworkImage(
          imageUrl: images[index],
          fit: BoxFit.cover,
          width: double.infinity,
          placeholder: (ctx, url) => Container(color: Colors.grey.shade100),
          errorWidget: (ctx, url, err) => Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image)),
        );
      },
    );
  }


  Widget _buildSpec(IconData icon, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: AppColors.primary),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color.withOpacity(0.8))),
      ],
    );
  }

  Widget _buildHighlight(IconData icon, String title, String sub, Color textColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 28, color: textColor),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
              const SizedBox(height: 2),
              Text(sub, style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.6))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmenityList(Color textColor) {
    if (widget.listing.amenities.isEmpty) return Text('No amenities listed', style: TextStyle(color: textColor));
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: widget.listing.amenities.map((a) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: textColor.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(a, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
      )).toList(),
    );
  }

  Widget _buildStickyBottomCTA(bool isDark, Color textColor, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // AI FAB Button
            GestureDetector(
              onTap: _openAIAssistant,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            
            // Contact Button
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _contactOwner,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.surfaceDark2 : Colors.grey.shade50,
                  foregroundColor: textColor,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Contact', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(width: 12),
            
            // Schedule Visit Button
            Expanded(
              flex: 4,
              child: ElevatedButton(
                onPressed: _scheduleVisit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Schedule Visit', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.2)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for loading state


  Widget _buildReviewsSection(Color textColor, Color subTextColor) {
    final reviewsAsync = ref.watch(reviewsStreamProvider(widget.listing.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reviews', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textColor)),
        const SizedBox(height: 16),
        reviewsAsync.when(
          data: (reviews) => reviews.isEmpty 
            ? Text('No reviews yet', style: TextStyle(color: subTextColor))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reviews.length,
                itemBuilder: (ctx, i) => ListTile(
                  title: Text(reviews[i].reviewerName, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                  subtitle: Text(reviews[i].comment, style: TextStyle(color: subTextColor)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.star, color: Colors.amber, size: 16), Text(reviews[i].rating.toString(), style: TextStyle(color: textColor))]),
                ),
              ),
          loading: () => const CircularProgressIndicator(),
          error: (e, s) => Text('Error loading reviews', style: TextStyle(color: textColor)),
        ),
      ],
    );
  }
}

class ShimmerHost extends StatelessWidget {
  const ShimmerHost({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 150, height: 20, color: Colors.white),
              const SizedBox(height: 8),
              Container(width: 100, height: 14, color: Colors.white),
            ],
          ),
          const CircleAvatar(radius: 28),
        ],
      ),
    );
  }
}
