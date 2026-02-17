import 'package:flutter/material.dart';

// Remaining placeholder pages

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context) => _buildPlaceholder(context, "Notifications");
}

Widget _buildPlaceholder(BuildContext context, String title) {
  return Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text("$title Coming Soon", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );
}