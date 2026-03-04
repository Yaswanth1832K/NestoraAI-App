import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';
import 'package:uuid/uuid.dart';

class RentAgreementService {
  Future<Map<String, dynamic>> generateAgreement({
    required ListingEntity listing,
    required String tenantName,
    required String ownerName,
    required double rentAmount,
    required int durationMonths,
  }) async {
    // Simulate complex document generation logic
    final agreementId = const Uuid().v4();
    final timestamp = DateTime.now();
    
    return {
      'id': agreementId,
      'createdAt': timestamp.toIso8601String(),
      'listingTitle': listing.title,
      'address': listing.address,
      'parties': {
        'owner': ownerName,
        'tenant': tenantName,
      },
      'terms': {
        'rent': rentAmount,
        'securityDeposit': rentAmount * 2,
        'duration': '$durationMonths months',
        'noticePeriod': '1 month',
      },
      'clauses': [
        'The tenant shall pay the rent on or before the 5th of every month.',
        'The security deposit is refundable at the end of the tenancy after deductions for damages.',
        'Sub-letting the property is strictly prohibited.',
        'Monthly maintenance charges are included in the rent.',
      ],
      'status': 'draft',
      'esignRequired': true,
    };
  }
}
