import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/chat/presentation/providers/chat_providers.dart';
import 'package:house_rental/features/chat/domain/entities/chat_room_entity.dart';
import 'package:house_rental/features/chat/domain/entities/message_entity.dart';
import 'package:house_rental/features/listings/presentation/providers/listings_providers.dart';
import 'package:house_rental/features/reviews/presentation/review_screen.dart';
import 'package:house_rental/features/visit_requests/domain/entities/visit_request_entity.dart';
import 'package:house_rental/features/visit_requests/presentation/providers/visit_request_providers.dart';

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
  Timer? _typingStopTimer;

  @override
  void dispose() {
    _typingStopTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  void _onTyping() {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    _typingStopTimer?.cancel();
    ref.read(chatRepositoryProvider).setTyping(widget.chatRoomId, user.uid);
    _typingStopTimer = Timer(const Duration(seconds: 2), () {
      ref.read(chatRepositoryProvider).clearTyping(widget.chatRoomId, user.uid);
    });
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    _typingStopTimer?.cancel();
    final user = ref.read(authStateProvider).value;
    if (user != null) ref.read(chatRepositoryProvider).clearTyping(widget.chatRoomId, user.uid);
    await _sendText(text);
  }

  Future<void> _sendText(String text) async {
    if (text.isEmpty) return;
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

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

  static const List<String> _suggestedReplies = [
    "Yes, it's available",
    "Let me check and get back",
    "What time works for you?",
  ];

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesStreamProvider(widget.chatRoomId));
    final chatRoomAsync = ref.watch(chatRoomStreamProvider(widget.chatRoomId));
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
          _buildSuggestedReplies(messagesAsync, chatRoomAsync, currentUser),
          _buildTypingIndicator(chatRoomAsync, currentUser),
          _buildBookingRequestButton(),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildSuggestedReplies(
    AsyncValue<List<MessageEntity>> messagesAsync,
    AsyncValue<ChatRoomEntity?> chatRoomAsync,
    dynamic currentUser,
  ) {
    if (currentUser == null) return const SizedBox.shrink();
    return messagesAsync.when(
      data: (messages) {
        return chatRoomAsync.when(
          data: (chatRoom) {
            if (chatRoom == null || messages.isEmpty) return const SizedBox.shrink();
            if (currentUser.uid != chatRoom.ownerId) return const SizedBox.shrink();
            if (messages.first.senderId == currentUser.uid) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _suggestedReplies.map((reply) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(reply, style: const TextStyle(fontSize: 13)),
                        onPressed: () => _sendText(reply),
                        backgroundColor: Colors.grey.shade800,
                        side: BorderSide(color: Colors.grey.shade600),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildBookingStatus() {
    final bookingAsync = ref.watch(bookingStreamProvider(widget.chatRoomId));
    final currentUser = ref.watch(authStateProvider).value;

    return bookingAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) return const SizedBox();

        final request = bookings.first;
        final status = request.status;
        final isOwner = currentUser?.uid == request.ownerId;

        if (status == 'pending' && isOwner) {
          final updateStatus = ref.read(updateVisitStatusUseCaseProvider);
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
                  onPressed: () => updateStatus(request, 'rejected'),
                  child: const Text("Reject", style: TextStyle(color: Colors.redAccent)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => updateStatus(request, 'approved'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  child: const Text("Accept", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Container(
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
                  const SizedBox(height: 4),
                  Text(
                    "Visit Date: ${DateFormat('dd/MM/yyyy').format(request.date)}",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            _buildReviewButtonFromRequest(request),
          ],
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildReviewButtonFromRequest(VisitRequestEntity request) {
    final currentUser = ref.watch(authStateProvider).value;
    final isRenter = currentUser?.uid == request.tenantId;
    if (request.status != 'approved' || !isRenter) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReviewScreen(
                  listingId: request.listingId,
                  listingTitle: request.listingTitle,
                  ownerId: request.ownerId,
                  bookingId: request.id,
                ),
              ),
            );
          },
          icon: const Icon(Icons.rate_review_outlined, size: 18),
          label: const Text("Leave a Review"),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.amber,
            side: const BorderSide(color: Colors.amber),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
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
        if (bookingsAsync.value?.isNotEmpty ?? false) return const SizedBox();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                // Ensure listing data is loaded (Fix Race Condition)
                final listing = await ref.read(listingProvider(chatRoom.listingId).future);

                // Pick Date
                final DateTime? date = await showDatePicker(
                  context: context,
                  initialDate: listing.availableDates.isNotEmpty 
                      ? listing.availableDates.first 
                      : DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)), // Increased range
                  selectableDayPredicate: (DateTime day) {
                    // Only allow dates defined by the owner
                    if (listing.availableDates.isEmpty) return true;
                    return listing.availableDates.any((d) => 
                      d.year == day.year && d.month == day.month && d.day == day.day);
                  },
                );

                if (date == null) return;

                final repo = ref.read(visitRequestRepositoryProvider);
                final visitDate = DateTime(date.year, date.month, date.day);
                final hasConflict = await repo.hasApprovedBookingForDate(chatRoom.listingId, visitDate);
                if (hasConflict) {
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

                final result = await repo.createBookingFromChat(
                  listingId: chatRoom.listingId,
                  ownerId: chatRoom.ownerId,
                  renterId: chatRoom.renterId,
                  chatId: widget.chatRoomId,
                  visitDate: visitDate,
                );
                if (mounted) {
                  result.fold(
                    (failure) => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to send request: ${failure.message}')),
                    ),
                    (_) => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Visit request sent successfully!")),
                    ),
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

  Widget _buildTypingIndicator(AsyncValue<ChatRoomEntity?> chatRoomAsync, dynamic currentUser) {
    return chatRoomAsync.when(
      data: (chatRoom) {
        if (chatRoom == null || currentUser == null) return const SizedBox.shrink();
        final typingId = chatRoom.typingUserId;
        if (typingId == null || typingId == currentUser.uid) return const SizedBox.shrink();
        final updated = chatRoom.typingUpdatedAt;
        if (updated != null && DateTime.now().difference(updated).inSeconds > 5) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey.shade400)),
              const SizedBox(width: 8),
              Text('Typing...', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
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
                onChanged: (_) => _onTyping(),
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
