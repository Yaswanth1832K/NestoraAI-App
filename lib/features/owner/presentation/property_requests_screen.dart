import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/core/theme/theme_provider.dart';
import 'package:house_rental/features/visit_requests/data/models/visit_request_model.dart';

class PropertyRequestsScreen extends ConsumerWidget {
  final String listingId;
  final String title;

  const PropertyRequestsScreen({
    super.key,
    required this.listingId,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('listingId', isEqualTo: listingId)
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }

          final bookings = snapshot.data!.docs;

          if (bookings.isEmpty) {
            return Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Icon(Icons.assignment_late_outlined, size: 80, color: isDark ? Colors.grey : Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text("No requests yet", style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                )
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final doc = bookings[index];
              final request = VisitRequestModel.fromFirestore(doc);
              final status = request.status;
              final date = request.date;

              return Card(
                elevation: isDark ? 0 : 2,
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            Text(
                              "Visit Request",
                              style: TextStyle(
                                  color: Colors.blueAccent.shade100,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                              ),
                            ),
                            _buildStatusBadge(status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                          children: [
                              const Icon(Icons.person_outline, color: Colors.grey, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                request.tenantName,
                                style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                              ),
                          ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                          children: [
                              const Icon(Icons.calendar_today_rounded, color: Colors.grey, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                "Date: ${date.day}/${date.month}/${date.year}",
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87, 
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 16
                                )
                              ),
                          ],
                      ),
                      const SizedBox(height: 16),
                      if (status == 'pending')
                        Row(
                          children: [
                            Expanded(
                                child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.withOpacity(0.2),
                                        foregroundColor: Colors.greenAccent,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {
                                        doc.reference.update({'status': 'approved'});
                                    },
                                    child: const Text("Approve"),
                                ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                                child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.withOpacity(0.2),
                                        foregroundColor: Colors.redAccent,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {
                                        doc.reference.update({'status': 'rejected'});
                                    },
                                    child: const Text("Reject"),
                                ),
                            ),
                          ],
                        )
                      else if (status == 'approved')
                         Row(
                             children: [
                                 const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
                                 const SizedBox(width: 8),
                                 Text("This visit is confirmed", style: TextStyle(color: isDark ? Colors.greenAccent : Colors.green.shade700)),
                             ],
                         )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
      Color color;
      switch (status) {
          case 'approved': color = Colors.greenAccent; break;
          case 'rejected': color = Colors.redAccent; break;
          default: color = Colors.orangeAccent;
      }

      return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Text(
              status.toUpperCase(),
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
      );
  }
}
