import 'package:equatable/equatable.dart';

class RoommateEntity extends Equatable {
  final String userId;
  final String name;
  final String city;
  final int budget;
  final String gender;
  final String preferredGender;
  final String occupation;
  final String bio;
  final DateTime? createdAt;

  const RoommateEntity({
    required this.userId,
    required this.name,
    required this.city,
    required this.budget,
    required this.gender,
    required this.preferredGender,
    required this.occupation,
    required this.bio,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        userId,
        name,
        city,
        budget,
        gender,
        preferredGender,
        occupation,
        bio,
        createdAt,
      ];
}
