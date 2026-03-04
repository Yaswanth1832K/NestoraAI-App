import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:house_rental/core/router/app_router.dart';
import 'package:house_rental/core/widgets/glass_container.dart';

class HomeServicesView extends StatelessWidget {
  const HomeServicesView({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> services = [
      {'name': 'Painting', 'icon': Icons.format_paint_rounded, 'badge': '25% Off', 'color': Colors.blue},
      {'name': 'Cleaning', 'icon': Icons.cleaning_services_rounded, 'badge': '60% Off', 'color': Colors.teal},
      {'name': 'Plumbing', 'icon': Icons.plumbing_rounded, 'badge': 'Starts ₹299', 'color': Colors.cyan},
      {'name': 'Electrical', 'icon': Icons.bolt_rounded, 'badge': 'Certified', 'color': Colors.amber},
      {'name': 'AC Repair', 'icon': Icons.ac_unit_rounded, 'badge': 'Hot Deal', 'color': Colors.lightBlue},
      {'name': 'Packers', 'icon': Icons.local_shipping_rounded, 'badge': 'Secure', 'color': Colors.indigo},
      {'name': 'Pest Ctrl', 'icon': Icons.bug_report_rounded, 'badge': 'Professional', 'color': Colors.orange},
      {'name': 'Carpentry', 'icon': Icons.handyman_rounded, 'badge': 'Master', 'color': Colors.brown},
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      physics: const BouncingScrollPhysics(),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return _ServiceCard(service: service, isDark: isDark);
        },
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final bool isDark;

  const _ServiceCard({required this.service, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = service['color'] as Color;
    return GestureDetector(
      onTap: () => context.push(
        AppRouter.serviceBooking,
        extra: {
          'serviceName': service['name'],
          'serviceIcon': service['icon'],
        },
      ),
      child: GlassContainer.standard(
        context: context,
        padding: EdgeInsets.zero,
        borderRadius: 24,
        child: Stack(
          children: [
            // Background Decorative Icon
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                service['icon'] as IconData,
                size: 90,
                color: color.withOpacity(isDark ? 0.08 : 0.04),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      service['badge'] as String,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Icon & Name
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(service['icon'] as IconData, size: 18, color: color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          service['name'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black,
                            letterSpacing: -0.2,
                          ),
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
}
