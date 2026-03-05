import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:house_rental/core/widgets/glass_container.dart';
import 'package:house_rental/core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/chat/domain/entities/chat_room_entity.dart';
import 'package:house_rental/features/chat/presentation/providers/chat_providers.dart';
import 'package:house_rental/features/listings/presentation/providers/listings_providers.dart';

class ChatInboxPage extends ConsumerWidget {
  const ChatInboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: -1),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            child: GlassContainer.standard(
              context: context,
              borderRadius: 15,
              padding: EdgeInsets.zero,
              child: IconButton(
                icon: const Icon(Icons.search_rounded, size: 22),
                onPressed: () {},
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 20, top: 8, bottom: 8),
            child: GlassContainer.standard(
              context: context,
              borderRadius: 15,
              padding: EdgeInsets.zero,
              child: IconButton(
                icon: const Icon(Icons.settings_outlined, size: 22),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Please login to view messages'));
          }
          
          final chatRoomsAsync = ref.watch(userChatRoomsProvider(user.uid));
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildFilterChip(context, 'All', isSelected: true),
                    const SizedBox(width: 12),
                    _buildFilterChip(context, 'Travelling', isSelected: false),
                    const SizedBox(width: 12),
                    _buildFilterChip(context, 'Support', isSelected: false),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: chatRoomsAsync.when(
                  data: (chatRooms) {
                    if (chatRooms.isEmpty) {
                      return _buildEmptyState(context);
                    }
                    
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: chatRooms.length,
                      physics: const BouncingScrollPhysics(),
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return ChatRoomTile(
                          chatRoom: chatRooms[index],
                          currentUserId: user.uid,
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Error: $error')),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, {required bool isSelected}) {
    final primaryColor = Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: () {},
      child: GlassContainer.standard(
        context: context,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        borderRadius: 20,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? primaryColor : Theme.of(context).hintColor.withOpacity(0.6),
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GlassContainer.standard(
              context: context,
              padding: const EdgeInsets.all(30),
              borderRadius: 40,
              child: Icon(Icons.forum_rounded, size: 50, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 32),
            const Text(
              'No messages yet',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'When you contact a host or receive an inquiry, your conversations will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).hintColor.withOpacity(0.6),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ],
        ),
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
    final isRoommate = chatRoom.type == 'roommate';
    final otherUserId = chatRoom.participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    final primaryColor = Theme.of(context).primaryColor;

    return InkWell(
      onTap: () => _navigateToChat(context, ref, isRoommate, otherUserId),
      borderRadius: BorderRadius.circular(24),
      child: GlassContainer.standard(
        context: context,
        borderRadius: 24,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _buildAvatar(context, isRoommate, otherUserId, ref),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(ref, isRoommate, otherUserId),
                  const SizedBox(height: 6),
                  _buildSubtitle(context),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildTrailing(context, primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, bool isRoommate, String otherUserId, WidgetRef ref) {
    final primaryColor = Theme.of(context).primaryColor;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: isRoommate ? Colors.purple.withOpacity(0.1) : primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isRoommate ? Icons.person_rounded : Icons.home_rounded,
        color: isRoommate ? Colors.purple : primaryColor,
        size: 26,
      ),
    );
  }

  Widget _buildTitle(WidgetRef ref, bool isRoommate, String otherUserId) {
    if (isRoommate) {
      final userProfile = ref.watch(userProfileProvider(otherUserId));
      return userProfile.when(
        data: (user) => Text(
          user?.displayName ?? 'Roommate Chat',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5),
        ),
        loading: () => const Text('...', style: TextStyle(fontWeight: FontWeight.bold)),
        error: (_, __) => const Text('Roommate', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    } else {
      if (chatRoom.listingId.isEmpty) {
        return const Text('Property Chat', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16));
      }
      final listing = ref.watch(listingProvider(chatRoom.listingId));
      return listing.when(
        data: (l) => Text(
          l.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5),
        ),
        loading: () => const Text('...', style: TextStyle(fontWeight: FontWeight.bold)),
        error: (_, __) => const Text('Property', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }
  }

  Widget _buildSubtitle(BuildContext context) {
    String subText = chatRoom.lastMessage ?? (chatRoom.type == 'roommate' ? 'Direct message' : 'Property inquiry');
    return Text(
      subText,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Theme.of(context).hintColor.withOpacity(0.6),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTrailing(BuildContext context, Color primaryColor) {
    final hasUnread = chatRoom.lastMessageSenderId != null &&
        chatRoom.lastMessageSenderId != currentUserId;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (chatRoom.lastTimestamp != null)
          Text(
            _formatDate(chatRoom.lastTimestamp!),
            style: TextStyle(color: Theme.of(context).hintColor.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w700),
          ),
        if (hasUnread) ...[
          const SizedBox(height: 6),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 6, spreadRadius: 1),
              ],
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
    return DateFormat('dd/MM').format(date);
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
    context.push('/chat-detail', extra: {'chatRoomId': chatRoom.id, 'title': title});
  }
}
