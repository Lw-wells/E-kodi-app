enum MessageType { announcement, rentReminder, utilityReminder, issueReport, general }
enum MessageDirection { outgoing, incoming } // Outgoing = Landlord -> Tenant; Incoming = Tenant -> Bot

class MessageModel {
  final String id;
  final String landlordId;
  final String? tenantId; // Null if broadcast to all
  final String? propertyId; // Target specific property users
  final String? unitId; // Target specific unit
  final String content;
  final MessageDirection direction;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead; // Important for incoming issue reports
  final bool sentSuccessfully;

  MessageModel({
    required this.id,
    required this.landlordId,
    this.tenantId,
    this.propertyId,
    this.unitId,
    required this.content,
    required this.direction,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.sentSuccessfully = true, // By default optimistic if coming from DB map
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      landlordId: map['landlordId'] ?? '',
      tenantId: map['tenantId'],
      propertyId: map['propertyId'],
      unitId: map['unitId'],
      content: map['content'] ?? '',
      direction: MessageDirection.values.firstWhere(
        (e) => e.name == (map['direction'] ?? 'outgoing'),
        orElse: () => MessageDirection.outgoing,
      ),
      type: MessageType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'general'),
        orElse: () => MessageType.general,
      ),
      timestamp: map['timestamp']?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      sentSuccessfully: map['sentSuccessfully'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'landlordId': landlordId,
      'tenantId': tenantId,
      'propertyId': propertyId,
      'unitId': unitId,
      'content': content,
      'direction': direction.name,
      'type': type.name,
      'timestamp': timestamp,
      'isRead': isRead,
      'sentSuccessfully': sentSuccessfully,
    };
  }

  MessageModel copyWith({
    bool? isRead,
    bool? sentSuccessfully,
  }) {
    return MessageModel(
      id: id,
      landlordId: landlordId,
      tenantId: tenantId,
      propertyId: propertyId,
      unitId: unitId,
      content: content,
      direction: direction,
      type: type,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      sentSuccessfully: sentSuccessfully ?? this.sentSuccessfully,
    );
  }
}
