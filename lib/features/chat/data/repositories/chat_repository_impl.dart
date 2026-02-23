import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:house_rental/features/chat/domain/entities/chat_room_entity.dart';
import 'package:house_rental/features/chat/domain/entities/message_entity.dart';
import 'package:house_rental/features/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;

  ChatRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, ChatRoomEntity>> getOrCreateChatRoom({
    required String renterId,
    required String ownerId,
    required String listingId,
  }) async {
    try {
      final chatRoom = await _remoteDataSource.createOrGetChat(
        listingId: listingId,
        ownerId: ownerId,
        currentUserId: renterId,
      );
      return Right(chatRoom);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<List<MessageEntity>> getMessagesStream(String chatRoomId) {
    return _remoteDataSource.streamMessages(chatRoomId);
  }

  @override
  Future<Either<Failure, void>> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String text,
  }) async {
    try {
      await _remoteDataSource.sendMessage(
        chatId: chatRoomId,
        text: text,
        senderId: senderId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<void> setTyping(String chatId, String userId) async {
    await _remoteDataSource.setTyping(chatId, userId);
  }

  @override
  Future<void> clearTyping(String chatId, String userId) async {
    await _remoteDataSource.clearTyping(chatId, userId);
  }

  @override
  Stream<List<ChatRoomEntity>> getUserChatRooms(String userId) {
    return _remoteDataSource.userChatRoomsStream(userId);
  }
}
