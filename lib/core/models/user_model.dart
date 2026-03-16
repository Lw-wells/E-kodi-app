class UserModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String role; // e.g., 'landlord', 'admin'
  final DateTime createdAt;
  final String? profileImageUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.createdAt,
    this.profileImageUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      role: map['role'] ?? 'landlord',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      profileImageUrl: map['profileImageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'createdAt': createdAt,
      'profileImageUrl': profileImageUrl,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role,
      createdAt: createdAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
