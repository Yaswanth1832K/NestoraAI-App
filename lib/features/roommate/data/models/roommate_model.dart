import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_rental/features/roommate/domain/entities/roommate_entity.dart';

class RoommateModel extends RoommateEntity {
  const RoommateModel({
    required super.userId,
    required super.name,
    required super.city,
    required super.budget,
    required super.gender,
    required super.preferredGender,
    required super.occupation,
    required super.bio,
    super.createdAt,
  });

  factory RoommateModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoommateModel(
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      city: data['city'] ?? '',
      budget: (data['budget'] as num?)?.toInt() ?? 0,
      gender: data['gender'] ?? '',
      preferredGender: data['preferredGender'] ?? '',
      occupation: data['occupation'] ?? '',
      bio: data['bio'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'city': city,
      'budget': budget,
      'gender': gender,
      'preferredGender': preferredGender,
      'occupation': occupation,
      'bio': bio,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  factory RoommateModel.fromEntity(RoommateEntity entity) {
    return RoommateModel(
      userId: entity.userId,
      name: entity.name,
      city: entity.city,
      budget: entity.budget,
      gender: entity.gender,
      preferredGender: entity.preferredGender,
      occupation: entity.occupation,
      bio: entity.bio,
      createdAt: entity.createdAt,
    );
  }
}
