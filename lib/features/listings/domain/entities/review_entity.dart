import 'package:equatable/equatable.dart';

class ReviewEntity extends Equatable {
  final String id;
  final String listingId;
  final String listingTitle;
  final String ownerId;
  final String reviewerId;
  final String reviewerName;
  final String bookingId;
  final double rating;
  final String comment;
  final DateTime createdAt;

  const ReviewEntity({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.ownerId,
    required this.reviewerId,
    required this.reviewerName,
    required this.bookingId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        listingId,
        listingTitle,
        ownerId,
        reviewerId,
        reviewerName,
        bookingId,
        rating,
        comment,
        createdAt,
      ];
}
