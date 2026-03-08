import 'package:flutter/material.dart';

class HomeService {
  final String id;
  final String name;
  final String category;
  final String image;
  final IconData icon;
  final String offer;
  final String description;
  final double priceStarting;
  final double rating;
  final String timeEstimate;

  const HomeService({
    required this.id,
    required this.name,
    required this.category,
    required this.image,
    required this.icon,
    required this.offer,
    required this.description,
    required this.priceStarting,
    required this.rating,
    required this.timeEstimate,
  });

  // Helper for "Starting from ₹XXX"
  String get priceTag => 'Starting @ ₹${priceStarting.toInt()}';
}
