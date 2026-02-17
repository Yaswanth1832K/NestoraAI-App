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
      tenantId: data['tenantId'] ?? data['renterId'] ?? '', 
      tenantName: data['tenantName'] ?? '',
      date: _parseDate(data['date'] ?? data['visitDate']), 
      time: data['time'] ?? '',
      message: data['message'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: _parseDate(data['createdAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  Map<String, dynamic> toFirestore() {
    return {
      'listingId': listingId,
      'listingTitle': listingTitle,
      'listingImage': listingImage,
      'ownerId': ownerId,
      'renterId': tenantId,
      'visitDate': Timestamp.fromDate(date),
      'time': time,
      'message': message,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'participants': [ownerId, tenantId], // Important for security rules
    };
  }
}
