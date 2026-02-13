import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PropertyRequestsScreen extends StatelessWidget {
  final String listingId;
  final String title;

  const PropertyRequestsScreen({
    super.key,
    required this.listingId,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
            return const Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Icon(Icons.assignment_late_outlined, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text("No requests yet", style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                )
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {

              final booking = bookings[index];
              final data = booking.data() as Map<String, dynamic>;
              final status = data['status'] ?? 'pending';

              final date = (data['visitDate'] as Timestamp).toDate();

              return Card(
                color: const Color(0xFF1A1A1A),
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
                              const Icon(Icons.calendar_today_rounded, color: Colors.grey, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                "Date: ${date.day}/${date.month}/${date.year}",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
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
                                        booking.reference.update({'status': 'approved'});
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
                                        booking.reference.update({'status': 'rejected'});
                                    },
                                    child: const Text("Reject"),
                                ),
                            ),
                          ],
                        )
                      else if (status == 'approved')
                         const Row(
                             children: [
                                 Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
                                 SizedBox(width: 8),
                                 Text("This visit is confirmed", style: TextStyle(color: Colors.greenAccent)),
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
