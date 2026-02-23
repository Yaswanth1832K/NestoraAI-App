import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/features/chat/domain/entities/chat_room_entity.dart';
import 'package:house_rental/features/chat/domain/entities/message_entity.dart';

abstract class ChatRepository {
  Future<Either<Failure, ChatRoomEntity>> getOrCreateChatRoom({
    required String renterId,
    required String ownerId,
    required String listingId,
  });

  Stream<List<MessageEntity>> getMessagesStream(String chatRoomId);

  Future<Either<Failure, void>> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String text,
  });

  Future<void> setTyping(String chatId, String userId);
  Future<void> clearTyping(String chatId, String userId);

  Stream<List<ChatRoomEntity>> getUserChatRooms(String userId);
}
