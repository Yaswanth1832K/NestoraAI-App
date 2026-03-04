import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/features/listings/presentation/providers/paginated_listings_notifier.dart';
import 'package:house_rental/features/home/presentation/widgets/listing_card.dart';
import 'package:house_rental/features/home/presentation/widgets/listing_card_skeleton.dart';
import 'package:house_rental/features/listings/domain/repositories/listing_repository.dart';
import 'package:house_rental/core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:house_rental/core/widgets/glass_container.dart';
import 'package:house_rental/features/listings/presentation/pages/listing_details_page.dart';
import 'package:house_rental/main.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:house_rental/core/theme/app_colors.dart';

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
      ref.read(paginatedListingsProvider.notifier).loadInitial();
    });
  }

  // ── 3 top-level tab cards ─────────────────────────────────
  Widget _topTabs(bool isDark) {
    final tabs = [
      {'label': 'Property',      'icon': Icons.home_rounded},
      {'label': 'Home Services', 'icon': Icons.handyman_rounded},
      {'label': 'Payments',      'icon': Icons.credit_card_rounded},
    ];
    final activeBg   = AppColors.primary;
    final inactiveBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight2;
    final activeTxt  = Colors.white;
    final inactiveTxt= isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppColors.s24, AppColors.s24, AppColors.s24, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Row(
              children: List.generate(tabs.length, (i) {
                final sel = _mainTab == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _mainTab = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: sel ? activeBg : Colors.transparent,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(tabs[i]['icon'] as IconData,
                              size: 18, color: sel ? activeTxt : inactiveTxt),
                          const SizedBox(width: 8),
                          Text(tabs[i]['label'] as String,
                              style: TextStyle(
                                  fontSize: 14, fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                                  color: sel ? activeTxt : inactiveTxt)),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
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
      body: SafeArea(
        child: Column(
          children: [
            // Center LogoBar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppColors.s24),
              child: _LogoBar(isDark: isDark),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: _topTabs(isDark),
              ),
            ),
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
    );
  }
}

// ── Logo header bar ───────────────────────────────────────────
class _LogoBar extends StatelessWidget {
  final bool isDark;
  const _LogoBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppColors.s24, vertical: AppColors.s24),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(AppColors.s8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.maps_home_work_rounded, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Text('Nestora',
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -1.2,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push(AppRouter.profile),
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 1),
                ),
                child: Center(child: Icon(Icons.person_rounded, size: 22, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
              ),
            ),
          ]),
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
  int _sub = 1;   // 0=Buy  1=Rent  2=Commercial
  final _scroll = ScrollController();
  String _selectedCat = 'Trending';

  static const _subtabs  = ['Buy', 'Rent', 'Commercial'];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      ref.read(paginatedListingsProvider.notifier).loadMore();
    }
  }

  void _onCatSelected(String cat) {
    if (_selectedCat == cat) return;
    setState(() => _selectedCat = cat);
    
    // Trigger real filter logic
    ref.read(paginatedListingsProvider.notifier).loadInitial(
      filter: ListingFilter(
        propertyType: (cat == 'Trending' || cat == 'Luxe') ? null : cat,
        isVerified: cat == 'Trending' ? true : null,
        maxPrice: cat == 'Luxe' ? 500000 : null,
      ),
    );
  }

  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

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
        Container(
          width: double.infinity,
          color: isDark ? const Color(0xFF141414) : Colors.white,
          child: Column(
            children: [
              // ── Centered Tagline ──
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text('100% Owner Properties · Zero Brokerage',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                    ),
                  ),
                ),
              ),

              // ── Subtabs (Buy/Rent/Commercial) ──────────────────
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppColors.s24),
                    child: Row(
                      children: _subtabs.asMap().entries.map((e) {
                          final isSel = _sub == e.key;
                          return Expanded(child: GestureDetector(
                            onTap: () => setState(() => _sub = e.key),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: isSel ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(color: isSel ? AppColors.primary : AppColors.borderLight),
                              ),
                              margin: EdgeInsets.only(right: e.key < 2 ? AppColors.s12 : 0),
                              child: Text(e.value, textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 14, fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                      color: isSel ? Colors.white : AppColors.textSecondaryLight)),
                            ),
                          ));
                        }).toList(),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Category Pills (Subtle & Functional) ──────────────────
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: SizedBox(
                    height: 52,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppColors.s24, vertical: 4),
                      children: ['Trending', 'Luxe', 'Apartments', 'Villas', 'Commercial', 'Plots'].map((c) {
                        final sel = _selectedCat == c;
                        return Padding(
                          padding: const EdgeInsets.only(right: AppColors.s12),
                          child: FilterChip(
                            label: Text(c),
                            selected: sel,
                            onSelected: (v) => _onCatSelected(c),
                            backgroundColor: isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight2,
                            selectedColor: AppColors.primary,
                            checkmarkColor: Colors.white,
                            showCheckmark: false,
                            labelStyle: TextStyle(
                              color: sel ? Colors.white : AppColors.textSecondaryLight,
                              fontSize: 13, fontWeight: sel ? FontWeight.w800 : FontWeight.w600),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                              side: BorderSide(
                                color: sel ? AppColors.primary : AppColors.borderLight,
                                width: 1,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              // ── Scrollable body (full width scroll, centered slivers) ──────────────────
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => ref.read(paginatedListingsProvider.notifier).loadInitial(),
                  child: CustomScrollView(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1100),
                            child: Column(
                              children: [
                                // ── Premium Mini Banner ──────────────────────
                                Container(
                                  margin: const EdgeInsets.fromLTRB(AppColors.s24, AppColors.s8, AppColors.s24, 0),
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
                                    Expanded(child: Text('Zero brokerage properties verified by Nestora',
                                        style: TextStyle(color: sub, fontSize: 11, fontWeight: FontWeight.w700))),
                                    TextButton(
                                      onPressed: () => context.push(AppRouter.postProperty),
                                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                                      child: const Text('Post Free', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 11)),
                                    ),
                                  ]),
                                ),

                                // ── Search & Filter Bar ───────────────────────────
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(AppColors.s24, AppColors.s16, AppColors.s24, 0),
                                  child: Row(children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => context.push(AppRouter.search),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: AppColors.s24, vertical: 14),
                                          decoration: BoxDecoration(
                                            color: card,
                                            borderRadius: BorderRadius.circular(32),
                                            border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08)),
                                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
                                          ),
                                          child: Row(children: [
                                            Icon(Icons.search_rounded, size: 20, color: AppColors.primary),
                                            const SizedBox(width: 12),
                                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                              Text('Where to?', style: TextStyle(color: txt, fontSize: 13, fontWeight: FontWeight.w900)),
                                              Text('Anywhere · Any week · Add guests', style: TextStyle(color: sub, fontSize: 11, fontWeight: FontWeight.w500)),
                                            ])),
                                          ]),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    GestureDetector(
                                      onTap: () => context.push(AppRouter.search),
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: card,
                                          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                                        ),
                                        child: Icon(Icons.tune_rounded, size: 20, color: txt),
                                      ),
                                    ),
                                  ]),
                                ),

                                const SizedBox(height: 16),

                                // ── Featured carousel header ──────────────
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(AppColors.s24, AppColors.s32, AppColors.s24, AppColors.s16),
                                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                    Text('Featured Properties',
                                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                                            letterSpacing: -0.5, color: txt)),
                                    GestureDetector(
                                      onTap: () => context.push(AppRouter.search),
                                      child: const Row(children: [
                                        Text('View all', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 13)),
                                        SizedBox(width: 2),
                                        Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 18),
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
                            ? SizedBox(height: 480, child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: 3, separatorBuilder: (_, __) => const SizedBox(width: 14),
                                itemBuilder: (_, __) => const ListingCardSkeleton(width: 200),
                              ))
                            : Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 1100),
                                child: SizedBox(
                                    height: 480,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: state.items.take(8).length,
                                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                                      itemBuilder: (ctx, i) => ListingCard(
                                          listing: state.items[i], margin: const EdgeInsets.only(right: 14)),
                                    ),
                                  ),
                              ),
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

                      // ── Compact list ──────────────────────────
                      if (state.items.isEmpty && !state.isLoading)
                        SliverToBoxAdapter(
                          child: Center(child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(children: [
                              Icon(Icons.home_work_outlined, size: 60,
                                  color: isDark ? Colors.white12 : Colors.black12),
                              const SizedBox(height: 12),
                              Text('No properties yet',
                                  style: TextStyle(color: isDark ? Colors.white38 : Colors.black38,
                                      fontWeight: FontWeight.w600)),
                            ]),
                          )),
                        )
                      else
                        SliverToBoxAdapter(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1100),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                                child: Column(
                                  children: List.generate(state.items.length + (state.hasMore ? 1 : 0), (i) {
                                    if (i == state.items.length) {
                                      return const Padding(padding: EdgeInsets.all(24),
                                          child: Center(child: CircularProgressIndicator(color: AppColors.primary)));
                                    }
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: ListingCard(
                                          listing: state.items[i],
                                          isVerticalFeed: true,
                                          margin: EdgeInsets.zero,
                                        ),
                                      );
                                  }),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      
      // ── Floating "Show Map" button ──────────────────────────
      Positioned(
        bottom: 32,
        left: 0,
        right: 0,
        child: Center(
          child: GestureDetector(
            onTap: () => context.push(AppRouter.map),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF222222), // Airbnb dark map button
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text('Show map', 
                    style: TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.w900, 
                      fontSize: 14,
                      letterSpacing: -0.2,
                    ),
                  ),
                   SizedBox(width: 10),
                   Icon(Icons.map_rounded, size: 20, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
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

  static const _services = [
    {'name': 'Instant\nServices',        'icon': Icons.flash_on_rounded,           'color': Color(0xFFFF6B35), 'sub': '15 mins'},
    {'name': 'Home\nCleaning',           'icon': Icons.cleaning_services_rounded,  'color': Color(0xFF00B4D8), 'sub': '60% Off'},
    {'name': 'Packers\n& Movers',        'icon': Icons.local_shipping_rounded,     'color': Color(0xFFE76F51), 'sub': 'Safe Move'},
    {'name': 'AC Service\n& Appliances', 'icon': Icons.ac_unit_rounded,            'color': Color(0xFF48CAE4), 'sub': 'Hot Deal'},
    {'name': 'Plumbing &\nElectrician',  'icon': Icons.plumbing_rounded,           'color': Color(0xFF2D6A4F), 'sub': 'Certified'},
    {'name': 'Home\nPainting',           'icon': Icons.format_paint_rounded,       'color': Color(0xFFFB8500), 'sub': '25% Off'},
    {'name': 'Rent\nAgreement',          'icon': Icons.gavel_rounded,              'color': Color(0xFF6D6875), 'sub': '30% Off'},
    {'name': 'Home\nInteriors',          'icon': Icons.chair_rounded,              'color': Color(0xFF774936), 'sub': 'Premium'},
  ];

  @override
  Widget build(BuildContext context) {
    final card = isDark ? AppColors.surfaceDark : Colors.white;
    final txt = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Full-width Teal hero with centered content ──
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: AppColors.s24, vertical: AppColors.s24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryGlow],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 25, offset: const Offset(0, 10))
              ],
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Text('FOR ALL YOUR', style: TextStyle(color: Colors.white70,
                        fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 4)),
                    SizedBox(height: 12),
                    Text('URGENT NEEDS', style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w900, fontSize: 32, letterSpacing: -1.0)),
                  ]),
                ),
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
                  // ── Search ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08))),
                      child: Row(children: [
                        Icon(Icons.search_rounded, size: 20, color: isDark ? Colors.white38 : Colors.black38),
                        const SizedBox(width: 10),
                        Text('Search Kitchen Cleaning...',
                            style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14)),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Adaptive service grid ────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 700 ? 6 : 4;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount, childAspectRatio: 0.72,
                              crossAxisSpacing: 10, mainAxisSpacing: 10),
                          itemCount: _services.length,
                          itemBuilder: (ctx, i) {
                            final s = _services[i];
                            return GestureDetector(
                              onTap: () => context.push(AppRouter.serviceBooking,
                                  extra: {'serviceName': (s['name'] as String).replaceAll('\n', ' '),
                                          'serviceIcon': s['icon'], 'badge': s['sub']}),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.surfaceDark2 : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Container(width: 40, height: 40,
                                    decoration: BoxDecoration(
                                        color: (s['color'] as Color).withOpacity(0.12), shape: BoxShape.circle),
                                    child: Icon(s['icon'] as IconData, size: 20, color: s['color'] as Color),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(s['name'] as String, textAlign: TextAlign.center, maxLines: 3,
                                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white70 : const Color(0xFF1A1A1A), height: 1.2)),
                                  const SizedBox(height: 3),
                                  Text(s['sub'] as String, textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600,
                                          color: s['color'] as Color)),
                                ]),
                              ),
                            );
                          },
                        );
                      }
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── VIP upsell banner ────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06))),
                      child: Row(children: [
                        Container(width: 38, height: 38,
                          decoration: const BoxDecoration(color: Color(0xFF2C2C2C), shape: BoxShape.circle),
                          child: const Center(child: Text('VIP',
                              style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 9)))),
                        const SizedBox(width: 12),
                        Expanded(child: RichText(text: TextSpan(children: [
                          TextSpan(text: 'Save upto ',
                              style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 13)),
                          const TextSpan(text: '15% off',
                              style: TextStyle(color: Color(0xFF1AA89B), fontWeight: FontWeight.w900, fontSize: 13)),
                          TextSpan(text: ' on Home Services\nStarting @ ₹199 ',
                              style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 12)),
                          const TextSpan(text: '₹599',
                              style: TextStyle(color: Colors.grey,
                                  decoration: TextDecoration.lineThrough, fontSize: 12)),
                        ]))),
                        Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white38 : Colors.black38),
                      ]),
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
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Premium Hero (Full Width) ──────────────────────────────
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: AppColors.s24, vertical: AppColors.s24),
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
                  const SizedBox(height: 24),
    
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
    
                  const SizedBox(height: 32),
    
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
    
                  const SizedBox(height: 20),
    
                  // ── Elegant Bill Grid ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppColors.s24),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 700 ? 6 : 4;
                        return GridView.builder(
                          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount, childAspectRatio: 0.85,
                              crossAxisSpacing: AppColors.s16, mainAxisSpacing: AppColors.s24),
                          itemCount: _bills.length,
                          itemBuilder: (ctx, i) {
                            final b = _bills[i];
                            return GestureDetector(
                              onTap: () => _pay((b['label'] as String).replaceAll('\n', ' ')),
                              child: Column(children: [
                                Container(
                                  width: 64, height: 64,
                                  decoration: BoxDecoration(
                                      color: card,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.06), blurRadius: 10, offset: const Offset(0, 4))
                                      ],
                                      border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03))),
                                  child: Center(
                                    child: Icon(b['icon'] as IconData, size: 28, color: AppColors.primary),
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
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
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
