import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/features/roommate/data/models/roommate_model.dart';
import 'package:house_rental/features/roommate/domain/entities/roommate_entity.dart';
import 'package:house_rental/features/roommate/domain/repositories/roommate_repository.dart';

class RoommateRepositoryImpl implements RoommateRepository {
  final FirebaseFirestore _firestore;

  RoommateRepositoryImpl(this._firestore);

  @override
  Future<Either<Failure, void>> saveRoommateProfile(RoommateEntity roommate) async {
    try {
      final model = RoommateModel.fromEntity(roommate);
      await _firestore.collection('roommates').doc(roommate.userId).set(model.toFirestore());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, RoommateEntity?>> getRoommateProfile(String userId) async {
    try {
      final doc = await _firestore.collection('roommates').doc(userId).get();
      if (!doc.exists) return const Right(null);
      return Right(RoommateModel.fromFirestore(doc));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RoommateEntity>>> findMatches(
    String city,
    int budget,
    String gender,
  ) async {
    try {
      // Step 1: Query by city and budget range (+3000)
      final querySnapshot = await _firestore
          .collection('roommates')
          .where('city', isEqualTo: city)
          .where('budget', isLessThanOrEqualTo: budget + 3000)
          .get();

      final matches = querySnapshot.docs.map((doc) => RoommateModel.fromFirestore(doc)).toList();

      return Right(matches);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
