import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/visit_requests/domain/entities/visit_request_entity.dart';
import 'package:house_rental/features/visit_requests/presentation/providers/visit_request_providers.dart';
import 'package:house_rental/features/chat/presentation/pages/chat_page.dart';
import 'package:house_rental/features/chat/presentation/providers/chat_providers.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MyVisitsPage extends ConsumerWidget {
  const MyVisitsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in')),
      );
    }

    final requestsAsync = ref.watch(tenantVisitRequestsProvider(user.uid));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Visits', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: requestsAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No scheduled visits yet',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _VisitRequestCard(request: request);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _VisitRequestCard extends ConsumerWidget {
  final VisitRequestEntity request;

  const _VisitRequestCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _getStatusColor(request.status);
    final user = ref.watch(authStateProvider).value;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Row(
              children: [
                // Listing Image
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CachedNetworkImage(
                    imageUrl: request.listingImage,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey.shade200),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.home_work, color: Colors.grey),
                    ),
                  ),
                ),
                
                // Listing Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.listingTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM dd, yyyy').format(request.date),
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: Theme.of(context).textTheme.bodySmall?.color),
                            const SizedBox(width: 4),
                            Text(
                              request.time,
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Status Chip
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      request.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (request.message.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Theme.of(context).brightness == Brightness.light 
                    ? Colors.grey.shade50 
                    : Colors.white.withOpacity(0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Message:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.message,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),

            // Actions Area
            if (request.status != 'cancelled' && request.status != 'rejected')
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    if (request.status == 'pending')
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _cancelRequest(context, ref, user?.uid),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Cancel"),
                        ),
                      ),
                    if (request.status == 'pending') const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _rescheduleRequest(context, ref),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Reschedule"),
                      ),
                    ),
                    if (request.status == 'approved') ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openChat(context, ref),
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text("Chat"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelRequest(BuildContext context, WidgetRef ref, String? uid) async {
    if (uid == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Request"),
        content: const Text("Are you sure you want to cancel this visit request?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes, Cancel")),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(cancelVisitUseCaseProvider)(request, uid);
    }
  }

  Future<void> _rescheduleRequest(BuildContext context, WidgetRef ref) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: request.date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (pickedDate == null || !context.mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null || !context.mounted) return;

    final formattedTime = '${pickedTime.hour}:${pickedTime.minute.toString().padLeft(2, '0')} ${pickedTime.period == DayPeriod.am ? 'AM' : 'PM'}';

    await ref.read(rescheduleVisitUseCaseProvider)(request, pickedDate, formattedTime);
  }

  void _openChat(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(getOrCreateChatRoomUseCaseProvider)(
      renterId: request.tenantId,
      ownerId: request.ownerId,
      listingId: request.listingId,
    );

    result.fold(
      (failure) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening chat: ${failure.message}')),
        );
      },
      (chatRoom) {
        // Use navigator to push chat page
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatPage(
              chatRoomId: chatRoom.id,
              title: request.listingTitle,
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
