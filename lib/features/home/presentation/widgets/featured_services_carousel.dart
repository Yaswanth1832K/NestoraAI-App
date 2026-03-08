import 'package:flutter/material.dart';
import 'package:house_rental/core/theme/app_colors.dart';
import 'package:house_rental/features/home/domain/entities/home_service.dart';
import 'package:house_rental/core/widgets/nestora_image.dart';

class FeaturedServicesCarousel extends StatefulWidget {
  final List<HomeService> services;
  final bool isDark;
  final Function(HomeService) onTap;

  const FeaturedServicesCarousel({
    super.key,
    required this.services,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<FeaturedServicesCarousel> createState() => _FeaturedServicesCarouselState();
}

class _FeaturedServicesCarouselState extends State<FeaturedServicesCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final txtColor = widget.isDark ? Colors.white : AppColors.textPrimaryLight;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppColors.s24, vertical: 12),
          child: Text(
            'Popular Services Near You',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: txtColor,
              letterSpacing: -0.5,
            ),
          ),
        ),
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemCount: widget.services.length,
            itemBuilder: (context, index) {
              final s = widget.services[index];
              return AnimatedScale(
                duration: const Duration(milliseconds: 400),
                scale: _currentPage == index ? 1.0 : 0.92,
                child: GestureDetector(
                  onTap: () => widget.onTap(s),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Hero(
                            tag: 'featured_service_image_${s.id}',
                            child: NestoraImage(
                              imageUrl: s.image,
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(6)),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.star_rounded, size: 14, color: Colors.white),
                                        const SizedBox(width: 4),
                                        Text(s.rating.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(s.priceTag, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                s.name,
                                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.services.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _currentPage == index ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: _currentPage == index ? AppColors.primary : AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}
