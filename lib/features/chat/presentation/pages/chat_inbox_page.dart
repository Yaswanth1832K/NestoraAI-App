import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/chat/presentation/providers/chat_providers.dart';
import 'package:house_rental/features/chat/presentation/pages/chat_page.dart';
import 'package:intl/intl.dart';
import 'package:house_rental/features/listings/presentation/providers/listings_providers.dart';
import 'package:house_rental/features/chat/domain/entities/chat_room_entity.dart';

class ChatInboxPage extends ConsumerWidget {
  const ChatInboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('Please login to view messages', style: TextStyle(color: Colors.white)),
            );
          }
          
          final chatRoomsAsync = ref.watch(userChatRoomsProvider(user.uid));
          
          return chatRoomsAsync.when(
            data: (chatRooms) {
              if (chatRooms.isEmpty) {
                return _buildEmptyState();
              }
              
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: chatRooms.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.white12),
                itemBuilder: (context, index) {
                  return ChatRoomTile(
                    chatRoom: chatRooms[index],
                    currentUserId: user.uid,
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error', style: const TextStyle(color: Colors.red))),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text(
            'No conversations yet',
            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Messages from property owners and potential roommates will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class ChatRoomTile extends ConsumerWidget {
  final ChatRoomEntity chatRoom;
  final String currentUserId;

  const ChatRoomTile({
    super.key,
    required this.chatRoom,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine title logically
    final isRoommate = chatRoom.type == 'roommate';
    final otherUserId = chatRoom.participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: _buildAvatar(isRoommate),
      title: _buildTitle(ref, isRoommate, otherUserId),
      subtitle: _buildSubtitle(),
      trailing: _buildTrailing(),
      onTap: () => _navigateToChat(context, ref, isRoommate, otherUserId),
    );
  }

  Widget _buildAvatar(bool isRoommate) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: isRoommate ? Colors.purple.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
      child: Icon(
        isRoommate ? Icons.person_rounded : Icons.home_rounded,
        color: isRoommate ? Colors.purple : Colors.blueAccent,
      ),
    );
  }

  Widget _buildTitle(WidgetRef ref, bool isRoommate, String otherUserId) {
    if (isRoommate) {
      final userProfile = ref.watch(userProfileProvider(otherUserId));
      return userProfile.when(
        data: (user) => Text(
          user?.displayName ?? 'Roommate Chat',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
        ),
        loading: () => const Text('Loading...', style: TextStyle(color: Colors.grey, fontSize: 14)),
        error: (_, __) => const Text('Roommate chat', style: TextStyle(color: Colors.white, fontSize: 16)),
      );
    } else {
      if (chatRoom.listingId.isEmpty) {
        return const Text('Property Chat', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16));
      }
      final listing = ref.watch(listingProvider(chatRoom.listingId));
      return listing.when(
        data: (l) => Text(
          l.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
        ),
        loading: () => const Text('Loading...', style: TextStyle(color: Colors.grey, fontSize: 14)),
        error: (_, __) => const Text('Property Chat', style: TextStyle(color: Colors.white, fontSize: 16)),
      );
    }
  }

  Widget _buildSubtitle() {
    String subText = 'Chat';
    if (chatRoom.lastMessage != null && chatRoom.lastMessage!.isNotEmpty) {
      subText = chatRoom.lastMessage!;
    } else {
      subText = chatRoom.type == 'roommate' ? 'Direct message' : 'Property inquiry';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(
        subText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      ),
    );
  }

  Widget _buildTrailing() {
    if (chatRoom.lastTimestamp == null) return const SizedBox();
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _formatDate(chatRoom.lastTimestamp!),
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return DateFormat.Hm().format(date);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat.E().format(date);
    return DateFormat('dd/MM/yy').format(date);
  }

  void _navigateToChat(BuildContext context, WidgetRef ref, bool isRoommate, String otherUserId) async {
    String title = 'Chat';
    if (isRoommate) {
      final user = await ref.read(userProfileProvider(otherUserId).future);
      title = user?.displayName ?? 'Roommate';
    } else if (chatRoom.listingId.isNotEmpty) {
      final listing = await ref.read(listingProvider(chatRoom.listingId).future);
      title = listing?.title ?? 'Property';
    }

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          chatRoomId: chatRoom.id,
          title: title,
        ),
      ),
    );
  }
}
