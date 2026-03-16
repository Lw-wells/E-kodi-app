class PropertyModel {
  final String id;
  final String landlordId;
  final String name; // e.g., "Sunrise Apartments"
  final String address;
  final String location;
  final int totalUnits;
  final DateTime createdAt;

  PropertyModel({
    required this.id,
    required this.landlordId,
    required this.name,
    required this.address,
    required this.location,
    required this.totalUnits,
    required this.createdAt,
  });

  factory PropertyModel.fromMap(Map<String, dynamic> map, String id) {
    return PropertyModel(
      id: id,
      landlordId: map['landlordId'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      location: map['location'] ?? '',
      totalUnits: map['totalUnits'] ?? 0,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'landlordId': landlordId,
      'name': name,
      'address': address,
      'location': location,
      'totalUnits': totalUnits,
      'createdAt': createdAt,
    };
  }

  PropertyModel copyWith({
    String? name,
    String? address,
    String? location,
    int? totalUnits,
  }) {
    return PropertyModel(
      id: id,
      landlordId: landlordId,
      name: name ?? this.name,
      address: address ?? this.address,
      location: location ?? this.location,
      totalUnits: totalUnits ?? this.totalUnits,
      createdAt: createdAt,
    );
  }
}
