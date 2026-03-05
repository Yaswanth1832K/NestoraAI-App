import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/core/widgets/glass_container.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/chat/presentation/providers/chat_providers.dart';
import 'package:house_rental/features/chat/presentation/pages/chat_page.dart';
import 'package:intl/intl.dart';

class InboxPage extends ConsumerWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider).value;
    final primaryColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Inbox',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: -1),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20, top: 8, bottom: 8),
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
        ],
      ),
      body: authState == null
          ? _buildEmptyState(
              context,
              Icons.lock_outline_rounded,
              'Login to see messages',
              'Once you log in, you can message hosts to book stays.',
            )
          : DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GlassContainer.standard(
                      context: context,
                      padding: const EdgeInsets.all(4),
                      borderRadius: 20,
                      child: TabBar(
                        labelColor: Colors.white,
                        unselectedLabelColor: Theme.of(context).hintColor.withOpacity(0.5),
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: primaryColor,
                        ),
                        dividerColor: Colors.transparent,
                        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        tabs: const [
                          Tab(text: 'Messages'),
                          Tab(text: 'Notifications'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildMessagesList(context, ref, authState.uid),
                        _buildEmptyState(
                          context,
                          Icons.notifications_none_rounded,
                          'No notifications',
                          'We\'ll notify you about property updates, price drops, and account activity.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMessagesList(BuildContext context, WidgetRef ref, String userId) {
    final chatsAsync = ref.watch(userChatRoomsProvider(userId));

    return chatsAsync.when(
      data: (chats) {
        if (chats.isEmpty) {
          return _buildEmptyState(
            context,
            Icons.chat_bubble_outline_rounded,
            'No new messages',
            'When you contact a host or send a request, you’ll see your conversations here.',
          );
        }

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: chats.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final chat = chats[index];
            final otherMember = chat.renterId == userId ? 'Host' : 'Guest';
            return GlassContainer.standard(
              context: context,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderRadius: 20,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Icon(Icons.person, color: Theme.of(context).primaryColor),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nestora $otherMember',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    if (chat.lastTimestamp != null)
                      Text(
                        DateFormat('MMM d').format(chat.lastTimestamp!),
                        style: TextStyle(color: Theme.of(context).hintColor.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    chat.lastMessage ?? 'Start a conversation...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Theme.of(context).hintColor, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        chatRoomId: chat.id,
                        title: 'Support Chat',
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, __) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildEmptyState(BuildContext context, IconData icon, String title, String subtitle) {
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
              child: Icon(icon, size: 50, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
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
