import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'property_requests_screen.dart';

class OwnerPropertiesScreen extends StatelessWidget {
  const OwnerPropertiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
        return const Scaffold(
            body: Center(child: Text("Please login to view your properties")),
        );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("My Properties", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('listings')
            .where('ownerId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }

          final listings = snapshot.data!.docs;

          if (listings.isEmpty) {
            return const Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Icon(Icons.home_work_outlined, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text("You have no properties yet", style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                )
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: listings.length,
            itemBuilder: (context, index) {

              final listing = listings[index];
              final data = listing.data() as Map<String, dynamic>;

              return Card(
                  color: const Color(0xFF1A1A1A),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.home_rounded, color: Colors.blueAccent),
                    ),
                    title: Text(data['title'] ?? 'Property', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: const Text("Tap to view requests", style: TextStyle(color: Colors.grey)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PropertyRequestsScreen(
                            listingId: listing.id,
                            title: data['title'] ?? 'Property',
                          ),
                        ),
                      );
                    },
                  ),
              );
            },
          );
        },
      ),
    );
  }
}
