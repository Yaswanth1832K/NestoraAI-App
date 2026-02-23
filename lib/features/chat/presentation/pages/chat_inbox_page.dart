import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/chat/presentation/providers/chat_providers.dart';
import 'package:house_rental/features/chat/presentation/pages/chat_page.dart';
import 'package:intl/intl.dart';
import 'package:house_rental/features/listings/presentation/providers/listings_providers.dart';
import 'package:house_rental/features/chat/domain/entities/chat_room_entity.dart';
import 'package:house_rental/core/theme/theme_provider.dart';

class ChatInboxPage extends ConsumerWidget {
  const ChatInboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: null, // Title is in body
        backgroundColor: bgColor,
        elevation: 0,
        actions: [
          _buildTopIcon(Icons.search, isDark),
          const SizedBox(width: 12),
          _buildTopIcon(Icons.settings_outlined, isDark),
          const SizedBox(width: 24),
        ],
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('Please login to view messages', style: TextStyle(color: Colors.black)),
            );
          }
          
          final chatRoomsAsync = ref.watch(userChatRoomsProvider(user.uid));
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Text(
                  'Messages',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: -1,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Row(
                  children: [
                    _buildFilterChip('All', isSelected: true, isDark: isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip('Travelling', isSelected: false, isDark: isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip('Support', isSelected: false, isDark: isDark),
                  ],
                ),
              ),
              Expanded(
                child: chatRoomsAsync.when(
                  data: (chatRooms) {
                    if (chatRooms.isEmpty) {
                      return _buildEmptyState();
                    }
                    
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: chatRooms.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12),
                      itemBuilder: (context, index) {
                        return ChatRoomTile(
                          chatRoom: chatRooms[index],
                          currentUserId: user.uid,
                          isDark: isDark,
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFF385C))),
                  error: (error, stack) => Center(child: Text('Error: $error', style: const TextStyle(color: Colors.red))),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFF385C))),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildTopIcon(IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        shape: BoxShape.circle,
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: Icon(icon, size: 20, color: isDark ? Colors.white : Colors.black),
    );
  }

  Widget _buildFilterChip(String label, {required bool isSelected, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected 
            ? (isDark ? Colors.white : Colors.black) 
            : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected 
              ? (isDark ? Colors.black : Colors.white) 
              : (isDark ? Colors.grey.shade300 : Colors.black87),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 48, color: Colors.grey.shade500),
            const SizedBox(height: 24),
            Text(
              'You don\'t have any messages',
              style: TextStyle(
                fontSize: 18, 
                color: Colors.grey.shade400, 
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'When you receive a new message, it will\nappear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF717171), 
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 80), // To center it nicely like the image
          ],
        ),
      ),
    );
  }
}

class ChatRoomTile extends ConsumerWidget {
  final ChatRoomEntity chatRoom;
  final String currentUserId;
  final bool isDark;

  const ChatRoomTile({
    super.key,
    required this.chatRoom,
    required this.currentUserId,
    required this.isDark,
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
    final titleColor = isDark ? Colors.white : Colors.black;
    if (isRoommate) {
      final userProfile = ref.watch(userProfileProvider(otherUserId));
      return userProfile.when(
        data: (user) => Text(
          user?.displayName ?? 'Roommate Chat',
          style: TextStyle(fontWeight: FontWeight.bold, color: titleColor, fontSize: 16),
        ),
        loading: () => const Text('Loading...', style: TextStyle(color: Colors.grey, fontSize: 14)),
        error: (_, __) => Text('Roommate chat', style: TextStyle(color: titleColor, fontSize: 16)),
      );
    } else {
      if (chatRoom.listingId.isEmpty) {
        return Text('Property Chat', style: TextStyle(fontWeight: FontWeight.bold, color: titleColor, fontSize: 16));
      }
      final listing = ref.watch(listingProvider(chatRoom.listingId));
      return listing.when(
        data: (l) => Text(
          l.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.bold, color: titleColor, fontSize: 16),
        ),
        loading: () => const Text('Loading...', style: TextStyle(color: Colors.grey, fontSize: 14)),
        error: (_, __) => Text('Property Chat', style: TextStyle(color: titleColor, fontSize: 16)),
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
    final hasUnread = chatRoom.lastMessageSenderId != null &&
        chatRoom.lastMessageSenderId != currentUserId &&
        chatRoom.lastMessage != null &&
        chatRoom.lastMessage!.isNotEmpty;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (chatRoom.lastTimestamp != null)
          Text(
            _formatDate(chatRoom.lastTimestamp!),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        if (hasUnread) ...[
          const SizedBox(height: 4),
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFFFF385C),
              shape: BoxShape.circle,
            ),
          ),
        ],
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
      title = listing.title ?? 'Property';
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
