import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:house_rental/core/theme/app_colors.dart';
import 'package:house_rental/core/widgets/glass_container.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: _buildAppBarTitle(chatRoomAsync),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Expanded(
              child: messagesAsync.when(
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 64, color: isDark ? Colors.white10 : Colors.black12),
                          const SizedBox(height: 16),
                          const Text('No messages yet. Say hi!', 
                            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: messages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return _buildBookingStatus();
                      }
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
            
            // Bottm area
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSuggestedReplies(messagesAsync, chatRoomAsync, currentUser),
                  _buildTypingIndicator(chatRoomAsync, currentUser),
                  _buildBookingRequestButton(),
                  _buildInput(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarTitle(AsyncValue<ChatRoomEntity?> chatRoomAsync) {
    return chatRoomAsync.when(
      data: (room) {
        if (room == null) return Text(widget.title);
        final isRoommate = room.type == 'roommate';
        
        return Row(
          children: [
            if (!isRoommate) ...[
              ref.watch(listingProvider(room.listingId)).maybeWhen(
                data: (l) => Container(
                  width: 40, height: 40,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: l.allImages.isNotEmpty 
                      ? DecorationImage(image: NetworkImage(l.allImages.first), fit: BoxFit.cover)
                      : null,
                    color: AppColors.primary.withOpacity(0.1),
                  ),
                  child: l.allImages.isEmpty ? const Icon(Icons.home_rounded, size: 20) : null,
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  if (!isRoommate) 
                    Text(
                      'Property Owner',
                      style: TextStyle(
                        fontSize: 11, 
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => Text(widget.title),
      error: (_, __) => Text(widget.title),
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
            return Container(
              height: 45,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _suggestedReplies.map((reply) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(reply, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                      onPressed: () => _sendText(reply),
                      backgroundColor: AppColors.surfaceDark2,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      side: BorderSide.none,
                    ),
                  );
                }).toList(),
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
          return GlassContainer.standard(
            context: context,
            margin: const EdgeInsets.all(16),
            borderRadius: 20,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      "New Visit Request",
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Tenant requested a visit on ${DateFormat('EEEE, MMM d').format(request.date)}",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => updateStatus.call(request, 'rejected'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Decline"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => updateStatus.call(request, 'approved'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Accept"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        final statusColor = status == 'approved' ? AppColors.success : (status == 'rejected' ? Colors.redAccent : AppColors.accentOrange);

        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 24),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 14, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      "Visit Status: ${status.toUpperCase()}",
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Scheduled for ${DateFormat('dd MMM yyyy').format(request.date)}",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                ),
                if (status == 'approved') _buildReviewButtonFromRequest(request),
              ],
            ),
          ),
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
      padding: const EdgeInsets.only(top: 12),
      child: TextButton.icon(
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
        icon: const Icon(Icons.rate_review_outlined, size: 16),
        label: const Text("Rate your visit", style: TextStyle(fontWeight: FontWeight.w800)),
        style: TextButton.styleFrom(foregroundColor: AppColors.accentOrange),
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
        if (bookingsAsync.value?.isNotEmpty ?? false) return const SizedBox();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: GestureDetector(
            onTap: () async {
              final listing = await ref.read(listingProvider(chatRoom.listingId).future);
              final DateTime? date = await showDatePicker(
                context: context,
                initialDate: listing.availableDates.isNotEmpty 
                    ? listing.availableDates.first 
                    : DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                selectableDayPredicate: (DateTime day) {
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("This date is already booked."), backgroundColor: Colors.redAccent),
                  );
                  return;
              }

              final result = await repo.createBookingFromChat(
                listingId: chatRoom.listingId,
                ownerId: chatRoom.ownerId,
                renterId: chatRoom.renterId,
                chatId: widget.chatRoomId,
                visitDate: visitDate,
              );
              result.fold(
                (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${f.message}'))),
                (_) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Visit request sent!"))),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: AppColors.purpleGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 10),
                  Text("Schedule Property Visit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                ],
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text('Typing...', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary.withOpacity(0.5))),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark2 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                ),
                maxLines: null,
                onChanged: (_) => _onTyping(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppColors.purpleGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isMe ? AppColors.purpleGradient : null,
              color: isMe ? null : (isDark ? AppColors.surfaceDark2 : Colors.grey.shade200),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(0),
                bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(20),
              ),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('hh:mm a').format(message.createdAt),
            style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
