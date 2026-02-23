import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_rental/features/chat/domain/entities/chat_room_entity.dart';

class ChatRoomModel extends ChatRoomEntity {
  const ChatRoomModel({
    required super.id,
    required super.renterId,
    required super.ownerId,
    required super.listingId,
    required super.participants,
    super.lastMessage,
    super.lastTimestamp,
    super.lastMessageSenderId,
    super.typingUserId,
    super.typingUpdatedAt,
  });

  factory ChatRoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoomModel(
      id: doc.id,
      renterId: data['renterId'] ?? '',
      ownerId: data['ownerId'] ?? '',
      listingId: data['listingId'] ?? '',
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'],
      lastTimestamp: (data['lastTimestamp'] as Timestamp?)?.toDate(),
      lastMessageSenderId: data['lastMessageSenderId'] as String?,
      typingUserId: data['typingUserId'] as String?,
      typingUpdatedAt: (data['typingUpdatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'renterId': renterId,
      'ownerId': ownerId,
      'listingId': listingId,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastTimestamp': lastTimestamp != null ? Timestamp.fromDate(lastTimestamp!) : null,
      if (lastMessageSenderId != null) 'lastMessageSenderId': lastMessageSenderId,
      if (typingUserId != null) 'typingUserId': typingUserId,
      if (typingUpdatedAt != null) 'typingUpdatedAt': Timestamp.fromDate(typingUpdatedAt!),
    };
  }
}
