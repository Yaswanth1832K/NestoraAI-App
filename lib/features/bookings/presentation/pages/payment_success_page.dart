import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:house_rental/core/theme/app_colors.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';

class PaymentSuccessPage extends StatelessWidget {
  final ListingEntity listing;

  const PaymentSuccessPage({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                
                // Success Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 80),
                ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
                
                const SizedBox(height: 32),
                
                // Text
                Text('Booking Confirmed!', 
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textColor))
                  .animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(begin: 0.2),
                  
                const SizedBox(height: 16),
                
                Text('You successfully booked:', 
                  style: TextStyle(fontSize: 16, color: subTextColor))
                  .animate().fadeIn(delay: 600.ms, duration: 600.ms),
                  
                const SizedBox(height: 8),
                
                Text('${listing.title} – ${listing.city}', 
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor))
                  .animate().fadeIn(delay: 800.ms, duration: 600.ms),
                  
                const SizedBox(height: 48),
  
                // Reward Banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.orangeGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.card_giftcard, color: Colors.white, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('You won a free spin!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            SizedBox(height: 4),
                            Text('Claim your reward now.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 1.seconds, duration: 800.ms).scaleXY(begin: 0.9, curve: Curves.easeOutBack),
                
                const SizedBox(height: 48),
                
                // Spin Reward Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      context.pushReplacement('/reward-wheel');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentOrange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Spin Reward Wheel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ).animate().fadeIn(delay: 1.2.seconds),
                
                const SizedBox(height: 16),
                
                // Skip Button
                TextButton(
                    onPressed: () {
                      context.go('/');
                    },
                  child: Text('Skip to Home', style: TextStyle(color: subTextColor, fontWeight: FontWeight.w600)),
                ).animate().fadeIn(delay: 1.5.seconds),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
