import 'dart:io';
import 'package:flutter/material.dart';
import 'package:house_rental/core/theme/app_colors.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

class ServiceHeroBanner extends StatelessWidget {
  final VoidCallback onSearchTap;
  final bool isDark;

  const ServiceHeroBanner({
    super.key,
    required this.onSearchTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Using a reliable network image for the hero banner
    const imagePath = 'https://images.unsplash.com/photo-1581578731548-c64695cc6954?q=80&w=2070&auto=format&fit=crop';

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final responsiveHeight = (screenWidth * 0.6).clamp(200.0, 320.0);
        final isSmall = screenWidth < 360;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: AppColors.s24, vertical: 12),
          height: responsiveHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // Background Image
                Positioned.fill(
                  child: Image.network(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.purpleGradient,
                      ),
                    ),
                  ),
                ),
                
                // Gradient Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.black.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Content
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmall ? 20.0 : 32.0,
                      vertical: isSmall ? 12.0 : 32.0,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min, // Added MainAxisSize.min
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  'NESTORA SERVICES',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: isSmall ? 8 : 12),
                          Text(
                            'Need Help\nat Home?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmall ? 22 : 32,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                              letterSpacing: -1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Book trusted home services instantly',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: isSmall ? 12 : 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: isSmall ? 16 : 24),
                          ElevatedButton(
                            onPressed: onSearchTap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              elevation: 8,
                              shadowColor: Colors.black45,
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmall ? 20 : 28, 
                                vertical: isSmall ? 10 : 16
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Book Now',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900, 
                                    letterSpacing: 0.5,
                                    fontSize: isSmall ? 11 : 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.arrow_forward_ios_rounded, size: isSmall ? 10 : 14),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}
