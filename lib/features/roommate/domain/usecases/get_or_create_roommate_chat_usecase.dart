import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/features/chat/domain/entities/chat_room_entity.dart';
import 'package:house_rental/features/chat/domain/repositories/chat_repository.dart';

class GetOrCreateRoommateChatUseCase {
  final FirebaseFirestore _firestore;

  GetOrCreateRoommateChatUseCase(this._firestore);

  Future<Either<Failure, ChatRoomEntity>> call(String myId, String otherId) async {
    try {
      // 1. Check if a roommate chat already exists between these two
      final query = await _firestore
          .collection('chats')
          .where('type', isEqualTo: 'roommate')
          .where('participants', arrayContains: myId)
          .get();

      final existingChatDoc = query.docs.where((doc) {
        final participants = List<String>.from(doc.data()['participants'] ?? []);
        return participants.contains(otherId);
      }).firstOrNull;

      if (existingChatDoc != null) {
        return Right(ChatRoomEntity.fromFirestore(existingChatDoc));
      }

      // 2. Create new roommate chat
      final chatRef = await _firestore.collection('chats').add({
        'participants': [myId, otherId],
        'type': 'roommate',
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'listingId': '', // Empty for roommate chats
        'ownerId': '',   // No specific owner in peer-to-peer
        'renterId': myId, // Initiator
      });

      final newDoc = await chatRef.get();
      return Right(ChatRoomEntity.fromFirestore(newDoc));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
