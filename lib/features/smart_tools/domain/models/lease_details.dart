class LeaseDetails {
  final String tenantName;
  final String ownerName;
  final String propertyAddress;
  final double rentAmount;
  final double securityDeposit;
  final int durationMonths;
  final DateTime startDate;

  LeaseDetails({
    required this.tenantName,
    required this.ownerName,
    required this.propertyAddress,
    required this.rentAmount,
    required this.securityDeposit,
    required this.durationMonths,
    required this.startDate,
  });

  Map<String, dynamic> toJson() => {
    'tenantName': tenantName,
    'ownerName': ownerName,
    'propertyAddress': propertyAddress,
    'rentAmount': rentAmount,
    'securityDeposit': securityDeposit,
    'durationMonths': durationMonths,
    'startDate': startDate.toIso8601String(),
  };

  factory LeaseDetails.empty() => LeaseDetails(
    tenantName: '',
    ownerName: '',
    propertyAddress: '',
    rentAmount: 0,
    securityDeposit: 0,
    durationMonths: 11,
    startDate: DateTime.now().add(const Duration(days: 7)),
  );
}
