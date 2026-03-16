enum UtilityType { water, electricity, garbage, security, maintenance, internet }

class UtilityBillModel {
  final String id;
  final String landlordId;
  final String propertyId;
  final String unitId;
  final String tenantId;
  final UtilityType type;
  
  // For variable bills (like Water meters)
  final double? previousReading; 
  final double? currentReading;
  final double amount;
  
  final DateTime billingPeriod;
  final DateTime dueDate;
  final bool isPaid;

  UtilityBillModel({
    required this.id,
    required this.landlordId,
    required this.propertyId,
    required this.unitId,
    required this.tenantId,
    required this.type,
    this.previousReading,
    this.currentReading,
    required this.amount,
    required this.billingPeriod,
    required this.dueDate,
    this.isPaid = false,
  });

  factory UtilityBillModel.fromMap(Map<String, dynamic> map, String id) {
    return UtilityBillModel(
      id: id,
      landlordId: map['landlordId'] ?? '',
      propertyId: map['propertyId'] ?? '',
      unitId: map['unitId'] ?? '',
      tenantId: map['tenantId'] ?? '',
      type: UtilityType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'water'),
        orElse: () => UtilityType.water,
      ),
      previousReading: map['previousReading']?.toDouble(),
      currentReading: map['currentReading']?.toDouble(),
      amount: (map['amount'] ?? 0.0).toDouble(),
      billingPeriod: map['billingPeriod']?.toDate() ?? DateTime.now(),
      dueDate: map['dueDate']?.toDate() ?? DateTime.now().add(const Duration(days: 7)),
      isPaid: map['isPaid'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'landlordId': landlordId,
      'propertyId': propertyId,
      'unitId': unitId,
      'tenantId': tenantId,
      'type': type.name,
      'previousReading': previousReading,
      'currentReading': currentReading,
      'amount': amount,
      'billingPeriod': billingPeriod,
      'dueDate': dueDate,
      'isPaid': isPaid,
    };
  }

  UtilityBillModel copyWith({
    double? previousReading,
    double? currentReading,
    double? amount,
    DateTime? dueDate,
    bool? isPaid,
  }) {
    return UtilityBillModel(
      id: id,
      landlordId: landlordId,
      propertyId: propertyId,
      unitId: unitId,
      tenantId: tenantId,
      type: type,
      previousReading: previousReading ?? this.previousReading,
      currentReading: currentReading ?? this.currentReading,
      amount: amount ?? this.amount,
      billingPeriod: billingPeriod,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}
