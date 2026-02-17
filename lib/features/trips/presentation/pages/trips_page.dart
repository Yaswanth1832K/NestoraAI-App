import 'package:flutter/material.dart';
import 'package:house_rental/core/theme/app_colors.dart';

class TripsPage extends StatelessWidget {
  const TripsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trips'),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
      body: Center(
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Icon(Icons.flight_takeoff, size: 64, color: AppColors.primary.withOpacity(0.5)),
             const SizedBox(height: 16),
             const Text(
               'No trips yet', 
               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
             ),
             const SizedBox(height: 8),
             const Text(
               'Time to dust off your bags and start planning your next adventure',
               textAlign: TextAlign.center,
               style: TextStyle(color: Colors.grey),
             ),
             const SizedBox(height: 24),
             OutlinedButton(
               onPressed: () {},
               style: OutlinedButton.styleFrom(
                 foregroundColor: Colors.black,
                 side: const BorderSide(color: Colors.black),
                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
               ),
               child: const Text('Start searching'),
             ),
           ],
         ),
      ),
    );
  }
}
