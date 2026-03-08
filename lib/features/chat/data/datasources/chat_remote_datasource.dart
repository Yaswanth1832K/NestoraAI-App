import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_rental/features/chat/data/models/chat_room_model.dart';
import 'package:house_rental/features/chat/data/models/message_model.dart';
import 'package:uuid/uuid.dart';

abstract interface class ChatRemoteDataSource {
  Future<ChatRoomModel> createOrGetChat({
    required String listingId,
    required String ownerId,
    required String currentUserId,
  });

  Future<void> sendMessage({
    required String chatId,
    required String text,
    required String senderId,
  });

  Stream<List<MessageModel>> streamMessages(String chatId);

  Stream<List<ChatRoomModel>> userChatRoomsStream(String userId);

  Future<void> setTyping(String chatId, String userId);

  Future<void> clearTyping(String chatId, String userId);

  Future<void> markAsRead(String chatId, String userId);
  Future<void> deleteAllChats(String userId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore _firestore;

  ChatRemoteDataSourceImpl(this._firestore);

  // ── Deterministic Mock Data Generator ─────────────────────────────────────
  List<ChatRoomModel> _getGeneratedRooms(String userId) {
    return [
      ChatRoomModel(
        id: 'mock_chat_1',
        renterId: userId,
        ownerId: 'owner_demo',
        listingId: 'demo_coimbatore_villa_1_owner_demo',
        participants: [userId, 'owner_demo'],
        lastMessage: 'Is the property still available?',
        lastTimestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        lastMessageSenderId: 'owner_demo',
      ),
      ChatRoomModel(
        id: 'mock_chat_2',
        renterId: userId,
        ownerId: 'owner_demo_2',
        listingId: 'demo_coimbatore_apartment_2_owner_demo_2',
        participants: [userId, 'owner_demo_2'],
        lastMessage: 'Can we schedule a visit this weekend?',
        lastTimestamp: DateTime.now().subtract(const Duration(hours: 2)),
        lastMessageSenderId: 'owner_demo_2',
      ),
    ];
  }

  @override
  Future<ChatRoomModel> createOrGetChat({
    required String listingId,
    required String ownerId,
    required String currentUserId,
  }) async {
    try {
      final query = await _firestore
          .collection('chats')
          .where('listingId', isEqualTo: listingId)
          .where('participants', arrayContains: currentUserId)
          .get();

      final existingChat = query.docs.where((doc) {
        final participants = List<String>.from(doc.data()['participants'] ?? []);
        return participants.contains(ownerId);
      });

      if (existingChat.isNotEmpty) {
        return ChatRoomModel.fromFirestore(existingChat.first);
      }

      final id = const Uuid().v4();
      final now = DateTime.now();
      final chatRoom = ChatRoomModel(
        id: id,
        renterId: currentUserId,
        ownerId: ownerId,
        listingId: listingId,
        participants: [currentUserId, ownerId],
        lastTimestamp: now,
        lastMessage: 'Chat started',
      );

      final data = chatRoom.toFirestore();
      data['createdAt'] = Timestamp.fromDate(now);

      await _firestore.collection('chats').doc(id).set(data);
      return chatRoom;
    } catch (e) {
      final id = 'local_${listingId}_${currentUserId.substring(0, 4)}';
      return ChatRoomModel(
        id: id,
        renterId: currentUserId,
        ownerId: ownerId,
        listingId: listingId,
        participants: [currentUserId, ownerId],
      );
    }
  }

  @override
  Future<void> sendMessage({
    required String chatId,
    required String text,
    required String senderId,
  }) async {
    try {
      final messageId = const Uuid().v4();
      final now = DateTime.now();

      final message = MessageModel(
        id: messageId,
        senderId: senderId,
        text: text,
        createdAt: now,
      );

      final batch = _firestore.batch();
      batch.set(
        _firestore.collection('chats').doc(chatId).collection('messages').doc(messageId),
        message.toFirestore(),
      );

      batch.update(_firestore.collection('chats').doc(chatId), {
        'lastMessage': text,
        'lastTimestamp': Timestamp.fromDate(now),
        'lastMessageSenderId': senderId,
      });

      await batch.commit();
    } catch (e) {
      // In-memory mock (implementation omitted for brevity, usually handled by Stream.value in demo)
    }
  }

  @override
  Future<void> setTyping(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'typingUserId': userId,
        'typingUpdatedAt': Timestamp.now(),
      });
    } catch (_) {}
  }

  @override
  Future<void> clearTyping(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'typingUserId': null,
        'typingUpdatedAt': null,
      });
    } catch (_) {}
  }

  @override
  Future<void> markAsRead(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessageSenderId': null,
      });
    } catch (_) {
      // Ignore Firestore permission issues for demo
    }
  }

  @override
  Future<void> deleteAllChats(String userId) async {
    try {
      final query = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .get();
      
      final batch = _firestore.batch();
      for (var doc in query.docs) {
        // Delete all messages in the room first (subcollection)
        final messages = await doc.reference.collection('messages').get();
        for (var msg in messages.docs) {
          batch.delete(msg.reference);
        }
        // Delete the room document
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (_) {}
  }

  @override
  Stream<List<MessageModel>> streamMessages(String chatId) async* {
    try {
      await for (final snapshot in _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .snapshots()) {
        final messages =
            snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList();
        messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        yield messages;
      }
    } catch (e) {
      yield [];
    }
  }

  @override
  Stream<List<ChatRoomModel>> userChatRoomsStream(String userId) async* {
    try {
      await for (final snapshot in _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .snapshots()) {
        final firestoreRooms =
            snapshot.docs.map((doc) => ChatRoomModel.fromFirestore(doc)).toList();
        firestoreRooms.sort((a, b) => (b.lastTimestamp ?? DateTime(0))
            .compareTo(a.lastTimestamp ?? DateTime(0)));
        yield firestoreRooms;
      }
    } catch (e) {
      yield [];
    }
  }
}
