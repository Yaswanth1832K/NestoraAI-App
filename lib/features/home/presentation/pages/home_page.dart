import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/features/listings/presentation/providers/paginated_listings_notifier.dart';
import 'package:house_rental/features/home/presentation/widgets/service_card.dart';
import 'package:house_rental/features/home/presentation/widgets/service_category_section.dart';
import 'package:house_rental/features/home/presentation/widgets/service_hero_banner.dart';
import 'package:house_rental/features/home/presentation/widgets/listing_card.dart';
import 'package:house_rental/features/home/presentation/widgets/listing_card_skeleton.dart';
import 'package:house_rental/features/listings/domain/repositories/listing_repository.dart';
import 'package:house_rental/features/location/location_provider.dart';
import 'package:house_rental/core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:house_rental/core/widgets/glass_container.dart';
import 'package:house_rental/features/listings/presentation/pages/listing_details_page.dart';
import 'package:house_rental/main.dart';
import 'package:house_rental/features/home/presentation/widgets/featured_services_carousel.dart';
import 'package:house_rental/features/home/presentation/pages/service_detail_page.dart';
import 'package:house_rental/features/home/data/services_data.dart';
import 'package:house_rental/features/home/domain/entities/home_service.dart';
import 'package:house_rental/features/notifications/presentation/providers/notification_providers.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:house_rental/core/theme/app_colors.dart';
import 'package:house_rental/l10n/generated/app_localizations.dart';
import 'package:house_rental/core/theme/app_spacing.dart';
import 'package:house_rental/core/widgets/nestora_empty_state.dart';
import 'package:house_rental/core/widgets/nestora_image.dart';

