import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/core/providers/firebase_provider.dart';
import 'package:house_rental/features/roommate/data/repositories/roommate_repository_impl.dart';
import 'package:house_rental/features/roommate/domain/repositories/roommate_repository.dart';
import 'package:house_rental/features/roommate/domain/usecases/save_roommate_profile_usecase.dart';
import 'package:house_rental/features/roommate/domain/usecases/get_roommate_profile_usecase.dart';
import 'package:house_rental/features/roommate/domain/usecases/find_roommate_matches_usecase.dart';
import 'package:house_rental/features/roommate/domain/usecases/get_or_create_roommate_chat_usecase.dart';

final roommateRepositoryProvider = Provider<RoommateRepository>((ref) {
  return RoommateRepositoryImpl(ref.watch(firestoreProvider));
});

final saveRoommateProfileUseCaseProvider = Provider<SaveRoommateProfileUseCase>((ref) {
  return SaveRoommateProfileUseCase(ref.watch(roommateRepositoryProvider));
});

final getRoommateProfileUseCaseProvider = Provider<GetRoommateProfileUseCase>((ref) {
  return GetRoommateProfileUseCase(ref.watch(roommateRepositoryProvider));
});

final findRoommateMatchesUseCaseProvider = Provider<FindRoommateMatchesUseCase>((ref) {
  return FindRoommateMatchesUseCase(ref.watch(roommateRepositoryProvider));
});

final getOrCreateRoommateChatUseCaseProvider = Provider<GetOrCreateRoommateChatUseCase>((ref) {
  return GetOrCreateRoommateChatUseCase(ref.watch(firestoreProvider));
});
