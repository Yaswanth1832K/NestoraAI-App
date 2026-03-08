import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:house_rental/core/theme/app_colors.dart';

class NestoraBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isDark;

  const NestoraBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenWidth = MediaQuery.of(context).size.width;
    final sideMargin = screenWidth < 350 ? 12.0 : (screenWidth < 400 ? 16.0 : 24.0);
    
    return Container(
      margin: EdgeInsets.fromLTRB(sideMargin, 0, sideMargin, bottomPadding > 0 ? bottomPadding : 16),
      height: 70,
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF1A1A1A).withOpacity(0.85) 
            : Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.search_rounded, 'Explore'),
                _buildNavItem(1, Icons.favorite_border_rounded, 'Wishlists', activeIcon: Icons.favorite_rounded),
                _buildNavItem(2, Icons.luggage_outlined, 'Trips', activeIcon: Icons.luggage_rounded),
                _buildNavItem(3, Icons.chat_bubble_outline_rounded, 'Inbox', activeIcon: Icons.chat_bubble_rounded),
                _buildNavItem(4, Icons.person_outline_rounded, 'Profile', activeIcon: Icons.person_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {IconData? activeIcon}) {
    final isSelected = currentIndex == index;
    final color = isSelected 
        ? AppColors.primary 
        : (isDark ? Colors.white54 : Colors.black45);
    
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? (activeIcon ?? icon) : icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