// ══════════════════════════════════════════════════════════════
//  HOME PAGE  –  3-tab: Property | Home Services | Payments
// ══════════════════════════════════════════════════════════════
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _mainTab = 0; // 0=Property  1=HomeServices  2=Payments

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Listen for location changes to trigger listing reloads
      ref.listenManual(userLocationProvider, (previous, next) {
        if (next.city != previous?.city || next.position != previous?.position) {
          ref.read(paginatedListingsProvider.notifier).loadInitial(
            filter: ListingFilter(
              city: next.city,
              userLat: next.position?.latitude,
              userLng: next.position?.longitude,
            ),
          );
        }
      }, fireImmediately: true);

      // Trigger initial location fetch
      ref.read(userLocationProvider.notifier).updateLocation();
    });
  }

  // ── Airbnb-Style Sliding Tab Switcher ─────────────────────────────────
  Widget _topTabs(bool isDark) {
    final tabs = [
      {'label': AppLocalizations.of(context)!.property,      'icon': Icons.home_rounded},
      {'label': AppLocalizations.of(context)!.homeServices, 'icon': Icons.handyman_rounded},
      {'label': AppLocalizations.of(context)!.payments,      'icon': Icons.credit_card_rounded},
    ];
    
    final activeTxt  = Colors.white;
    final inactiveTxt= isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: AppColors.s24, vertical: 8),
          height: 52,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Stack(
            children: [
              // Sliding Highlight
              AnimatedAlign(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                alignment: Alignment(_getTabAlignment(_mainTab), 0),
                child: FractionallySizedBox(
                  widthFactor: 1 / 3,
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              // Tab Items
              Row(
                children: List.generate(tabs.length, (i) {
                  final sel = _mainTab == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _mainTab = i),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: sel ? FontWeight.w900 : FontWeight.w600,
                            color: sel ? activeTxt : inactiveTxt,
                          ),
                          child: Text(tabs[i]['label'] as String),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getTabAlignment(int index) {
    if (index == 0) return -1.0;
    if (index == 1) return 0.0;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppColors.s24),
                  child: _LogoBar(isDark: isDark),
                ),
              ),
              // Search bar now sits between Logo and Tabs
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppColors.s24, 8, AppColors.s24, 8),
                  child: _buildGlobalSearchBar(context, ref, isDark),
                ),
              ),
              SliverPersistentHeader(
                pinned: true, // Keep it pinned for easy tab switching
                delegate: _SliverTabsDelegate(
                  child: Container(
                    color: bg,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: _topTabs(isDark),
                      ),
                    ),
                  ),
                ),
              ),
            ];
          },
          body: Column(
            children: [
              Expanded(
                child: IndexedStack(
                  index: _mainTab,
                  children: [
                    _PropertyTab(isDark: isDark),
                    _HomeServicesTab(isDark: isDark),
                    _PaymentsTab(isDark: isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalSearchBar(BuildContext context, WidgetRef ref, bool isDark) {
    final card = isDark ? AppColors.surfaceDark : Colors.white;
    final txt = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Row(children: [
      Expanded(
        child: GestureDetector(
          onTap: () => context.push(AppRouter.search),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Row(children: [
              const Icon(Icons.search_rounded, size: 24, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(child: Consumer(builder: (context, ref, _) {
                final city = ref.watch(userLocationProvider).city ?? 'Anywhere';
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Near $city', style: TextStyle(color: txt, fontSize: 13, fontWeight: FontWeight.w900, height: 1.1)),
                  Text('${AppLocalizations.of(context)!.anyWeek} · ${AppLocalizations.of(context)!.addGuests}', style: TextStyle(color: sub, fontSize: 11, fontWeight: FontWeight.w500)),
                ]);
              })),
            ]),
          ),
        ),
      ),
      const SizedBox(width: 12),
      GestureDetector(
        onTap: () => context.push(AppRouter.search),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: card,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Icon(Icons.tune_rounded, size: 20, color: txt),
        ),
      ),
    ]);
  }
}

class _SliverTabsDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SliverTabsDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 52; // Reduced for less gap
  @override
  double get minExtent => 52;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}

// ── Logo header bar ───────────────────────────────────────────
class _LogoBar extends StatelessWidget {
  final bool isDark;
  const _LogoBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final showLogoText = screenWidth > 360; // More conservative threshold for text

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                // Larger Logo
                Container(
                  padding: const EdgeInsets.all(AppColors.s12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.maps_home_work_rounded, color: AppColors.primary, size: 28),
                ),
                if (showLogoText) ...[
                  const SizedBox(width: 12),
                  Text('Nestora',
                      style: TextStyle(
                          fontSize: screenWidth < 360 ? 24 : 28, 
                          fontWeight: FontWeight.w900, 
                          letterSpacing: -1.2,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                ],
                const Spacer(),
                
                // ── Notification Bell (Glass Circle) ──
                Consumer(builder: (context, ref, _) {
                  final notifications = ref.watch(userNotificationsProvider);
                  final unreadCount = notifications.maybeWhen(
                    data: (list) => list.where((n) => !n.isRead).length,
                    orElse: () => 0,
                  );
                  
                  return GestureDetector(
                    onTap: () => context.push(AppRouter.notifications),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.notifications_none_rounded, 
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, 
                            size: 24
                          ),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 2, top: 2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              child: Text(
                                unreadCount > 9 ? '9+' : '$unreadCount',
                                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),

                const SizedBox(width: 12),

                // ── Profile Avatar (Glass Circle) ──
                GestureDetector(
                  onTap: () => context.push(AppRouter.profile),
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Icon(Icons.person_outline_rounded, size: 24, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              // ── Location Selector (Below Header) ──
              Consumer(builder: (context, ref, _) {
                final locState = ref.watch(userLocationProvider);
                return GestureDetector(
                  onTap: () => ref.read(userLocationProvider.notifier).updateLocation(),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        locState.isLoading ? 'Locating...' : (locState.city ?? 'Anywhere'),
                        style: TextStyle(
                          fontSize: 14, 
                          fontWeight: FontWeight.w800, 
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.primary),
                    ],
                  ),
                ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  TAB 1 – PROPERTY
// ══════════════════════════════════════════════════════════════
class _PropertyTab extends ConsumerStatefulWidget {
  final bool isDark;
  const _PropertyTab({required this.isDark, super.key});
  @override
  ConsumerState<_PropertyTab> createState() => _PropertyTabState();
}

class _PropertyTabState extends ConsumerState<_PropertyTab> {

  // Raw English key — used for filter logic (independent of locale display)
  String _selectedCat = 'Trending';

  // English labels matching the category pills (must stay in sync with pill list)
  static const _catKeys = ['Trending', 'Luxe', 'Apartments', 'Villas', 'Commercial', 'Plots'];



  @override
  void initState() {
    super.initState();

    
    // CRITICAL: Trigger initial load so properties aren't invisible on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paginatedListingsProvider.notifier).loadInitial(filter: _activeFilter());
    });
  }


  /// Build a filter from the current subtab + category combination.
  ListingFilter _activeFilter() {
    final locState = ref.read(userLocationProvider);
    
    // --- Category mapping ---
    String? propertyType;
    double? minPrice;
    double? maxPrice;
    bool? isVerified;

    switch (_selectedCat) {
      case 'Trending':
        isVerified = null;          // Show all, no strict verification filter
        break;
      case 'Luxe':
        minPrice = 80000;           // High-end properties
        break;
      case 'Apartments':
        propertyType = 'Apartment';
        break;
      case 'Villas':
        propertyType = 'Villa';
        break;
      case 'Commercial':
        propertyType = 'Commercial';
        break;
      case 'Plots':
        propertyType = 'Plot';      // Demoed as Plot type
        break;
    }

    // --- Default to Rent logic for price capping ---
    maxPrice = maxPrice ?? 150000;

    return ListingFilter(
      minPrice: minPrice,
      maxPrice: maxPrice,
      city: locState.city,
      userLat: locState.position?.latitude,
      userLng: locState.position?.longitude,
      propertyType: propertyType,
      isVerified: isVerified,
    );
  }



  void _onCatSelected(String catKey) {
    if (_selectedCat == catKey) return;
    setState(() => _selectedCat = catKey);
    ref.read(paginatedListingsProvider.notifier).loadInitial(filter: _activeFilter());
  }

  @override
  void dispose() { super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state   = ref.watch(paginatedListingsProvider);
    final isDark  = widget.isDark;
    final bg      = Theme.of(context).scaffoldBackgroundColor;
    final card    = isDark ? AppColors.surfaceDark : Colors.white;
    final txt     = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final sub     = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification) {
              if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 400) {
                ref.read(paginatedListingsProvider.notifier).loadMore();
              }
            }
            return false;
          },
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.read(paginatedListingsProvider.notifier).loadInitial(),
            child: CustomScrollView(
            primary: false,
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // ── Banner, Search & Header ──────────────────
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      children: [
                        // ── Premium Mini Banner ──────────────────────
                        Container(
                          margin: const EdgeInsets.fromLTRB(AppColors.s24, 16, AppColors.s24, 16),
                          padding: const EdgeInsets.symmetric(horizontal: AppColors.s16, vertical: 14),
                          decoration: BoxDecoration(
                            color: card,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                          ),
                          child: Row(children: [
                            const Icon(Icons.verified_user_rounded, color: Colors.blueAccent, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(AppLocalizations.of(context)!.zeroBrokerageVerified,
                                style: TextStyle(color: sub, fontSize: 11, fontWeight: FontWeight.w700))),
                            TextButton(
                              onPressed: () => context.push(AppRouter.postProperty),
                              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                              child: Text(AppLocalizations.of(context)!.postFree, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 11)),
                            ),
                          ]),
                        ),

                        // Space before next section
                        const SizedBox(height: 8),

                        const SizedBox(height: 8),

                        // ── Roommate Finder Card ──────────────────
                        GestureDetector(
                          onTap: () => context.push(AppRouter.roommateFeed),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: AppColors.s24, vertical: 12),
                            width: double.infinity,
                            constraints: const BoxConstraints(minHeight: 180),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                                  blurRadius: 25,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  right: -10,
                                  bottom: -10,
                                  child: Icon(
                                    Icons.people_alt_rounded,
                                    size: 160,
                                    color: Colors.white.withOpacity(0.12),
                                  ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                                   .rotate(begin: -0.02, end: 0.02, duration: 3.seconds, curve: Curves.easeInOut),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(28),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Text(
                                          'NEW FEATURE',
                                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight:
                                          FontWeight.w900, letterSpacing: 1),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Roommate Finder',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.8,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Find your perfect soulmate\nto live with.',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Start Matching',
                                              style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF3B82F6), fontSize: 13),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF3B82F6)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.05),
                        ),

                        const SizedBox(height: 16),

                        // ── Smart Tools Section ──────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(AppColors.s24, AppColors.s24, AppColors.s24, AppColors.s12),
                          child: Text('Smart Tools',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5, color: txt)),
                        ),
                        SizedBox(
                          height: 160,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: AppColors.s24),
                            children: [
                              _SmartToolCard(
                                title: 'AR Measurement',
                                subtitle: 'Check if it fits',
                                icon: Icons.straighten_rounded,
                                color: AppColors.accentBlue,
                                onTap: () => context.push(AppRouter.arMeasurement),
                                isDark: isDark,
                              ),
                              _SmartToolCard(
                                title: 'Lease Generator',
                                subtitle: 'Instant agreement',
                                icon: Icons.description_outlined,
                                color: AppColors.accentTeal,
                                onTap: () => context.push(AppRouter.leaseGenerator),
                                isDark: isDark,
                              ),
                              _SmartToolCard(
                                title: 'Emergency Help',
                                subtitle: 'Rapid assistance',
                                icon: Icons.emergency_rounded,
                                color: AppColors.error,
                                onTap: () => context.push(AppRouter.emergencyHelp),
                                isDark: isDark,
                              ),
                              _SmartToolCard(
                                title: 'Move-in Calculator',
                                subtitle: 'Estimate setup costs',
                                icon: Icons.calculate_rounded,
                                color: AppColors.accentOrange,
                                onTap: () => context.push(AppRouter.moveInCalculator),
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),

                        // ── Featured carousel header ──────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(AppColors.s24, AppColors.s32, AppColors.s24, AppColors.s16),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text(AppLocalizations.of(context)!.featuredProperties,
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5, color: txt)),
                            GestureDetector(
                              onTap: () => context.push(AppRouter.search),
                              child: Row(children: [
                                Text(AppLocalizations.of(context)!.viewAll, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 13)),
                                const SizedBox(width: 2),
                                const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 18),
                              ]),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
  // ── Featured horizontal cards (full width gallery feel) ─────────────
                      SliverToBoxAdapter(
                        child: (state.isLoading && state.items.isEmpty)
                            ? LayoutBuilder(
                                builder: (context, constraints) {
                                  final height = (constraints.maxWidth * 1.2).clamp(300.0, 480.0);
                                  return SizedBox(
                                    height: height,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                                      itemCount: 3,
                                      separatorBuilder: (_, __) => AppSpacing.h12,
                                      itemBuilder: (_, __) => ListingCardSkeleton(width: constraints.maxWidth * 0.7),
                                    ),
                                  );
                                },
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  final height = (constraints.maxWidth * 1.2).clamp(300.0, 480.0);
                                  final cardWidth = (constraints.maxWidth * 0.75).clamp(250.0, 320.0);
                                  
                                  return Center(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 1100),
                                      child: SizedBox(
                                        height: height,
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                                          physics: const BouncingScrollPhysics(),
                                          itemCount: state.items.take(8).length,
                                          separatorBuilder: (_, __) => AppSpacing.h12,
                                          itemBuilder: (ctx, i) => ListingCard(
                                              listing: state.items[i], 
                                              width: cardWidth,
                                              heroPrefix: 'featured_listing',
                                              margin: const EdgeInsets.only(right: 4)),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),

                      SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1100),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Available now header ──────────────────
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
                                  child: Text('Available now',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                                          letterSpacing: -0.4, color: txt)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      if (state.items.isEmpty && !state.isLoading)
                        SliverToBoxAdapter(
                          child: Consumer(
                            builder: (context, ref, _) {
                              final city = ref.watch(userLocationProvider).city;
                              return Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 40),
                                    Icon(Icons.home_work_rounded, size: 72, color: AppColors.primary.withOpacity(0.3)),
                                    const SizedBox(height: 20),
                                    Text(
                                      city != null ? 'No properties in $city' : 'No properties found',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      city != null
                                          ? 'Showing nearby listings instead. Try expanding your search.'
                                          : 'Try adjusting your filters or location.',
                                      style: TextStyle(color: Theme.of(context).hintColor, fontSize: 14),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),
                                    OutlinedButton.icon(
                                      onPressed: () => ref.read(paginatedListingsProvider.notifier).loadInitial(),
                                      icon: const Icon(Icons.refresh_rounded),
                                      label: const Text('Show all listings'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        side: const BorderSide(color: AppColors.primary),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      ),
                                    ),
                                    const SizedBox(height: 40),
                                  ],
                                ),
                              );
                            },
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          sliver: SliverLayoutBuilder(
                            builder: (context, sliverConstraints) {
                              // SliverLayoutBuilder always gives finite crossAxisExtent
                              final screenWidth = sliverConstraints.crossAxisExtent;
                              final effectiveWidth = screenWidth.isFinite
                                  ? screenWidth.clamp(0.0, 1100.0)
                                  : 800.0; // safe fallback
                              final cols = effectiveWidth > 700 ? 3 : (effectiveWidth > 450 ? 2 : 1);
                              final cardWidth = (effectiveWidth - (cols - 1) * 12) / cols;
                              return SliverGrid(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  mainAxisExtent: cols == 1 ? 520 : 500,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (ctx, i) {
                                    if (i == state.items.length) {
                                      return const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: CircularProgressIndicator(
                                              color: AppColors.primary),
                                        ),
                                      );
                                    }
                                    final listing = state.items[i];
                                    // Data-integrity guard: skip invalid listings
                                    if (listing.title.trim().isEmpty || listing.price <= 0) {
                                      return const SizedBox.shrink();
                                    }
                                    return ListingCard(
                                      listing: listing,
                                      isVerticalFeed: true,
                                      heroPrefix: 'available_listing',
                                      margin: EdgeInsets.zero,
                                    );
                                  },
                                  childCount: state.items.length + (state.hasMore ? 1 : 0),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      
      // ── Floating "Show Map" button (Airbnb Style) ──────────────────────────
      Positioned(
        bottom: 110,
        left: 0,
        right: 0,
        child: Center(
          child: GestureDetector(
            onTap: () => context.push(AppRouter.map),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ColorFilter.mode(Colors.black.withOpacity(0.1), BlendMode.darken),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222222).withOpacity(0.95), // Premium dark
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(color: Colors.black45, blurRadius: 20, offset: const Offset(0, 10))
                    ],
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       Text(AppLocalizations.of(context)?.showMap ?? 'Show map', 
                        style: const TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.w900, 
                          fontSize: 14,
                          letterSpacing: -0.2,
                        ),
                      ),
                       const SizedBox(width: 10),
                       const Icon(Icons.map_rounded, size: 20, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ).animate().fadeIn(duration: 800.ms, delay: 1.seconds).scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
      ),
    ],
  );
}

  Widget _feat(IconData icon, String text) => Row(children: [
    Icon(icon, size: 13, color: Colors.white60),
    const SizedBox(width: 6),
    Text(text, style: const TextStyle(color: Colors.white60, fontSize: 12)),
  ]);
}

