import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:house_rental/core/widgets/glass_container.dart';
import 'package:go_router/go_router.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/chat/domain/entities/chat_room_entity.dart';
import 'package:house_rental/features/chat/presentation/providers/chat_providers.dart';
import 'package:house_rental/features/listings/presentation/providers/listings_providers.dart';

// ── Filter tab enum ──────────────────────────────────────────────
enum _ChatFilter { all, property, unread }

extension _ChatFilterLabel on _ChatFilter {
  String get label {
    switch (this) {
      case _ChatFilter.all:      return 'All';
      case _ChatFilter.property: return 'Property';
      case _ChatFilter.unread:   return 'Unread';
    }
  }
}

class ChatInboxPage extends ConsumerStatefulWidget {
  const ChatInboxPage({super.key});

  @override
  ConsumerState<ChatInboxPage> createState() => _ChatInboxPageState();
}

class _ChatInboxPageState extends ConsumerState<ChatInboxPage> {
  _ChatFilter _selectedFilter = _ChatFilter.all;
  bool _searchOpen = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ChatRoomEntity> _applyFilter(
      List<ChatRoomEntity> rooms, String currentUserId) {
    var list = rooms;

    // Tab filter
    switch (_selectedFilter) {
      case _ChatFilter.all:
        break;
      case _ChatFilter.property:
        list = list.where((r) => r.type != 'roommate').toList();
        break;
      case _ChatFilter.unread:
        list = list
            .where((r) =>
                r.lastMessageSenderId != null &&
                r.lastMessageSenderId != currentUserId)
            .toList();
        break;
    }

    // Search filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list
          .where((r) =>
              (r.lastMessage ?? '').toLowerCase().contains(q) ||
              r.listingId.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: _searchOpen
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38),
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              )
            : const Text(
                'Messages',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    letterSpacing: -1),
              ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Search toggle
          Container(
            margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            child: GlassContainer.standard(
              context: context,
              borderRadius: 15,
              padding: EdgeInsets.zero,
              child: IconButton(
                icon: Icon(
                  _searchOpen ? Icons.close_rounded : Icons.search_rounded,
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _searchOpen = !_searchOpen;
                    if (!_searchOpen) {
                      _searchQuery = '';
                      _searchController.clear();
                    }
                  });
                },
              ),
            ),
          ),
          // Mark-all-read icon
          Container(
            margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            child: GlassContainer.standard(
              context: context,
              borderRadius: 15,
              padding: EdgeInsets.zero,
              child: IconButton(
                icon: const Icon(Icons.done_all_rounded, size: 22),
                tooltip: 'Mark all as read',
                onPressed: () async {
                  final user = ref.read(authStateProvider).value;
                  if (user == null) return;
                  
                  final rooms = ref.read(userChatRoomsProvider(user.uid)).value ?? [];
                  final markAsRead = ref.read(markAsReadUseCaseProvider);
                  
                  int marked = 0;
                  for (final room in rooms) {
                    if (room.lastMessageSenderId != null && room.lastMessageSenderId != user.uid) {
                      await markAsRead(chatId: room.id, userId: user.uid);
                      marked++;
                    }
                  }
                  
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(marked > 0 ? 'Marked $marked as read' : 'No unread messages')),
                  );
                },
              ),
            ),
          ),
          // Clear-all messages icon
          Container(
            margin: const EdgeInsets.only(right: 20, top: 8, bottom: 8),
            child: GlassContainer.standard(
              context: context,
              borderRadius: 15,
              padding: EdgeInsets.zero,
              child: IconButton(
                icon: const Icon(Icons.delete_sweep_rounded, size: 22, color: Colors.redAccent),
                tooltip: 'Clear all messages',
                onPressed: () async {
                  final user = ref.read(authStateProvider).value;
                  if (user == null) return;

                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Clear All Messages?', style: TextStyle(fontWeight: FontWeight.w900)),
                      content: const Text('This will permanently delete all your conversations. This action cannot be undone.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Clear All', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await ref.read(deleteAllChatsUseCaseProvider)(user.uid);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All messages cleared')),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: 60,
                      color: isDark ? Colors.white24 : Colors.black26),
                  const SizedBox(height: 16),
                  const Text('Please login to view messages',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }

          final chatRoomsAsync = ref.watch(userChatRoomsProvider(user.uid));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // ── Filter Chips ─────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: _ChatFilter.values.map((filter) {
                    final isSelected = _selectedFilter == filter;

                    // Count unread for badge
                    int? badge;
                    if (filter == _ChatFilter.unread) {
                      final rooms = chatRoomsAsync.value ?? [];
                      badge = rooms
                          .where((r) =>
                              r.lastMessageSenderId != null &&
                              r.lastMessageSenderId != user.uid)
                          .length;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedFilter = filter),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryColor
                                : (isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.black.withOpacity(0.04)),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? primaryColor
                                  : (isDark
                                      ? Colors.white12
                                      : Colors.black12),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                filter.label,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.white60
                                          : Colors.black54),
                                  fontWeight: isSelected
                                      ? FontWeight.w900
                                      : FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              if (badge != null && badge > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white
                                        : primaryColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$badge',
                                    style: TextStyle(
                                      color: isSelected
                                          ? primaryColor
                                          : Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // ── Conversation List ─────────────────────────────────
              Expanded(
                child: chatRoomsAsync.when(
                  data: (chatRooms) {
                    final filtered =
                        _applyFilter(chatRooms, user.uid);

                    if (filtered.isEmpty) {
                      return _buildEmptyState(context, isDark);
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(
                          left: 20, right: 20, top: 10, bottom: 100),
                      itemCount: filtered.length,
                      physics: const BouncingScrollPhysics(),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return ChatRoomTile(
                          chatRoom: filtered[index],
                          currentUserId: user.uid,
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                      child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 48, color: Colors.redAccent),
                          const SizedBox(height: 12),
                          Text('Could not load messages\n$error',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error: $error')),
      ),

      // ── New Conversation FAB ──────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showNewConversationSheet(context);
        },
        backgroundColor: Theme.of(context).primaryColor,
        label: const Text('New Chat',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800)),
        icon: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final isSearching =
        _searchQuery.isNotEmpty || _selectedFilter != _ChatFilter.all;
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
              child: Icon(
                isSearching
                    ? Icons.search_off_rounded
                    : Icons.forum_rounded,
                size: 50,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              isSearching ? 'No results found' : 'No messages yet',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5),
            ),
            const SizedBox(height: 12),
            Text(
              isSearching
                  ? 'Try a different search term or filter.'
                  : 'When you contact a host or receive an inquiry,\nyour conversations will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).hintColor.withOpacity(0.6),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            if (_selectedFilter != _ChatFilter.all ||
                _searchQuery.isNotEmpty) ...[
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedFilter = _ChatFilter.all;
                    _searchQuery = '';
                    _searchController.clear();
                    _searchOpen = false;
                  });
                },
                icon: const Icon(Icons.clear_all_rounded),
                label: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showNewConversationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Start a New Chat',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5)),
            const SizedBox(height: 8),
            Text(
              'To message a property owner, open a listing\nand tap "Contact Owner".',
              style: TextStyle(
                  color: Theme.of(context).hintColor.withOpacity(0.7),
                  fontSize: 14,
                  height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/');
                },
                icon: const Icon(Icons.home_rounded),
                label: const Text('Browse Properties'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Chat Room Tile
// ─────────────────────────────────────────────────────────────────
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
    final hasUnread = chatRoom.lastMessageSenderId != null &&
        chatRoom.lastMessageSenderId != currentUserId;

    return InkWell(
      onTap: () => _navigateToChat(context, ref, isRoommate, otherUserId),
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: hasUnread
              ? Border.all(color: primaryColor.withOpacity(0.3), width: 1.5)
              : null,
        ),
        child: GlassContainer.standard(
          context: context,
          borderRadius: 24,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildAvatar(context, ref, isRoommate, primaryColor, hasUnread),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitle(ref, isRoommate, otherUserId),
                    const SizedBox(height: 5),
                    _buildSubtitle(context, hasUnread),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildTrailing(context, primaryColor, hasUnread),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, WidgetRef ref, bool isRoommate,
      Color primaryColor, bool hasUnread) {
    if (isRoommate) {
      return Stack(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: Colors.purple, size: 26),
          ),
          if (hasUnread) _buildUnreadIndicator(context, primaryColor),
        ],
      );
    }

    final listingAsync = ref.watch(listingProvider(chatRoom.listingId));
    return listingAsync.when(
      data: (listing) => Stack(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: listing.allImages.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(listing.allImages.first),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: primaryColor.withOpacity(0.1),
            ),
            child: listing.allImages.isEmpty
                ? Icon(Icons.home_rounded, color: primaryColor, size: 26)
                : null,
          ),
          if (hasUnread) _buildUnreadIndicator(context, primaryColor),
        ],
      ),
      loading: () => _buildEmptyAvatar(primaryColor),
      error: (_, __) => _buildEmptyAvatar(primaryColor),
    );
  }

  Widget _buildEmptyAvatar(Color primaryColor) {
    return Container(
      width: 56, height: 56,
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(Icons.home_rounded, color: primaryColor, size: 26),
    );
  }

  Widget _buildUnreadIndicator(BuildContext context, Color primaryColor) {
    return Positioned(
      top: 0,
      right: 0,
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: primaryColor,
          shape: BoxShape.circle,
          border: Border.all(
              color: Theme.of(context).scaffoldBackgroundColor,
              width: 2),
        ),
      ),
    );
  }

  Widget _buildTitle(
      WidgetRef ref, bool isRoommate, String otherUserId) {
    if (isRoommate) {
      final userProfile = ref.watch(userProfileProvider(otherUserId));
      return userProfile.when(
        data: (user) => Text(
          user?.displayName ?? 'Direct Chat',
          style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: -0.5),
        ),
        loading: () =>
            const Text('...', style: TextStyle(fontWeight: FontWeight.bold)),
        error: (_, __) =>
            const Text('Direct Chat',
                style: TextStyle(fontWeight: FontWeight.bold)),
      );
    } else {
      if (chatRoom.listingId.isEmpty) {
        return const Text('Property Chat',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16));
      }
      final listing = ref.watch(listingProvider(chatRoom.listingId));
      return listing.when(
        data: (l) => Text(
          l.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: -0.5),
        ),
        loading: () =>
            const Text('...', style: TextStyle(fontWeight: FontWeight.bold)),
        error: (_, __) =>
            const Text('Property',
                style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }
  }

  Widget _buildSubtitle(BuildContext context, bool hasUnread) {
    final subText = chatRoom.lastMessage ??
        (chatRoom.type == 'roommate'
            ? 'Direct message'
            : 'Property inquiry');
    return Text(
      subText,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: hasUnread
            ? Theme.of(context).textTheme.bodyMedium?.color
            : Theme.of(context).hintColor.withOpacity(0.6),
        fontSize: 13,
        fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
      ),
    );
  }

  Widget _buildTrailing(
      BuildContext context, Color primaryColor, bool hasUnread) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (chatRoom.lastTimestamp != null)
          Text(
            _formatDate(chatRoom.lastTimestamp!),
            style: TextStyle(
              color: hasUnread
                  ? primaryColor
                  : Theme.of(context).hintColor.withOpacity(0.5),
              fontSize: 11,
              fontWeight: hasUnread ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        if (hasUnread) ...[
          const SizedBox(height: 5),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('NEW',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5)),
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

  void _navigateToChat(BuildContext context, WidgetRef ref,
      bool isRoommate, String otherUserId) async {
    String title = 'Chat';
    if (isRoommate && otherUserId.isNotEmpty) {
      try {
        final user =
            await ref.read(userProfileProvider(otherUserId).future);
        title = user?.displayName ?? 'Direct Chat';
      } catch (_) {
        title = 'Direct Chat';
      }
    } else if (chatRoom.listingId.isNotEmpty) {
      try {
        final listing =
            await ref.read(listingProvider(chatRoom.listingId).future);
        title = listing.title;
      } catch (_) {
        title = 'Property Chat';
      }
    }

    if (!context.mounted) return;
    context.push('/chat-detail',
        extra: {'chatRoomId': chatRoom.id, 'title': title});
  }
}
