import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/features/home/presentation/pages/home_page.dart';
import 'package:house_rental/features/search/presentation/pages/search_page.dart';
import 'package:house_rental/features/favorites/presentation/pages/favorites_page.dart';
import 'package:house_rental/features/map/presentation/pages/map_page.dart';
import 'package:house_rental/features/chat/presentation/pages/chat_inbox_page.dart';
import 'package:house_rental/features/profile/presentation/pages/profile_page.dart';
import 'package:house_rental/features/roommate/presentation/pages/roommate_feed_screen.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/trips/presentation/pages/trips_page.dart';

import 'package:house_rental/core/notifications/notification_service.dart';

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
    // Initialize push notifications
    NotificationService().initNotifications(context);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Exact 5 Airbnb-style tabs
    final List<Widget> pages = [
      const HomePage(),
      const FavoritesPage(),
      const TripsPage(),
      const ChatInboxPage(),
      const ProfilePage(),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          selectedItemColor: const Color(0xFFFF385C), // Exact Airbnb Red
          unselectedItemColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          elevation: 0, // Flat with border instead of heavy shadow
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 2), child: Icon(Icons.search)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 2), child: Icon(Icons.search, size: 28)),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 2), child: Icon(Icons.favorite_border)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 2), child: Icon(Icons.favorite, size: 28)),
              label: 'Wishlists',
            ),
            BottomNavigationBarItem(
              // Using a standard icon as placeholder for the Trips/Airbnb logo
              icon: Padding(padding: EdgeInsets.only(bottom: 2), child: Icon(Icons.change_history)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 2), child: Icon(Icons.change_history, size: 28)),
              label: 'Trips',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 2), child: Icon(Icons.chat_bubble_outline)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 2), child: Icon(Icons.chat_bubble, size: 28)),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 2), child: Icon(Icons.person_outline)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 2), child: Icon(Icons.person, size: 28)),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
