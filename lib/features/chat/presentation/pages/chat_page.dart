import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/chat/presentation/providers/chat_providers.dart';
import 'package:house_rental/features/chat/domain/entities/message_entity.dart';
import 'package:house_rental/features/listings/presentation/providers/listings_providers.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String chatRoomId;
  final String title;

  const ChatPage({
    super.key,
    required this.chatRoomId,
    required this.title,
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    _messageController.clear();
    
    final result = await ref.read(sendMessageUseCaseProvider)(
      chatRoomId: widget.chatRoomId,
      senderId: user.uid,
      text: text,
    );

    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sending message: ${failure.message}')),
          );
        }
      },
      (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesStreamProvider(widget.chatRoomId));
    final currentUser = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          _buildBookingStatus(),
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(child: Text('No messages yet. Say hi!'));
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUser?.uid;
                    return _MessageBubble(message: message, isMe: isMe);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
          _buildBookingRequestButton(),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildBookingStatus() {
    final bookingAsync = ref.watch(bookingStreamProvider(widget.chatRoomId));
    final currentUser = ref.watch(authStateProvider).value;

    return bookingAsync.when(
      data: (snapshot) {
        if (snapshot.docs.isEmpty) return const SizedBox();

        final booking = snapshot.docs.first;
        final data = booking.data() as Map<String, dynamic>;
        final status = data['status'];
        final isOwner = currentUser?.uid == data['ownerId'];

        if (status == 'pending' && isOwner) {
          return Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1A1A1A),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "New Visit Request",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () => booking.reference.update({'status': 'rejected'}),
                  child: const Text("Reject", style: TextStyle(color: Colors.redAccent)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => booking.reference.update({'status': 'approved'}),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  child: const Text("Accept", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: status == 'approved' 
              ? Colors.green.withOpacity(0.1) 
              : status == 'rejected' 
                  ? Colors.red.withOpacity(0.1) 
                  : Colors.blue.withOpacity(0.1),
          child: Column(
            children: [
              Text(
                "Visit Status: ${status.toString().toUpperCase()}",
                style: TextStyle(
                  color: status == 'approved' 
                      ? Colors.greenAccent 
                      : status == 'rejected' 
                          ? Colors.redAccent 
                          : Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              if (data['visitDate'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  "Visit Date: ${DateFormat('dd/MM/yyyy').format((data['visitDate'] as Timestamp).toDate())}",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildBookingRequestButton() {
    final chatRoomAsync = ref.watch(chatRoomStreamProvider(widget.chatRoomId));
    final bookingsAsync = ref.watch(bookingStreamProvider(widget.chatRoomId));
    final currentUser = ref.watch(authStateProvider).value;

    return chatRoomAsync.when(
      data: (chatRoom) {
        if (chatRoom == null || currentUser?.uid != chatRoom.renterId) return const SizedBox();
        
        // Hide button if a booking already exists
        if (bookingsAsync.value?.docs.isNotEmpty ?? false) return const SizedBox();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final listingAsync = ref.read(listingProvider(chatRoom.listingId));
                final listing = listingAsync.value;

                if (listing == null) return;

                // Pick Date
                final DateTime? date = await showDatePicker(
                  context: context,
                  initialDate: listing.availableDates.isNotEmpty 
                      ? listing.availableDates.first 
                      : DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 180)),
                  selectableDayPredicate: (DateTime day) {
                    // Only allow dates defined by the owner
                    if (listing.availableDates.isEmpty) return true;
                    return listing.availableDates.any((d) => 
                      d.year == day.year && d.month == day.month && d.day == day.day);
                  },
                );

                if (date == null) return;

                // Double Booking Check
                final bookingTimestamp = Timestamp.fromDate(DateTime(date.year, date.month, date.day));
                final existing = await FirebaseFirestore.instance
                    .collection('bookings')
                    .where('listingId', isEqualTo: chatRoom.listingId)
                    .where('visitDate', isEqualTo: bookingTimestamp)
                    .where('status', isEqualTo: 'approved')
                    .get();

                if (existing.docs.isNotEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("This date is already booked and approved for someone else."),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                  return;
                }

                await FirebaseFirestore.instance.collection('bookings').add({
                  'listingId': chatRoom.listingId,
                  'ownerId': chatRoom.ownerId,
                  'renterId': chatRoom.renterId,
                  'chatId': widget.chatRoomId,
                  'participants': [chatRoom.renterId, chatRoom.ownerId],
                  'status': 'pending',
                  'visitDate': bookingTimestamp,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Visit request sent successfully!")),
                  );
                }
              },
              icon: const Icon(Icons.calendar_today, size: 18),
              label: const Text("Request Property Visit"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
                maxLines: null,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blueAccent),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? Colors.blueAccent : const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
                bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
              ),
            ),
            child: Text(
              message.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
            child: Text(
              DateFormat('hh:mm a').format(message.createdAt),
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}
