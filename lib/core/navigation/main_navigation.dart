import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:house_rental/features/home/presentation/pages/home_page.dart';
import 'package:house_rental/features/favorites/presentation/pages/favorites_page.dart';
import 'package:house_rental/features/map/presentation/pages/map_page.dart';
import 'package:house_rental/features/trips/presentation/pages/trips_page.dart';
import 'package:house_rental/features/chat/presentation/pages/chat_inbox_page.dart';
import 'package:house_rental/features/profile/presentation/pages/profile_page.dart';
import 'package:house_rental/core/notifications/notification_service.dart';
import 'package:house_rental/core/router/app_router.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';

// ── Brand colors ───────────────────────────────────────────────
const _kPurple   = Color(0xFF7C5CBF);
const _kDarkCard = Color(0xFF1C1C1C);
const _kDarkBg   = Color(0xFF0D0D0D);

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});
  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    NotificationService().initNotifications(context);
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBg          = isDark ? _kDarkCard : Colors.white;
    final iconActive     = _kPurple;
    final iconInactive   = isDark ? Colors.white38 : Colors.black38;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    // ── 5 pages in order: Home | Saved | Trips | Messages | Profile ──
    final pages = [
      const HomePage(),
      const FavoritesPage(),
      const TripsPage(),
      const ChatInboxPage(),
      const ProfilePage(),
    ];

    final isOwner = ref.watch(isOwnerProvider).value ?? false;

    return Scaffold(
      backgroundColor: isDark ? _kDarkBg : const Color(0xFFF0F0F5),
      body: IndexedStack(index: _selectedIndex, children: pages),

      // ── Floating post-property button (Visible to Owners only) ─
      floatingActionButton: isOwner ? FloatingActionButton(
        onPressed: () => context.push(AppRouter.postProperty),
        backgroundColor: _kPurple,
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 75,
        color: barBg,
        notchMargin: 10,
        elevation: 0,
        shape: const CircularNotchedRectangle(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavItem(icon: Icons.grid_view_rounded, activeIcon: Icons.grid_view_rounded, label: 'Home', selected: _selectedIndex == 0, activeColor: iconActive, inactiveColor: iconInactive, onTap: () => _onItemTapped(0)),
                _NavItem(icon: Icons.favorite_border_rounded, activeIcon: Icons.favorite_rounded, label: 'Saved', selected: _selectedIndex == 1, activeColor: iconActive, inactiveColor: iconInactive, onTap: () => _onItemTapped(1)),
                if (isOwner)
                  const Opacity(opacity: 0, child: Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Icon(Icons.add))), // Placeholder for FAB
                _NavItem(icon: Icons.luggage_outlined, activeIcon: Icons.luggage_rounded, label: 'Trips', selected: _selectedIndex == 2, activeColor: iconActive, inactiveColor: iconInactive, onTap: () => _onItemTapped(2)),
                _NavItem(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: 'Messages', selected: _selectedIndex == 3, activeColor: iconActive, inactiveColor: iconInactive, onTap: () => _onItemTapped(3)),
                _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile', selected: _selectedIndex == 4, activeColor: iconActive, inactiveColor: iconInactive, onTap: () => _onItemTapped(4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Single nav bar item ──────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                selected ? activeIcon : icon,
                key: ValueKey(selected),
                size: 24,
                color: selected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: selected ? activeColor : inactiveColor,
                fontSize: 9.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
