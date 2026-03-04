import 'package:flutter/material.dart';
import 'package:house_rental/core/widgets/glass_container.dart';

class TripsPage extends StatefulWidget {
  const TripsPage({super.key});
  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Trips',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 32, letterSpacing: -1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: TabBar(
                controller: _tabCtrl,
                isScrollable: true,
                indicatorColor: primaryColor,
                indicatorWeight: 3,
                dividerColor: Colors.transparent,
                labelColor: isDark ? Colors.white : Colors.black,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                tabs: const [
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Past'),
                  Tab(text: 'Canceled'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _EmptyTrips(
            icon: Icons.map_rounded,
            title: 'No upcoming trips',
            subtitle: 'When you\'re ready to plan your next stay, we\'re here to help.',
            btnLabel: 'Explore Nestora',
            primaryColor: primaryColor,
          ),
          _EmptyTrips(
            icon: Icons.history_rounded,
            title: 'No past trips',
            subtitle: 'You haven\'t taken any trips using Nestora yet.',
            btnLabel: 'Find a home',
            primaryColor: primaryColor,
          ),
          _EmptyTrips(
            icon: Icons.cancel_outlined,
            title: 'No canceled trips',
            subtitle: 'All your canceled trips will appear here.',
            btnLabel: 'Back to home',
            primaryColor: primaryColor,
          ),
        ],
      ),
    );
  }
}

class _EmptyTrips extends StatelessWidget {
  final IconData icon;
  final String title, subtitle, btnLabel;
  final Color primaryColor;

  const _EmptyTrips({
    required this.icon, required this.title,
    required this.subtitle, required this.btnLabel,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 40, color: primaryColor),
            ),
            const SizedBox(height: 32),
            Text(title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            const SizedBox(height: 12),
            Text(subtitle,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                )),
            const SizedBox(height: 40),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(btnLabel, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 100), // Spacing for safe area
          ],
        ),
      ),
    );
  }
}