// Internal helpers removed in favor of ListingCard.dart

// ══════════════════════════════════════════════════════════════
//  TAB 2 – HOME SERVICES
// ══════════════════════════════════════════════════════════════
class _HomeServicesTab extends StatelessWidget {
  final bool isDark;
  const _HomeServicesTab({required this.isDark, super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      primary: false,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Premium Hero Banner ──
          ServiceHeroBanner(
            isDark: isDark,
            onSearchTap: () {
               // Placeholder for category search
            },
          ),

          // ── Featured Carousel ──
          FeaturedServicesCarousel(
            isDark: isDark,
            services: ServicesData.featuredServices,
            onTap: (service) => _openDetail(context, service, 'featured_service'),
          ),

          const SizedBox(height: 24),

          // ── Categorized Sections ──
          ...ServicesData.categories.map((cat) {
            final services = ServicesData.getByCategory(cat).cast<HomeService>();
            if (services.isEmpty) return const SizedBox.shrink();
            
            return ServiceCategorySection(
              title: cat,
              isDark: isDark,
              children: services.map((s) {
                final prefix = 'category_${cat.toLowerCase().replaceAll(' ', '_')}';
                return ServiceCard(
                  service: s,
                  isDark: isDark,
                  heroPrefix: prefix,
                  onTap: () => _openDetail(context, s, prefix),
                  onBookNow: () => _openDetail(context, s, prefix),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, HomeService service, String heroPrefix) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceDetailPage(
          service: service, 
          isDark: isDark,
          heroPrefix: heroPrefix,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  TAB 3 – PAYMENTS
// ══════════════════════════════════════════════════════════════
class _PaymentsTab extends StatefulWidget {
  final bool isDark;
  const _PaymentsTab({required this.isDark, super.key});
  @override
  State<_PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<_PaymentsTab> {
  static const _methods = [
    {'label': 'to Contact',      'icon': Icons.contacts_rounded},
    {'label': 'to UPI',          'icon': Icons.payments_rounded},
    {'label': 'to Bank\nAccount','icon': Icons.account_balance_rounded},
  ];

  static const _bills = [
    {'label': 'House\nRent',            'icon': Icons.home_rounded},
    {'label': 'School\nFee',            'icon': Icons.school_rounded},
    {'label': 'Society\nMaintenance',   'icon': Icons.apartment_rounded},
    {'label': 'Tuition\nFee',           'icon': Icons.menu_book_rounded},
    {'label': 'Office/Shop\nRent',      'icon': Icons.business_rounded},
    {'label': 'Property\nTax',          'icon': Icons.vpn_key_rounded},
    {'label': 'Property\nSecurity',     'icon': Icons.security_rounded},
    {'label': 'Utility\nBills',         'icon': Icons.electrical_services_rounded},
  ];

  void _pay(String method) => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => _PaySheet(method: method, isDark: widget.isDark),
  );

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final card = isDark ? AppColors.surfaceDark : Colors.white;
    final txt = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return SingleChildScrollView(
      primary: false,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // ── Premium Hero (Full Width) ──────────────────────────────
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: AppColors.s24, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark 
                  ? [const Color(0xFF0D0D0D), const Color(0xFF1C1C1C)]
                  : [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 25, offset: const Offset(0, 10))
              ],
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Stack(children: [
                  Positioned(
                    right: -30, top: -20,
                    child: Icon(Icons.credit_card_rounded, size: 200, color: Colors.white.withOpacity(0.03)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppColors.s32),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Payments & Finance',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5)),
                      const SizedBox(height: 6),
                      Text('Secure & instant zero-brokerage payments',
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w600, fontSize: 13)),
                      
                      const SizedBox(height: 32),
                      Row(children: _methods.asMap().entries.map((e) {
                        final m = e.value;
                        return Expanded(child: GestureDetector(
                          onTap: () => _pay(m['label'] as String),
                          child: Container(
                            margin: EdgeInsets.only(right: e.key < 2 ? 12 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Column(children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                                child: Icon(m['icon'] as IconData, size: 22, color: Colors.white),
                              ),
                              const SizedBox(height: 10),
                              Text(m['label'] as String, textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white,
                                      fontWeight: FontWeight.w800, fontSize: 11, height: 1.2)),
                            ]),
                          ),
                        ));
                      }).toList()),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
    
          // ── Centered body ──
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
    
                  // ── Instant Cash (Cred style) ──────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppColors.s24),
                    child: Container(
                      padding: const EdgeInsets.all(AppColors.s24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark 
                            ? [const Color(0xFF1E1E24), const Color(0xFF141418)]
                            : [const Color(0xFFF8F9FA), const Color(0xFFECEFF1)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 8))],
                      ),
                      child: Row(children: [
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(color: const Color(0xFF1AA89B).withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
                          child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF1AA89B), size: 30),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Instant Credit Line',
                              style: TextStyle(fontWeight: FontWeight.w900, color: txt, fontSize: 16, letterSpacing: -0.3)),
                          const SizedBox(height: 4),
                          Text('Up to ₹5,00,000 disbursement',
                              style: TextStyle(color: subTextColor, fontSize: 13, fontWeight: FontWeight.w600)),
                        ])),
                        const Icon(Icons.chevron_right_rounded, color: Color(0xFF1AA89B)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 8),
    
                  // ── Bill Section Header ────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Utility & Rent Bills',
                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: txt, letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text('Earn cashback on every bill payment',
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.w600)),
                    ]),
                  ),
    
                  const SizedBox(height: 8),
    
                  // ── Elegant Bill Grid ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppColors.s24),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 700 ? 6 : 4;
                        return GridView.builder(
                          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount, 
                              childAspectRatio: 0.7, // More vertical space for text
                              crossAxisSpacing: AppColors.s16, 
                              mainAxisSpacing: AppColors.s24),
                          itemCount: _bills.length,
                          itemBuilder: (ctx, i) {
                            final b = _bills[i];
                            return GestureDetector(
                              onTap: () => _pay((b['label'] as String).replaceAll('\n', ' ')),
                              child: Column(children: [
                                Container(
                                  width: constraints.maxWidth > 400 ? 64 : 52,
                                  height: constraints.maxWidth > 400 ? 64 : 52,
                                  decoration: BoxDecoration(
                                      color: card,
                                      borderRadius: BorderRadius.circular(constraints.maxWidth > 400 ? 24 : 18),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.06), blurRadius: 10, offset: const Offset(0, 4))
                                      ],
                                      border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03))),
                                  child: Center(
                                    child: Icon(b['icon'] as IconData, size: constraints.maxWidth > 400 ? 28 : 22, color: AppColors.primary),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(b['label'] as String, textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                                        color: txt, height: 1.1)),
                              ]),
                            );
                          },
                        );
                      }
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}

