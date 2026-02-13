import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String role; // 'owner' or 'renter'

  const UserEntity({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.role = 'renter', // Default to renter for safety
  });

  @override
  List<Object?> get props => [uid, email, displayName, photoUrl, role];
}
