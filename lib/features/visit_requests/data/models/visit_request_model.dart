import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_rental/features/visit_requests/domain/entities/visit_request_entity.dart';

class VisitRequestModel extends VisitRequestEntity {
  const VisitRequestModel({
    required super.id,
    required super.listingId,
    required super.listingTitle,
    required super.listingImage,
    required super.ownerId,
    required super.tenantId,
    required super.tenantName,
    required super.date,
    required super.time,
    super.message,
    required super.status,
    required super.createdAt,
  });

  factory VisitRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VisitRequestModel(
      id: doc.id,
      listingId: data['listingId'] ?? '',
      listingTitle: data['listingTitle'] ?? '',
      listingImage: data['listingImage'] ?? '',
      ownerId: data['ownerId'] ?? '',
      tenantId: data['tenantId'] ?? '',
      tenantName: data['tenantName'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      time: data['time'] ?? '',
      message: data['message'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'listingId': listingId,
      'listingTitle': listingTitle,
      'listingImage': listingImage,
      'ownerId': ownerId,
      'tenantId': tenantId,
      'tenantName': tenantName,
      'date': Timestamp.fromDate(date),
      'time': time,
      'message': message,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
