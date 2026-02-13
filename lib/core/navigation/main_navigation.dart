import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/features/home/presentation/pages/home_page.dart';
import 'package:house_rental/features/search/presentation/pages/search_page.dart';
import 'package:house_rental/features/favorites/presentation/pages/favorites_page.dart';
import 'package:house_rental/features/map/presentation/pages/map_page.dart';
import 'package:house_rental/features/chat/presentation/pages/chat_inbox_page.dart';
import 'package:house_rental/features/owner/presentation/owner_properties_screen.dart';
import 'package:house_rental/features/profile/presentation/pages/profile_page.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';

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
    final isOwnerAsync = ref.watch(isOwnerProvider);
    final isOwner = isOwnerAsync.value ?? false;

    // Define pages dynamically based on role
    final List<Widget> pages = [
      const HomePage(),
      const SearchPage(),
      const MapPage(),
      const FavoritesPage(),
      const ChatInboxPage(),
      if (isOwner) const OwnerPropertiesScreen(),
      const ProfilePage(),
    ];

    // Define items dynamically based on role
    final List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_rounded),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.search_rounded),
        label: 'Search',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.map_rounded),
        label: 'Map',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.favorite_rounded),
        label: 'Favorites',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.chat_bubble_rounded),
        label: 'Messages',
      ),
      if (isOwner)
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_work_rounded),
          label: 'My Properties',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_rounded),
        label: 'Profile',
      ),
    ];

    // Guard against index out of bounds if role changes
    if (_selectedIndex >= pages.length) {
      _selectedIndex = pages.length - 1;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: const Color(0xFF1A1A1A),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 10,
        items: navItems,
      ),
    );
  }
}