// ── Payment bottom sheet ──────────────────────────────────────
class _PaySheet extends StatefulWidget {
  final String method;
  final bool isDark;
  const _PaySheet({required this.method, required this.isDark});
  @override State<_PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends State<_PaySheet> {
  final _amt = TextEditingController();
  final _note = TextEditingController();
  final _field1 = TextEditingController(); // Card Num / UPI ID
  final _field2 = TextEditingController(); // Expiry / CVV
  int _methodIdx = 0; // 0: Card, 1: UPI, 2: NetBanking
  bool _loading = false;

  @override
  void dispose() { 
    _amt.dispose(); _note.dispose(); 
    _field1.dispose(); _field2.dispose(); 
    super.dispose(); 
  }

  void _submit() async {
    if (_amt.text.isEmpty) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.pop(context);
    
    final method = _methodIdx == 0 ? 'Card' : _methodIdx == 1 ? 'UPI' : 'Net Banking';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Payment of ₹${_amt.text} via $method initiated!'),
        backgroundColor: AppColors.success));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final txt = isDark ? Colors.white : const Color(0xFF1A1A1A);
    
    return Container(
      decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
      padding: EdgeInsets.only(left: AppColors.s24, right: AppColors.s24, top: AppColors.s24,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppColors.s32),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 24),
        Text('Pay ${widget.method}', style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w900, color: txt, letterSpacing: -0.5)),
        const SizedBox(height: 24),
        
        // Payment Method Selector
        Row(children: [
          _methodBtn(0, Icons.credit_card_rounded, 'Card'),
          const SizedBox(width: 8),
          _methodBtn(1, Icons.qr_code_scanner_rounded, 'UPI'),
          const SizedBox(width: 8),
          _methodBtn(2, Icons.account_balance_rounded, 'NetBank'),
        ]),
        
        const SizedBox(height: 24),
        _tf('Amount (₹)', _amt, TextInputType.number, isDark),
        const SizedBox(height: 12),
        
        // Dynamic Fields
        if (_methodIdx == 0) ...[
          _tf('Card Number', _field1, TextInputType.number, isDark, icon: Icons.credit_card),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _tf('MM/YY', _field2, TextInputType.datetime, isDark)),
            const SizedBox(width: 12),
            Expanded(child: _tf('CVV', TextEditingController(), TextInputType.number, isDark, obscure: true)),
          ]),
        ] else if (_methodIdx == 1) ...[
          _tf('UPI ID (e.g., name@upi)', _field1, TextInputType.emailAddress, isDark, icon: Icons.alternate_email_rounded),
        ] else ...[
          _tf('Bank Name', _field1, TextInputType.text, isDark, icon: Icons.account_balance_rounded),
        ],

        const SizedBox(height: 12),
        _tf('Note (optional)', _note, TextInputType.text, isDark),
        const SizedBox(height: 28),
        
        GestureDetector(
          onTap: _loading ? null : _submit,
          child: Container(
            width: double.infinity, height: 64, alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: _loading
                ? const SizedBox(width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                : const Text('PROCEED TO PAY',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0)),
          ),
        ),
      ]),
    );
  }

  Widget _methodBtn(int idx, IconData icon, String label) {
    final sel = _methodIdx == idx;
    final isDark = widget.isDark;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _methodIdx = idx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? AppColors.primary.withOpacity(0.1) : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? AppColors.primary : Colors.transparent, width: 1.5),
          ),
          child: Column(children: [
            Icon(icon, size: 20, color: sel ? AppColors.primary : (isDark ? Colors.white38 : Colors.black38)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w800,
              color: sel ? AppColors.primary : (isDark ? Colors.white38 : Colors.black38))),
          ]),
        ),
      ),
    );
  }

  Widget _tf(String hint, TextEditingController c, TextInputType t, bool dark, {IconData? icon, bool obscure = false}) => TextField(
    controller: c, keyboardType: t, obscureText: obscure,
    style: TextStyle(color: dark ? Colors.white : Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
    decoration: InputDecoration(
      prefixIcon: icon != null ? Icon(icon, size: 18, color: dark ? Colors.white24 : Colors.black26) : null,
      hintText: hint,
      hintStyle: TextStyle(color: dark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3), fontSize: 14),
      filled: true,
      fillColor: dark ? const Color(0xFF252525) : const Color(0xFFF8F9FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    ),
  );
}

// ── Custom Sliver Floating Header Delegate ────────────────────────
class SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  SliverHeaderDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 80;
  @override
  double get minExtent => 80;

  @override
  bool shouldRebuild(SliverHeaderDelegate oldDelegate) => true;
}

class _SmartToolCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _SmartToolCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final safeColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer.standard(
        context: context,
        width: 160,
        borderRadius: 24,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: safeColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: safeColor, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ).animate()
       .fadeIn(duration: 400.ms, delay: 200.ms)
       .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), curve: Curves.easeOutBack),
    );
  }
}


