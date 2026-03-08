import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:house_rental/core/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:house_rental/features/home/domain/entities/home_service.dart';

class ServiceDetailPage extends StatelessWidget {
  final HomeService service;
  final bool isDark;
  final String heroPrefix;

  const ServiceDetailPage({
    super.key,
    required this.service,
    required this.isDark,
    this.heroPrefix = 'service',
  });

  @override
  Widget build(BuildContext context) {
    final txtColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Hero Image ──
              SliverAppBar(
                expandedHeight: 400,
                pinned: true,
                backgroundColor: bgColor,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: '${heroPrefix}_image_${service.id}',
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: service.image,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            color: isDark ? Colors.grey[900] : Colors.grey[200],
                            child: const Icon(Icons.broken_image_rounded, size: 50, color: Colors.grey),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.3),
                                Colors.transparent,
                                Colors.black.withOpacity(0.8),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Content ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppColors.s24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              service.category.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                service.rating.toString(),
                                style: TextStyle(color: txtColor, fontWeight: FontWeight.w900, fontSize: 16),
                              ),
                              Text(
                                ' (240+ reviews)',
                                style: TextStyle(color: subColor, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        service.name,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: txtColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _infoItem(Icons.timer_outlined, service.timeEstimate, subColor),
                          const SizedBox(width: 20),
                          _infoItem(Icons.verified_user_outlined, 'Trusted Pro', subColor),
                        ],
                      ),

                      const SizedBox(height: 32),
                      
                      // ── About Section Card ──
                      _buildSectionCard(
                        title: 'About Service',
                        isDark: isDark,
                        child: Text(
                          service.description,
                          style: TextStyle(
                            fontSize: 15,
                            color: subColor,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Inclusion Section Card ──
                      _buildSectionCard(
                        title: 'What\'s Included?',
                        isDark: isDark,
                        child: Column(
                          children: [
                            _inclusionItem('Professional & Verified Experts', subColor),
                            _inclusionItem('Complete home disinfection', subColor),
                            _inclusionItem('Stain removal from all furniture', subColor),
                            _inclusionItem('Eco-friendly cleaning agents', subColor),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 120), // Space for bottom button
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Bottom Fixed Button ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              decoration: BoxDecoration(
                color: cardColor,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, -5))
                ],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Price',
                        style: TextStyle(color: subColor, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '₹${service.priceStarting.toInt()}',
                        style: TextStyle(color: txtColor, fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showSuccessDialog(context),
                      child: Container(
                        height: 60,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))
                          ],
                        ),
                        child: const Text(
                          'BOOK SERVICE',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0),
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
    );
  }

  Widget _buildSectionCard({required String title, required Widget child, required bool isDark}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.w900, 
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                child: Lottie.network(
                  'https://assets10.lottiefiles.com/packages/lf20_s2lryxtd.json',
                  repeat: false,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.check_circle_rounded, color: AppColors.accentTeal, size: 48),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Booked Successfully!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Our representative will contact you shortly to confirm the schedule.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to services list
                },
                child: Container(
                  height: 56,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'BACK TO HOME',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color.withOpacity(0.6)),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _inclusionItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, size: 20, color: AppColors.accentTeal),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text, 
              style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
