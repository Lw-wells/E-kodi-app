class TenantModel {
  final String id;
  final String landlordId;
  final String propertyId;
  final String unitId;
  final String fullName;
  final String phoneNumber; // Used for WhatsApp and MPesa
  final String nationalId;
  final double accountBalance; // Current outstanding (-) or overpaid (+)
  final DateTime leaseStart;
  final DateTime? leaseEnd;
  final bool isActive;

  TenantModel({
    required this.id,
    required this.landlordId,
    required this.propertyId,
    required this.unitId,
    required this.fullName,
    required this.phoneNumber,
    required this.nationalId,
    this.accountBalance = 0.0,
    required this.leaseStart,
    this.leaseEnd,
    this.isActive = true,
  });

  factory TenantModel.fromMap(Map<String, dynamic> map, String id) {
    return TenantModel(
      id: id,
      landlordId: map['landlordId'] ?? '',
      propertyId: map['propertyId'] ?? '',
      unitId: map['unitId'] ?? '',
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      nationalId: map['nationalId'] ?? '',
      accountBalance: (map['accountBalance'] ?? 0.0).toDouble(),
      leaseStart: map['leaseStart']?.toDate() ?? DateTime.now(),
      leaseEnd: map['leaseEnd']?.toDate(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'landlordId': landlordId,
      'propertyId': propertyId,
      'unitId': unitId,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'nationalId': nationalId,
      'accountBalance': accountBalance,
      'leaseStart': leaseStart,
      'leaseEnd': leaseEnd,
      'isActive': isActive,
    };
  }

  TenantModel copyWith({
    String? propertyId,
    String? unitId,
    String? fullName,
    String? phoneNumber,
    String? nationalId,
    double? accountBalance,
    DateTime? leaseStart,
    DateTime? leaseEnd,
    bool? isActive,
  }) {
    return TenantModel(
      id: id,
      landlordId: landlordId,
      propertyId: propertyId ?? this.propertyId,
      unitId: unitId ?? this.unitId,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      nationalId: nationalId ?? this.nationalId,
      accountBalance: accountBalance ?? this.accountBalance,
      leaseStart: leaseStart ?? this.leaseStart,
      leaseEnd: leaseEnd ?? this.leaseEnd,
      isActive: isActive ?? this.isActive,
    );
  }
}
