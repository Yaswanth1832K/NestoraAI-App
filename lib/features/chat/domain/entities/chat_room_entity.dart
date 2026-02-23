import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ChatRoomEntity extends Equatable {
  final String id;
  final String renterId;
  final String ownerId;
  final String listingId;
  final String? type; // 'property' or 'roommate'
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastTimestamp;
  /// Sender uid of the last message; used for unread indicator when != current user.
  final String? lastMessageSenderId;
  /// User id currently typing (for typing indicator).
  final String? typingUserId;
  final DateTime? typingUpdatedAt;

  const ChatRoomEntity({
    required this.id,
    required this.renterId,
    required this.ownerId,
    required this.listingId,
    this.type,
    required this.participants,
    this.lastMessage,
    this.lastTimestamp,
    this.lastMessageSenderId,
    this.typingUserId,
    this.typingUpdatedAt,
  });

  factory ChatRoomEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoomEntity(
      id: doc.id,
      renterId: data['renterId'] ?? '',
      ownerId: data['ownerId'] ?? '',
      listingId: data['listingId'] ?? '',
      type: data['type'],
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'],
      lastTimestamp: (data['lastMessageTime'] as Timestamp?)?.toDate() ??
                     (data['lastTimestamp'] as Timestamp?)?.toDate(),
      lastMessageSenderId: data['lastMessageSenderId'] as String?,
      typingUserId: data['typingUserId'] as String?,
      typingUpdatedAt: (data['typingUpdatedAt'] as Timestamp?)?.toDate(),
    );
  }

  @override
  List<Object?> get props => [id, renterId, ownerId, listingId, type, participants, lastMessage, lastTimestamp, lastMessageSenderId, typingUserId, typingUpdatedAt];
}
