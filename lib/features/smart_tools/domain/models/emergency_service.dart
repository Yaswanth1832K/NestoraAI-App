import 'package:flutter/material.dart';

class EmergencyService {
  final String id;
  final String name;
  final IconData icon;
  final String estimatedArrival;
  final String category;
  final Color color;

  EmergencyService({
    required this.id,
    required this.name,
    required this.icon,
    required this.estimatedArrival,
    required this.category,
    required this.color,
  });

  static List<EmergencyService> get defaults => [
    EmergencyService(
      id: 'em_elec',
      name: 'Emergency Electrician',
      icon: Icons.electrical_services_rounded,
      estimatedArrival: '15-20 mins',
      category: 'Electrical',
      color: Colors.amber,
    ),
    EmergencyService(
      id: 'em_plum',
      name: 'Emergency Plumber',
      icon: Icons.plumbing_rounded,
      estimatedArrival: '20-30 mins',
      category: 'Plumbing',
      color: Colors.blue,
    ),
    EmergencyService(
      id: 'em_lock',
      name: 'Emergency Locksmith',
      icon: Icons.vpn_key_rounded,
      estimatedArrival: '10-15 mins',
      category: 'Lock & Security',
      color: Colors.orange,
    ),
    EmergencyService(
      id: 'em_ac',
      name: 'Emergency AC Repair',
      icon: Icons.ac_unit_rounded,
      estimatedArrival: '45-60 mins',
      category: 'HVAC',
      color: Colors.lightBlue,
    ),
    EmergencyService(
      id: 'em_clean',
      name: 'Emergency Cleaning',
      icon: Icons.cleaning_services_rounded,
      estimatedArrival: '1-2 hours',
      category: 'Sanitization',
      color: Colors.green,
    ),
  ];
}
