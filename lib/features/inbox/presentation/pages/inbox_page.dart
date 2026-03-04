import 'package:flutter/material.dart';
import 'package:house_rental/core/widgets/glass_container.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Inbox',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: -1),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20, top: 8, bottom: 8),
            child: GlassContainer.standard(
              context: context,
              borderRadius: 15,
              padding: EdgeInsets.zero,
              child: IconButton(
                icon: const Icon(Icons.search_rounded, size: 22),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GlassContainer.standard(
                context: context,
                padding: const EdgeInsets.all(4),
                borderRadius: 20,
                child: TabBar(
                  labelColor: Colors.white,
                  unselectedLabelColor: Theme.of(context).hintColor.withOpacity(0.5),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: primaryColor,
                  ),
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  tabs: const [
                    Tab(text: 'Messages'),
                    Tab(text: 'Notifications'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: TabBarView(
                children: [
                  _buildEmptyState(
                    context,
                    Icons.chat_bubble_outline_rounded,
                    'No new messages',
                    'When you contact a host or send a request, you’ll see your conversations here.',
                  ),
                  _buildEmptyState(
                    context,
                    Icons.notifications_none_rounded,
                    'No notifications',
                    'We\'ll notify you about property updates, price drops, and account activity.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GlassContainer.standard(
              context: context,
              padding: const EdgeInsets.all(30),
              borderRadius: 40,
              child: Icon(icon, size: 50, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).hintColor.withOpacity(0.6),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
