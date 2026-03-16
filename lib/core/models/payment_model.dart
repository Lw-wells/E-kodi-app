enum PaymentType { rent, utility, penalty, deposit, other }
enum PaymentStatus { pending, completed, failed, matched, unmatched }

class PaymentModel {
  final String id;
  final String landlordId;
  final String? tenantId; // Null if unmatched (e.g., M-Pesa Daraja payload missing acc info)
  final String? propertyId;
  final String? unitId;
  final double amount;
  final String method; // e.g., "MPESA", "CASH", "BANK"
  final String transactionReference; // e.g., "QWX12345XYZ"
  final DateTime timestamp;
  final PaymentStatus status;
  final PaymentType type;
  final String? notes;

  PaymentModel({
    required this.id,
    required this.landlordId,
    this.tenantId,
    this.propertyId,
    this.unitId,
    required this.amount,
    required this.method,
    required this.transactionReference,
    required this.timestamp,
    this.status = PaymentStatus.unmatched,
    this.type = PaymentType.rent,
    this.notes,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentModel(
      id: id,
      landlordId: map['landlordId'] ?? '',
      tenantId: map['tenantId'],
      propertyId: map['propertyId'],
      unitId: map['unitId'],
      amount: (map['amount'] ?? 0.0).toDouble(),
      method: map['method'] ?? 'MPESA',
      transactionReference: map['transactionReference'] ?? '',
      timestamp: map['timestamp']?.toDate() ?? DateTime.now(),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'unmatched'),
        orElse: () => PaymentStatus.unmatched,
      ),
      type: PaymentType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'rent'),
        orElse: () => PaymentType.rent,
      ),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'landlordId': landlordId,
      'tenantId': tenantId,
      'propertyId': propertyId,
      'unitId': unitId,
      'amount': amount,
      'method': method,
      'transactionReference': transactionReference,
      'timestamp': timestamp,
      'status': status.name,
      'type': type.name,
      'notes': notes,
    };
  }

  PaymentModel copyWith({
    String? tenantId,
    String? propertyId,
    String? unitId,
    PaymentStatus? status,
    PaymentType? type,
    String? notes,
  }) {
    return PaymentModel(
      id: id,
      landlordId: landlordId,
      tenantId: tenantId ?? this.tenantId,
      propertyId: propertyId ?? this.propertyId,
      unitId: unitId ?? this.unitId,
      amount: amount,
      method: method,
      transactionReference: transactionReference,
      timestamp: timestamp,
      status: status ?? this.status,
      type: type ?? this.type,
      notes: notes ?? this.notes,
    );
  }
}
