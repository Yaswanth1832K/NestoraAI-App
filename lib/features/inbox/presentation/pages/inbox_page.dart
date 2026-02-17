import 'package:flutter/material.dart';
import 'package:house_rental/core/theme/app_colors.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        actions: [
           IconButton(
             icon: const Icon(Icons.search, color: Colors.black),
             onPressed: () {},
           ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
             const TabBar(
               labelColor: Colors.black,
               unselectedLabelColor: Colors.grey,
               indicatorColor: Colors.black,
               tabs: [
                 Tab(text: 'Messages'),
                 Tab(text: 'Notifications'),
               ],
             ),
             Expanded(
               child: TabBarView(
                 children: [
                   Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.primary.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'No new messages', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
            ),
             const SizedBox(height: 8),
            const Text(
              'When you contact a host or send a reservation request, you’ll see your messages here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
                   ),
                   const Center(
                     child: Text('No notifications'),
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
