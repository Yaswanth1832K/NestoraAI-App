import 'package:flutter/material.dart';
import '../domain/entities/home_service.dart';

class ServicesData {
  static const List<HomeService> allServices = [
    // ── Cleaning Services ──
    HomeService(
      id: 'clean_1',
      name: 'Kitchen Cleaning',
      category: 'Cleaning Services',
      image: 'https://images.unsplash.com/photo-1527515637462-cff94eecc1ac?auto=format&fit=crop&q=80&w=800',
      icon: Icons.cleaning_services_rounded,
      offer: '30% OFF',
      description: 'Deep cleaning of your kitchen including chimney, stove, and cabinets.',
      priceStarting: 499,
      rating: 4.8,
      timeEstimate: '60-90 mins',
    ),
    HomeService(
      id: 'clean_2',
      name: 'Bathroom Cleaning',
      category: 'Cleaning Services',
      image: 'https://images.unsplash.com/photo-1584622781564-1d987f7333c1?auto=format&fit=crop&q=80&w=800',
      icon: Icons.wash_rounded,
      offer: 'Buy 1 Get 1',
      description: 'Complete disinfection and cleaning of tiles, floors, and fittings.',
      priceStarting: 299,
      rating: 4.7,
      timeEstimate: '45 mins',
    ),
    HomeService(
      id: 'clean_3',
      name: 'Full Home Cleaning',
      category: 'Cleaning Services',
      image: 'https://images.unsplash.com/photo-1528740561666-dc2479dc08ab?auto=format&fit=crop&q=80&w=800',
      icon: Icons.home_repair_service_rounded,
      offer: 'FLAT 40% OFF',
      description: 'A comprehensive top-to-bottom cleaning of your entire residence.',
      priceStarting: 1999,
      rating: 4.9,
      timeEstimate: '4-6 hours',
    ),
    HomeService(
      id: 'clean_4',
      name: 'Sofa Cleaning',
      category: 'Cleaning Services',
      image: 'https://images.unsplash.com/photo-1589182373726-e4f658ab50f0?auto=format&fit=crop&q=80&w=800',
      icon: Icons.weekend_rounded,
      offer: 'Starts @ ₹249',
      description: 'Dust and stain removal from sofas and couches using specialized equipment.',
      priceStarting: 249,
      rating: 4.6,
      timeEstimate: '60 mins',
    ),

    // ── Repair Services ──
    HomeService(
      id: 'repair_1',
      name: 'AC Repair',
      category: 'Repair Services',
      image: 'https://images.unsplash.com/photo-1621905252507-b35242f8df49?q=80&w=800',
      icon: Icons.ac_unit_rounded,
      offer: 'Free Gas Check',
      description: 'Expert repair and servicing for all types of air conditioners.',
      priceStarting: 299,
      rating: 4.9,
      timeEstimate: '60 mins',
    ),
    HomeService(
      id: 'repair_2',
      name: 'Refrigerator Repair',
      category: 'Repair Services',
      image: 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&q=80&w=800',
      icon: Icons.kitchen_rounded,
      offer: 'Safe Service',
      description: 'Prompt repair for cooling issues, leaks, and electrical faults.',
      priceStarting: 349,
      rating: 4.7,
      timeEstimate: '90 mins',
    ),
    HomeService(
      id: 'repair_3',
      name: 'Washing Machine',
      category: 'Repair Services',
      image: 'https://images.unsplash.com/photo-1517677208171-0bc6725a3e60?auto=format&fit=crop&q=80&w=800',
      icon: Icons.local_laundry_service_rounded,
      offer: 'Starts @ ₹199',
      description: 'Fixing drum, drain, and electrical issues in all washing machines.',
      priceStarting: 199,
      rating: 4.8,
      timeEstimate: '60 mins',
    ),

    // ── Maintenance ──
    HomeService(
      id: 'maint_1',
      name: 'Plumbing',
      category: 'Home Maintenance',
      image: 'https://images.unsplash.com/photo-1607472586893-edb57bdc0e39?auto=format&fit=crop&q=80&w=800',
      icon: Icons.plumbing_rounded,
      offer: 'Verified',
      description: 'Leaking pipes, tap replacement, and bathroom fittings repair.',
      priceStarting: 99,
      rating: 4.8,
      timeEstimate: '30-45 mins',
    ),
    HomeService(
      id: 'maint_2',
      name: 'Electrician',
      category: 'Home Maintenance',
      image: 'https://images.unsplash.com/photo-1621905251918-48416bd8575a?auto=format&fit=crop&q=80&w=800',
      icon: Icons.electrical_services_rounded,
      offer: 'Expert Care',
      description: 'Electrical wiring, switches, and appliance installations.',
      priceStarting: 99,
      rating: 4.9,
      timeEstimate: '30 mins',
    ),

    // ── Moving ──
    HomeService(
      id: 'move_1',
      name: 'Packers & Movers',
      category: 'Moving Services',
      image: 'https://images.unsplash.com/photo-1600585152220-90363fe7e115?auto=format&fit=crop&q=80&w=800',
      icon: Icons.local_shipping_rounded,
      offer: 'Free Estimate',
      description: 'Professional packing and safe moving of your belongings.',
      priceStarting: 4999,
      rating: 4.9,
      timeEstimate: 'Day long',
    ),

    // ── Improvement ──
    HomeService(
      id: 'improve_1',
      name: 'Home Painting',
      category: 'Home Improvement',
      image: 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?auto=format&fit=crop&q=80&w=800',
      icon: Icons.format_paint_rounded,
      offer: 'Premium Finish',
      description: 'Expert wall painting with high-quality paints and finish.',
      priceStarting: 999,
      rating: 4.8,
      timeEstimate: 'Multi-day',
    ),
    HomeService(
      id: 'improve_2',
      name: 'Modular Kitchen',
      category: 'Home Improvement',
      image: 'https://images.unsplash.com/photo-1556912172-45b7abe8b7e1?q=80&w=800',
      icon: Icons.countertops_rounded,
      offer: 'Free Demo',
      description: 'Modern and ergonomic kitchen designs for your home.',
      priceStarting: 49999,
      rating: 4.9,
      timeEstimate: 'Weeks',
    ),
  ];

  static List<String> get categories => [
    'Cleaning Services',
    'Repair Services',
    'Home Maintenance',
    'Moving Services',
    'Home Improvement',
  ];

  static List<HomeService> getByCategory(String category) {
    return allServices.where((s) => s.category == category).toList();
  }

  static List<HomeService> get featuredServices => 
    allServices.where((s) => s.rating >= 4.8).take(4).toList();
}
