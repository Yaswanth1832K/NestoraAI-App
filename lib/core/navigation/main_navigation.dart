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
import 'package:house_rental/core/theme/app_colors.dart';
import 'package:house_rental/core/widgets/glass_container.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/location/location_provider.dart';

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
    // Fetch location silently on app start to refresh coordinates/city
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userLocationProvider.notifier).updateLocation(silent: true);
    });
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    final pages = [
      const HomePage(),
      const FavoritesPage(),
      const TripsPage(),
      const ChatInboxPage(),
      const ProfilePage(),
    ];

    final isOwner = ref.watch(isOwnerProvider).value ?? false;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: pages),
          
          // ── Floating Glass Bottom Navigation ──
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? const Color(0xFF1A1A1A).withOpacity(0.95) 
                        : Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                      if (isDark)
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                    ],
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black12,
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(child: _NavItem(icon: Icons.grid_view_rounded, activeIcon: Icons.grid_view_rounded, label: 'Home', selected: _selectedIndex == 0, activeColor: AppColors.primary, isDark: isDark, onTap: () => _onItemTapped(0))),
                      Expanded(child: _NavItem(icon: Icons.favorite_border_rounded, activeIcon: Icons.favorite_rounded, label: 'Saved', selected: _selectedIndex == 1, activeColor: AppColors.primary, isDark: isDark, onTap: () => _onItemTapped(1))),
                      Expanded(child: _NavItem(icon: Icons.luggage_outlined, activeIcon: Icons.luggage_rounded, label: 'Trips', selected: _selectedIndex == 2, activeColor: AppColors.primary, isDark: isDark, onTap: () => _onItemTapped(2))),
                      Expanded(child: _NavItem(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: 'Inbox', selected: _selectedIndex == 3, activeColor: AppColors.primary, isDark: isDark, onTap: () => _onItemTapped(3))),
                      Expanded(child: _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile', selected: _selectedIndex == 4, activeColor: AppColors.primary, isDark: isDark, onTap: () => _onItemTapped(4))),
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
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final Color activeColor;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveColor = isDark ? Colors.white38 : Colors.black38;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? activeColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: selected ? [
            BoxShadow(
              color: activeColor.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                selected ? activeIcon : icon,
                key: ValueKey(selected),
                size: 24,
                color: selected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: selected ? 4 : 0,
              height: 4,
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: activeColor.withOpacity(0.6),
                    blurRadius: 4,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
