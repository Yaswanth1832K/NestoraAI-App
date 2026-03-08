import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:house_rental/core/router/app_router.dart';
import 'package:house_rental/core/widgets/glass_container.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/chat/presentation/providers/chat_providers.dart';
import 'package:house_rental/features/listings/presentation/providers/listings_providers.dart';
import 'package:house_rental/features/visit_requests/domain/entities/visit_request_entity.dart';
import 'package:house_rental/features/visit_requests/presentation/providers/visit_request_providers.dart';

class TripsPage extends ConsumerStatefulWidget {
  const TripsPage({super.key});

  @override
  ConsumerState<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends ConsumerState<TripsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF7F7F7),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Trips',
            style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 32,
                letterSpacing: -1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: TabBar(
                controller: _tabCtrl,
                isScrollable: true,
                indicatorColor: primaryColor,
                indicatorWeight: 3,
                dividerColor: Colors.transparent,
                labelColor: isDark ? Colors.white : Colors.black,
                unselectedLabelColor: Colors.grey,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                unselectedLabelStyle:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                tabs: const [
                  Tab(text: 'Trips'),
                  Tab(text: 'Canceled'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: user == null
          ? _buildLoginPrompt(context, primaryColor, isDark)
          : _buildTabBody(context, user.uid, primaryColor, isDark),
    );
  }

  Widget _buildTabBody(BuildContext context, String uid,
      Color primaryColor, bool isDark) {
    final requestsAsync = ref.watch(tenantVisitRequestsProvider(uid));

    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text('Could not load trips\n$err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () =>
                    ref.refresh(tenantVisitRequestsProvider(uid)),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (all) {
        // All non-canceled trips: past, pending, approved
        final trips = all
            .where((r) => r.status != 'cancelled' && r.status != 'canceled')
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        // Canceled: explicitly cancelled
        final canceled = all
            .where((r) => r.status == 'cancelled' || r.status == 'canceled')
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return TabBarView(
          controller: _tabCtrl,
          children: [
            _TripList(
              trips: trips,
              emptyIcon: Icons.map_rounded,
              emptyTitle: 'No trips yet',
              emptySubtitle:
                  "When you're ready to plan your next stay, we're here to help.",
              emptyBtnLabel: 'Explore Nestora',
              primaryColor: primaryColor,
              isDark: isDark,
            ),
            _TripList(
              trips: canceled,
              emptyIcon: Icons.cancel_outlined,
              emptyTitle: 'No canceled trips',
              emptySubtitle: 'All your canceled trips will appear here.',
              emptyBtnLabel: 'Back to home',
              primaryColor: primaryColor,
              isDark: isDark,
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoginPrompt(
      BuildContext context, Color primaryColor, bool isDark) {
    return TabBarView(
      controller: _tabCtrl,
      children: List.generate(
        2,
        (_) => _EmptyTrips(
          icon: Icons.lock_outline_rounded,
          title: 'Login required',
          subtitle: 'Please log in to see your booked trips.',
          btnLabel: 'Log in',
          primaryColor: primaryColor,
          isDark: isDark,
          onTap: () => context.go(AppRouter.login),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Trip list (single tab)
// ─────────────────────────────────────────────────────────────────
class _TripList extends StatelessWidget {
  final List<VisitRequestEntity> trips;
  final IconData emptyIcon;
  final String emptyTitle, emptySubtitle, emptyBtnLabel;
  final Color primaryColor;
  final bool isDark;

  const _TripList({
    required this.trips,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyBtnLabel,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return _EmptyTrips(
        icon: emptyIcon,
        title: emptyTitle,
        subtitle: emptySubtitle,
        btnLabel: emptyBtnLabel,
        primaryColor: primaryColor,
        isDark: isDark,
        onTap: () => context.go(AppRouter.home),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20).copyWith(bottom: 100),
      physics: const BouncingScrollPhysics(),
      itemCount: trips.length,
      itemBuilder: (ctx, i) => _TripCard(trip: trips[i]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Real Trip Card
// ─────────────────────────────────────────────────────────────────
class _TripCard extends ConsumerWidget {
  final VisitRequestEntity trip;
  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final user = ref.watch(authStateProvider).value;

    // Try to get richer listing data (image / price) from the listing provider
    final listingAsync = ref.watch(listingProvider(trip.listingId));

    final statusColor = _statusColor(trip.status);
    final statusLabel = _statusLabel(trip.status);

    // Best available image — prefer listing data if loaded
    final imageUrl = listingAsync.maybeWhen(
      data: (l) =>
          l.allImages.isNotEmpty ? l.allImages.first : trip.listingImage,
      orElse: () => trip.listingImage,
    );

    final priceStr = listingAsync.maybeWhen(
      data: (l) => '₹${NumberFormat('#,##,###').format(l.price.toInt())}/mo',
      orElse: () => '',
    );

    final city = listingAsync.maybeWhen(
      data: (l) => l.city,
      orElse: () => '',
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero image ──────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Stack(
                children: [
                  SizedBox(
                    height: 190,
                    width: double.infinity,
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                                color: isDark
                                    ? const Color(0xFF1A1A1A)
                                    : const Color(0xFFEEEEEE)),
                            errorWidget: (_, __, ___) => Container(
                              color: isDark
                                  ? const Color(0xFF1A1A1A)
                                  : const Color(0xFFEEEEEE),
                              child: const Icon(Icons.home_rounded,
                                  size: 40, color: Colors.grey),
                            ),
                          )
                        : Container(
                            color: isDark
                                ? const Color(0xFF1A1A1A)
                                : const Color(0xFFEEEEEE),
                            child: const Icon(Icons.home_rounded,
                                size: 40, color: Colors.grey),
                          ),
                  ),
                  // Gradient overlay for bottom readability
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.55),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Status badge top-right
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Text(
                        statusLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  // Price badge bottom-left over image
                  if (priceStr.isNotEmpty)
                    Positioned(
                      bottom: 12,
                      left: 14,
                      child: Text(
                        priceStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          shadows: [
                            Shadow(blurRadius: 8, color: Colors.black54)
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Details section ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Property name
                  Text(
                    trip.listingTitle,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        letterSpacing: -0.4),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Location
                  if (city.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 14, color: primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          city,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white60
                                : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Date & time row
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _InfoPill(
                        icon: Icons.calendar_today_rounded,
                        label: DateFormat('EEE, MMM dd yyyy')
                            .format(trip.date),
                        primaryColor: primaryColor,
                        isDark: isDark,
                      ),
                      _InfoPill(
                        icon: Icons.access_time_rounded,
                        label: trip.time,
                        primaryColor: primaryColor,
                        isDark: isDark,
                      ),
                    ],
                  ),

                  // Message (if any)
                  if (trip.message.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        trip.message,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white54
                              : Colors.black45,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // ── Action buttons ──────────────────────────────
                  Row(
                    children: [
                      // Cancel — for pending or approved (future)
                      if (trip.status == 'pending' || trip.status == 'approved') ...[
                        Expanded(
                          child: _ActionBtn(
                            label: 'Cancel',
                            color: Colors.red,
                            onTap: () =>
                                _cancelRequest(context, ref, user?.uid),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],

                      // Reschedule — pending or approved + future date
                      if (trip.status == 'pending' ||
                          (trip.status == 'approved' &&
                              !trip.date.isBefore(DateTime.now())))
                        Expanded(
                          child: _ActionBtn(
                            label: 'Reschedule',
                            color: primaryColor.withOpacity(0.8),
                            onTap: () =>
                                _rescheduleRequest(context, ref),
                          ),
                        ),

                      // Chat — approved trips
                      // Chat — approved trips
                      if (trip.status == 'approved') ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ActionBtn(
                            label: 'Open Chat',
                            color: primaryColor,
                            filled: true,
                            onTap: () => _openChat(context, ref),
                          ),
                        ),
                      ],

                      // View details — past / cancelled
                      if (trip.status == 'rejected' ||
                          trip.status == 'cancelled' ||
                          trip.status == 'canceled' ||
                          trip.date.isBefore(DateTime(DateTime.now().year,
                                  DateTime.now().month, DateTime.now().day)))
                        Expanded(
                          child: _ActionBtn(
                            label: 'View Property',
                            color: primaryColor,
                            filled: true,
                            onTap: () => context.push(AppRouter.search),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────
  Color _statusColor(String s) {
    switch (s) {
      case 'approved': return Colors.green;
      case 'pending':  return Colors.orange;
      case 'rejected': return Colors.red;
      case 'cancelled': 
      case 'canceled': return Colors.grey;
      default: return Colors.blueGrey;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'approved':  return '✓ Confirmed';
      case 'pending':   return '⏳ Pending';
      case 'rejected':  return '✗ Rejected';
      case 'cancelled': 
      case 'canceled': return '✗ Cancelled';
      default: return s.toUpperCase();
    }
  }

  Future<void> _cancelRequest(
      BuildContext context, WidgetRef ref, String? uid) async {
    if (uid == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Visit Request',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text(
            'Are you sure you want to cancel this visit request?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes, Cancel',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      final result = await ref.read(cancelVisitUseCaseProvider)(trip, uid);
      if (context.mounted) {
        result.fold(
          (failure) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel: ${failure.message}'), backgroundColor: Colors.red),
          ),
          (_) => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trip cancelled successfully'), backgroundColor: Colors.green),
          ),
        );
      }
    }
  }

  Future<void> _rescheduleRequest(
      BuildContext context, WidgetRef ref) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: trip.date.isAfter(DateTime.now())
          ? trip.date
          : DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (picked == null || !context.mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime == null || !context.mounted) return;

    final formatted =
        '${pickedTime.hour}:${pickedTime.minute.toString().padLeft(2, '0')} ${pickedTime.period == DayPeriod.am ? 'AM' : 'PM'}';
    await ref.read(rescheduleVisitUseCaseProvider)(trip, picked, formatted);
  }

  void _openChat(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(getOrCreateChatRoomUseCaseProvider)(
      renterId: trip.tenantId,
      ownerId: trip.ownerId,
      listingId: trip.listingId,
    );
    result.fold(
      (failure) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${failure.message}')),
        );
      },
      (chatRoom) => context.push('/chat-detail',
          extra: {'chatRoomId': chatRoom.id, 'title': trip.listingTitle}),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Small pill info label
// ─────────────────────────────────────────────────────────────────
class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color primaryColor;
  final bool isDark;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: primaryColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Action button
// ─────────────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: filled ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: filled ? Colors.white : color,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Empty-state (original design preserved)
// ─────────────────────────────────────────────────────────────────
class _EmptyTrips extends StatelessWidget {
  final IconData icon;
  final String title, subtitle, btnLabel;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onTap;

  const _EmptyTrips({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.btnLabel,
    required this.primaryColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 40, color: primaryColor),
            ),
            const SizedBox(height: 32),
            Text(title,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5)),
            const SizedBox(height: 12),
            Text(subtitle,
                style: TextStyle(
                  color:
                      isDark ? Colors.white54 : Colors.grey.shade600,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                )),
            const SizedBox(height: 40),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(btnLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
