import 'package:flutter/material.dart';
import 'package:house_rental/core/theme/app_colors.dart';

class SafetyPage extends StatelessWidget {
  const SafetyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Safety Center")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Emergency Services",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.red,
                child: Icon(Icons.local_police, color: Colors.white),
              ),
              title: const Text("Call Police"),
              subtitle: const Text("100"),
              trailing: const Icon(Icons.phone),
              onTap: () {},
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.red,
                child: Icon(Icons.local_hospital, color: Colors.white),
              ),
              title: const Text("Call Ambulance"),
              subtitle: const Text("102"),
              trailing: const Icon(Icons.phone),
              onTap: () {},
            ),
            const Divider(height: 32),
            const Text(
              "Safety Tips",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSafetyTip(Icons.lock, "Always lock doors and windows when leaving."),
            _buildSafetyTip(Icons.person_pin, "Share your location with trusted contacts."),
            _buildSafetyTip(Icons.warning, "Be aware of your surroundings at night."),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {},
                child: const Text("Contact Nestora Safety Team"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyTip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
