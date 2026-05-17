import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/widgets/tenant_app_layout.dart';

class TenantMessagesScreen extends StatefulWidget {
  const TenantMessagesScreen({super.key});

  @override
  State<TenantMessagesScreen> createState() => _TenantMessagesScreenState();
}

class _TenantMessagesScreenState extends State<TenantMessagesScreen> {
  final _messageController = TextEditingController();
  String _messageType = 'general';
  bool _isSending = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    setState(() => _userData = doc.data());
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (_userData == null) return;

    setState(() => _isSending = true);

    try {
      await FirebaseFirestore.instance.collection('message_replies').add({
        'tenantId': _userData?['tenantId'] ?? '',
        'tenantName': _userData?['name'] ?? 'Tenant',
        'unitName': _userData?['unitName'] ?? '',
        'propertyName': _userData?['propertyName'] ?? '',
        'phone': _userData?['phone'] ?? '',
        'body': _messageController.text.trim(),
        'channel': 'app',
        'messageType': _messageType,
        'isResolved': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Message sent to landlord'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // ── Stream: messages FROM landlord ────────────────────────────────────────
  Stream<QuerySnapshot<Map<String, dynamic>>> _landlordMessagesStream() {
    final propertyId = _userData?['propertyId'] as String? ?? '';
    final unitId = _userData?['unitId'] as String? ?? '';

    // Messages sent to this tenant — matches if:
    // target = 'all', OR target = 'property' with matching propertyId,
    // OR target = 'unit' with matching unitId
    return FirebaseFirestore.instance
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
          final filtered = snap.docs.where((doc) {
            final data = doc.data();
            final target = data['target'] as String? ?? 'all';
            if (target == 'all') return true;
            if (target == 'property') {
              return data['targetPropertyId'] == propertyId;
            }
            if (target == 'unit') {
              return data['targetUnitId'] == unitId;
            }
            return false;
          }).toList();

          return _FilteredSnapshot(snap, filtered);
        })
    // We need raw snapshot so use a workaround below
    ;
  }

  @override
  Widget build(BuildContext context) {
    final tenantId = _userData?['tenantId'] as String? ?? '';
    final propertyId = _userData?['propertyId'] as String? ?? '';
    final unitId = _userData?['unitId'] as String? ?? '';

    return TenantAppLayout(
      currentLocation: '/tenant/messages',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Messages', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),

            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(icon: Icon(Icons.inbox), text: 'From Landlord'),
                        Tab(icon: Icon(Icons.send), text: 'My Messages'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // ── Tab 1: Messages from landlord ────────────
                          _LandlordMessagesTab(
                            propertyId: propertyId,
                            unitId: unitId,
                          ),

                          // ── Tab 2: Tenant's sent messages ────────────
                          _MyMessagesTab(
                            tenantId: tenantId,
                            messageController: _messageController,
                            messageType: _messageType,
                            isSending: _isSending,
                            onTypeChanged: (t) =>
                                setState(() => _messageType = t),
                            onSend: _sendMessage,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab 1: Messages from landlord ─────────────────────────────────────────

class _LandlordMessagesTab extends StatelessWidget {
  final String propertyId;
  final String unitId;

  const _LandlordMessagesTab({required this.propertyId, required this.unitId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // ✅ Filter client-side: all, property match, or unit match
        final allDocs = snapshot.data?.docs ?? [];
        final messages = allDocs.where((doc) {
          final data = doc.data();
          final target = data['target'] as String? ?? 'all';
          if (target == 'all') return true;
          if (target == 'property') {
            return data['targetPropertyId'] == propertyId;
          }
          if (target == 'unit') {
            return data['targetUnitId'] == unitId;
          }
          return false;
        }).toList();

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No messages from landlord yet',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Announcements and notices from\nyour landlord will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Card(
          child: ListView.separated(
            itemCount: messages.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = messages[index].data();
              final title = data['title'] as String? ?? '';
              final body = data['body'] as String? ?? '';
              final type = data['type'] as String? ?? 'announcement';
              final createdAt = data['createdAt'] as Timestamp?;

              return ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: _typeColor(type).withAlpha(30),
                  child: Icon(
                    _typeIcon(type),
                    color: _typeColor(type),
                    size: 20,
                  ),
                ),
                title: Text(
                  title.isNotEmpty ? title : body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: createdAt != null
                    ? Text(
                        _timeAgo(createdAt.toDate()),
                        style: const TextStyle(fontSize: 12),
                      )
                    : null,
                trailing: Chip(
                  label: Text(
                    _capitalize(type),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  backgroundColor: _typeColor(type),
                  padding: EdgeInsets.zero,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(body),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'emergency':
        return Colors.red;
      case 'maintenance':
        return Colors.orange;
      case 'payment_reminder':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'emergency':
        return Icons.warning;
      case 'maintenance':
        return Icons.build;
      case 'payment_reminder':
        return Icons.payment;
      default:
        return Icons.campaign;
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ── Tab 2: Tenant's sent messages ─────────────────────────────────────────

class _MyMessagesTab extends StatelessWidget {
  final String tenantId;
  final TextEditingController messageController;
  final String messageType;
  final bool isSending;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onSend;

  const _MyMessagesTab({
    required this.tenantId,
    required this.messageController,
    required this.messageType,
    required this.isSending,
    required this.onTypeChanged,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Compose ───────────────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send Message to Landlord',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('General'),
                      selected: messageType == 'general',
                      onSelected: (_) => onTypeChanged('general'),
                    ),
                    ChoiceChip(
                      avatar: const Icon(Icons.build, size: 16),
                      label: const Text('Maintenance'),
                      selected: messageType == 'maintenance',
                      onSelected: (_) => onTypeChanged('maintenance'),
                    ),
                    ChoiceChip(
                      avatar: const Icon(Icons.warning, size: 16),
                      label: const Text('Urgent'),
                      selected: messageType == 'urgent',
                      onSelected: (_) => onTypeChanged('urgent'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    hintText: 'Describe your issue or request...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isSending ? null : onSend,
                    icon: isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(isSending ? 'Sending...' : 'Send Message'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── History ───────────────────────────────────────────────────
        Text('Sent Messages', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),

        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('message_replies')
                .where('tenantId', isEqualTo: tenantId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final messages = snapshot.data?.docs ?? [];

              if (messages.isEmpty) {
                return Center(
                  child: Text(
                    'No sent messages yet',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                );
              }

              return Card(
                child: ListView.separated(
                  itemCount: messages.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final data = messages[index].data();
                    final body = data['body'] as String? ?? '';
                    final type = data['messageType'] as String? ?? 'general';
                    final isResolved = data['isResolved'] as bool? ?? false;
                    final createdAt = data['createdAt'] as Timestamp?;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _typeColor(type).withAlpha(30),
                        child: Icon(
                          _typeIcon(type),
                          color: _typeColor(type),
                          size: 18,
                        ),
                      ),
                      title: Text(
                        body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: createdAt != null
                          ? Text(
                              '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}',
                            )
                          : null,
                      trailing: Chip(
                        label: Text(
                          isResolved ? 'Resolved' : 'Open',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                        backgroundColor: isResolved
                            ? Colors.green
                            : Colors.orange,
                        padding: EdgeInsets.zero,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'maintenance':
        return Colors.orange;
      case 'urgent':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'maintenance':
        return Icons.build;
      case 'urgent':
        return Icons.warning;
      default:
        return Icons.chat_bubble;
    }
  }
}

// ── Helper class (not needed externally) ──────────────────────────────────
class _FilteredSnapshot implements QuerySnapshot<Map<String, dynamic>> {
  final QuerySnapshot<Map<String, dynamic>> _original;
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  _FilteredSnapshot(this._original, this.docs);

  @override
  List<DocumentChange<Map<String, dynamic>>> get docChanges =>
      _original.docChanges;

  @override
  SnapshotMetadata get metadata => _original.metadata;

  @override
  int get size => docs.length;
}

























// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../../../shared/widgets/tenant_app_layout.dart';

// class TenantMessagesScreen extends StatefulWidget {
//   const TenantMessagesScreen({super.key});

//   @override
//   State<TenantMessagesScreen> createState() => _TenantMessagesScreenState();
// }

// class _TenantMessagesScreenState extends State<TenantMessagesScreen> {
//   final _messageController = TextEditingController();
//   String _messageType = 'general';
//   bool _isSending = false;
//   Map<String, dynamic>? _userData;

//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//   }

//   Future<void> _loadUserData() async {
//     final uid = FirebaseAuth.instance.currentUser?.uid;
//     if (uid == null) return;
//     final doc = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(uid)
//         .get();
//     setState(() => _userData = doc.data());
//   }

//   Future<void> _sendMessage() async {
//     if (_messageController.text.trim().isEmpty) return;
//     if (_userData == null) return;

//     setState(() => _isSending = true);

//     try {
//       await FirebaseFirestore.instance.collection('message_replies').add({
//         'tenantId':     _userData?['tenantId']     ?? '',
//         'tenantName':   _userData?['name']         ?? 'Tenant',
//         'unitName':     _userData?['unitName']     ?? '',
//         'propertyName': _userData?['propertyName'] ?? '',
//         'phone':        _userData?['phone']        ?? '',
//         'body':         _messageController.text.trim(),
//         'channel':      'app',
//         'messageType':  _messageType,
//         'isResolved':   false,
//         'createdAt':    FieldValue.serverTimestamp(),
//       });

//       _messageController.clear();
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('✅ Message sent to landlord'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to send: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _isSending = false);
//     }
//   }

//   @override
//   void dispose() {
//     _messageController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final tenantId = _userData?['tenantId'] as String? ?? '';

//     return TenantAppLayout(
//       currentLocation: '/tenant/messages',
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Messages',
//                 style: Theme.of(context).textTheme.headlineMedium),
//             const SizedBox(height: 24),

//             // ── Compose message ───────────────────────────────────────
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Send Message to Landlord',
//                         style: Theme.of(context).textTheme.titleMedium),
//                     const SizedBox(height: 12),

//                     // Message type
//                     Wrap(
//                       spacing: 8,
//                       children: [
//                         ChoiceChip(
//                           label: const Text('General'),
//                           selected: _messageType == 'general',
//                           onSelected: (_) =>
//                               setState(() => _messageType = 'general'),
//                         ),
//                         ChoiceChip(
//                           avatar: const Icon(Icons.build, size: 16),
//                           label: const Text('Maintenance'),
//                           selected: _messageType == 'maintenance',
//                           onSelected: (_) =>
//                               setState(() => _messageType = 'maintenance'),
//                         ),
//                         ChoiceChip(
//                           avatar: const Icon(Icons.warning, size: 16),
//                           label: const Text('Urgent'),
//                           selected: _messageType == 'urgent',
//                           onSelected: (_) =>
//                               setState(() => _messageType = 'urgent'),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 12),

//                     TextFormField(
//                       controller: _messageController,
//                       decoration: const InputDecoration(
//                         hintText:
//                             'Describe your issue or request...',
//                         border: OutlineInputBorder(),
//                         alignLabelWithHint: true,
//                       ),
//                       maxLines: 4,
//                     ),
//                     const SizedBox(height: 12),

//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton.icon(
//                         onPressed: _isSending ? null : _sendMessage,
//                         icon: _isSending
//                             ? const SizedBox(
//                                 width: 16,
//                                 height: 16,
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 2,
//                                   color: Colors.white,
//                                 ),
//                               )
//                             : const Icon(Icons.send),
//                         label: Text(
//                             _isSending ? 'Sending...' : 'Send Message'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 24),

//             // ── Message history ───────────────────────────────────────
//             Text('Message History',
//                 style: Theme.of(context).textTheme.titleLarge),
//             const SizedBox(height: 12),

//             Expanded(
//               child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//                 stream: FirebaseFirestore.instance
//                     .collection('message_replies')
//                     .where('tenantId', isEqualTo: tenantId)
//                     .orderBy('createdAt', descending: true)
//                     .snapshots(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState ==
//                       ConnectionState.waiting) {
//                     return const Center(
//                         child: CircularProgressIndicator());
//                   }

//                   final messages = snapshot.data?.docs ?? [];

//                   if (messages.isEmpty) {
//                     return Center(
//                       child: Text('No messages yet',
//                           style: TextStyle(color: Colors.grey[500])),
//                     );
//                   }

//                   return Card(
//                     child: ListView.separated(
//                       itemCount: messages.length,
//                       separatorBuilder: (_, __) =>
//                           const Divider(height: 1),
//                       itemBuilder: (context, index) {
//                         final data       = messages[index].data();
//                         final body       = data['body']        as String? ?? '';
//                         final type       = data['messageType'] as String? ?? 'general';
//                         final isResolved = data['isResolved']  as bool?   ?? false;
//                         final createdAt  = data['createdAt']   as Timestamp?;

//                         return ListTile(
//                           leading: CircleAvatar(
//                             backgroundColor:
//                                 _typeColor(type).withAlpha(30),
//                             child: Icon(_typeIcon(type),
//                                 color: _typeColor(type), size: 18),
//                           ),
//                           title: Text(body,
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis),
//                           subtitle: createdAt != null
//                               ? Text(
//                                   '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}',
//                                 )
//                               : null,
//                           trailing: Chip(
//                             label: Text(
//                               isResolved ? 'Resolved' : 'Open',
//                               style: const TextStyle(
//                                   color: Colors.white, fontSize: 11),
//                             ),
//                             backgroundColor:
//                                 isResolved ? Colors.green : Colors.orange,
//                             padding: EdgeInsets.zero,
//                           ),
//                         );
//                       },
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Color _typeColor(String type) {
//     switch (type) {
//       case 'maintenance': return Colors.orange;
//       case 'urgent':      return Colors.red;
//       default:            return Colors.blue;
//     }
//   }

//   IconData _typeIcon(String type) {
//     switch (type) {
//       case 'maintenance': return Icons.build;
//       case 'urgent':      return Icons.warning;
//       default:            return Icons.chat_bubble;
//     }
//   }
// }