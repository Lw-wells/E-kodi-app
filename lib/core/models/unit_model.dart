class UnitModel {
  final String id;
  final String propertyId;
  final String landlordId;
  final String unitNumber; // e.g., "A1", "102"
  final double baseRent;
  final String? currentTenantId;
  final bool isOccupied;

  UnitModel({
    required this.id,
    required this.propertyId,
    required this.landlordId,
    required this.unitNumber,
    required this.baseRent,
    this.currentTenantId,
    this.isOccupied = false,
  });

  factory UnitModel.fromMap(Map<String, dynamic> map, String id) {
    return UnitModel(
      id: id,
      propertyId: map['propertyId'] ?? '',
      landlordId: map['landlordId'] ?? '',
      unitNumber: map['unitNumber'] ?? '',
      baseRent: (map['baseRent'] ?? 0.0).toDouble(),
      currentTenantId: map['currentTenantId'],
      isOccupied: map['isOccupied'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'propertyId': propertyId,
      'landlordId': landlordId,
      'unitNumber': unitNumber,
      'baseRent': baseRent,
      'currentTenantId': currentTenantId,
      'isOccupied': isOccupied,
    };
  }

  UnitModel copyWith({
    String? unitNumber,
    double? baseRent,
    String? currentTenantId,
    bool? isOccupied,
  }) {
    return UnitModel(
      id: id,
      propertyId: propertyId,
      landlordId: landlordId,
      unitNumber: unitNumber ?? this.unitNumber,
      baseRent: baseRent ?? this.baseRent,
      currentTenantId: currentTenantId ?? this.currentTenantId,
      isOccupied: isOccupied ?? this.isOccupied,
    );
  }
}
