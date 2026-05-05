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
        'tenantId':     _userData?['tenantId']     ?? '',
        'tenantName':   _userData?['name']         ?? 'Tenant',
        'unitName':     _userData?['unitName']     ?? '',
        'propertyName': _userData?['propertyName'] ?? '',
        'phone':        _userData?['phone']        ?? '',
        'body':         _messageController.text.trim(),
        'channel':      'app',
        'messageType':  _messageType,
        'isResolved':   false,
        'createdAt':    FieldValue.serverTimestamp(),
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

  @override
  Widget build(BuildContext context) {
    final tenantId = _userData?['tenantId'] as String? ?? '';

    return TenantAppLayout(
      currentLocation: '/tenant/messages',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Messages',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),

            // ── Compose message ───────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Send Message to Landlord',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),

                    // Message type
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('General'),
                          selected: _messageType == 'general',
                          onSelected: (_) =>
                              setState(() => _messageType = 'general'),
                        ),
                        ChoiceChip(
                          avatar: const Icon(Icons.build, size: 16),
                          label: const Text('Maintenance'),
                          selected: _messageType == 'maintenance',
                          onSelected: (_) =>
                              setState(() => _messageType = 'maintenance'),
                        ),
                        ChoiceChip(
                          avatar: const Icon(Icons.warning, size: 16),
                          label: const Text('Urgent'),
                          selected: _messageType == 'urgent',
                          onSelected: (_) =>
                              setState(() => _messageType = 'urgent'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText:
                            'Describe your issue or request...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSending ? null : _sendMessage,
                        icon: _isSending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(
                            _isSending ? 'Sending...' : 'Send Message'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Message history ───────────────────────────────────────
            Text('Message History',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('message_replies')
                    .where('tenantId', isEqualTo: tenantId)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data?.docs ?? [];

                  if (messages.isEmpty) {
                    return Center(
                      child: Text('No messages yet',
                          style: TextStyle(color: Colors.grey[500])),
                    );
                  }

                  return Card(
                    child: ListView.separated(
                      itemCount: messages.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final data       = messages[index].data();
                        final body       = data['body']        as String? ?? '';
                        final type       = data['messageType'] as String? ?? 'general';
                        final isResolved = data['isResolved']  as bool?   ?? false;
                        final createdAt  = data['createdAt']   as Timestamp?;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                _typeColor(type).withAlpha(30),
                            child: Icon(_typeIcon(type),
                                color: _typeColor(type), size: 18),
                          ),
                          title: Text(body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          subtitle: createdAt != null
                              ? Text(
                                  '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}',
                                )
                              : null,
                          trailing: Chip(
                            label: Text(
                              isResolved ? 'Resolved' : 'Open',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11),
                            ),
                            backgroundColor:
                                isResolved ? Colors.green : Colors.orange,
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
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'maintenance': return Colors.orange;
      case 'urgent':      return Colors.red;
      default:            return Colors.blue;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'maintenance': return Icons.build;
      case 'urgent':      return Icons.warning;
      default:            return Icons.chat_bubble;
    }
  }
}