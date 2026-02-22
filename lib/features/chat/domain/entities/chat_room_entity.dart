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

  const ChatRoomEntity({
    required this.id,
    required this.renterId,
    required this.ownerId,
    required this.listingId,
    this.type,
    required this.participants,
    this.lastMessage,
    this.lastTimestamp,
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
    );
  }

  @override
  List<Object?> get props => [id, renterId, ownerId, listingId, type, participants, lastMessage, lastTimestamp];
}
