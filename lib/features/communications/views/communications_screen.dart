import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_layout.dart';
import '../../../config/routes.dart';

class CommunicationsScreen extends StatelessWidget {
  const CommunicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentLocation: AppRoutes.communications,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Communications',
                    style: Theme.of(context).textTheme.headlineMedium),
                ElevatedButton.icon(
                  onPressed: () => context.go('/communications/compose'),
                  icon: const Icon(Icons.send),
                  label: const Text('New Message'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Inbox'),
                        Tab(text: 'Sent History'),
                        Tab(text: 'Announcements'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        children: [
                          const _InboxTab(),
                          const _SentHistoryTab(),
                          const _AnnouncementsTab(),
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

// ── Inbox Tab (with nested tabs) ───────────────────────────────────────────

class _InboxTab extends StatelessWidget {
  const _InboxTab();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // ── Unread badge counts ──────────────────────────────────────
          _InboxTabBar(),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              children: [
                _MessageList(
                  stream: FirebaseFirestore.instance
                      .collection('message_replies')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  emptyMessage: 'No replies yet',
                  emptySubtitle: 'Tenant replies to your messages\nwill appear here.',
                  emptyIcon: Icons.reply_outlined,
                ),
                _MessageList(
                  stream: FirebaseFirestore.instance
                      .collection('message_replies')
                      .where('messageType', isEqualTo: 'maintenance')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  emptyMessage: 'No maintenance requests',
                  emptySubtitle: 'Tenant maintenance requests\nwill appear here.',
                  emptyIcon: Icons.build_outlined,
                ),
                _MessageList(
                  stream: FirebaseFirestore.instance
                      .collection('message_replies')
                      .where('messageType', isEqualTo: 'general')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  emptyMessage: 'No general messages',
                  emptySubtitle: 'General tenant messages\nwill appear here.',
                  emptyIcon: Icons.chat_bubble_outline,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Inbox nested tab bar with live unread counts ───────────────────────────

class _InboxTabBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('message_replies')
          .where('isResolved', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final all         = snapshot.data?.docs ?? [];
        final allCount    = all.length;
        final maintCount  = all.where((d) =>
            d.data()['messageType'] == 'maintenance').length;
        final genCount    = all.where((d) =>
            d.data()['messageType'] == 'general').length;

        return TabBar(
          labelStyle: const TextStyle(fontSize: 12),
          tabs: [
            Tab(child: _tabLabel('Replies', allCount)),
            Tab(child: _tabLabel('Maintenance', maintCount)),
            Tab(child: _tabLabel('General', genCount)),
          ],
        );
      },
    );
  }

  Widget _tabLabel(String label, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (count > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Reusable message list ──────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final String emptyMessage;
  final String emptySubtitle;
  final IconData emptyIcon;

  const _MessageList({
    required this.stream,
    required this.emptyMessage,
    required this.emptySubtitle,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data?.docs ?? [];

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(emptyIcon, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(emptyMessage,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.grey[600])),
                const SizedBox(height: 8),
                Text(emptySubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return Card(
          child: ListView.separated(
            itemCount: messages.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data        = messages[index].data();
              final replyId     = messages[index].id;
              final tenantName  = data['tenantName']  as String? ?? 'Unknown';
              final unitName    = data['unitName']    as String? ?? '';
              final body        = data['body']        as String? ?? '';
              final isResolved  = data['isResolved']  as bool?   ?? false;
              final channel     = data['channel']     as String? ?? 'sms';
              final messageType = data['messageType'] as String? ?? 'reply';
              final createdAt   = data['createdAt']   as Timestamp?;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isResolved
                      ? Colors.green.withAlpha(30)
                      : _typeColor(messageType).withAlpha(30),
                  child: Text(
                    tenantName.isNotEmpty
                        ? tenantName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: isResolved
                          ? Colors.green
                          : _typeColor(messageType),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Flexible(child: Text(tenantName)),
                    const SizedBox(width: 8),
                    if (unitName.isNotEmpty)
                      Chip(
                        label: Text(unitName,
                            style: const TextStyle(fontSize: 10)),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    const SizedBox(width: 4),
                    Icon(
                      channel == 'whatsapp'
                          ? Icons.chat
                          : Icons.sms,
                      size: 14,
                      color: Colors.grey,
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    if (createdAt != null)
                      Text(
                        _timeAgo(createdAt.toDate()),
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey),
                      ),
                  ],
                ),
                isThreeLine: true,
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => _toggleResolved(replyId, isResolved),
                      child: Chip(
                        label: Text(
                          isResolved ? 'Resolved' : 'Open',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11),
                        ),
                        backgroundColor:
                            isResolved ? Colors.green : Colors.orange,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                onTap: () => _showMessageDetail(context, data, replyId),
              );
            },
          ),
        );
      },
    );
  }

  void _showMessageDetail(
    BuildContext context,
    Map<String, dynamic> data,
    String replyId,
  ) {
    final tenantName  = data['tenantName']  as String? ?? 'Unknown';
    final unitName    = data['unitName']    as String? ?? '';
    final body        = data['body']        as String? ?? '';
    final isResolved  = data['isResolved']  as bool?   ?? false;
    final messageType = data['messageType'] as String? ?? 'reply';
    final createdAt   = data['createdAt']   as Timestamp?;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(_typeIcon(messageType),
                color: _typeColor(messageType), size: 20),
            const SizedBox(width: 8),
            Flexible(child: Text('$tenantName — $unitName')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (createdAt != null)
              Text(
                '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year} '
                '${createdAt.toDate().hour}:${createdAt.toDate().minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            const SizedBox(height: 12),
            Text(body),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('message_replies')
                  .doc(replyId)
                  .update({'isResolved': !isResolved});
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isResolved ? Colors.orange : Colors.green,
            ),
            child: Text(isResolved ? 'Reopen' : 'Mark Resolved'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleResolved(String replyId, bool current) async {
    await FirebaseFirestore.instance
        .collection('message_replies')
        .doc(replyId)
        .update({'isResolved': !current});
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'maintenance': return Colors.orange;
      case 'general':     return Colors.blue;
      default:            return Colors.purple;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'maintenance': return Icons.build;
      case 'general':     return Icons.chat_bubble;
      default:            return Icons.reply;
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Sent History Tab ───────────────────────────────────────────────────────

class _SentHistoryTab extends StatelessWidget {
  const _SentHistoryTab();

  Stream<QuerySnapshot<Map<String, dynamic>>> get _messagesStream =>
      FirebaseFirestore.instance
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .snapshots();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _messagesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data?.docs ?? [];

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('No messages sent yet',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.grey[600])),
              ],
            ),
          );
        }

        return Card(
          child: ListView.separated(
            itemCount: messages.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data      = messages[index].data();
              final title     = data['title']   as String? ?? '';
              final body      = data['body']    as String? ?? '';
              final type      = data['type']    as String? ?? 'announcement';
              final channel   = data['channel'] as String? ?? 'sms';
              final sentTo    = data['sentTo']  as int?    ?? 0;
              final target    = data['target']  as String? ?? 'all';
              final createdAt = data['createdAt'] as Timestamp?;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _typeColor(type).withAlpha(30),
                  child: Icon(_typeIcon(type),
                      color: _typeColor(type), size: 20),
                ),
                title: Text(title.isNotEmpty ? title : body),
                subtitle: Text(
                  'Sent to $sentTo tenant${sentTo == 1 ? '' : 's'} • '
                  '${_capitalize(target)} • '
                  '${channel.toUpperCase()}',
                ),
                trailing: createdAt != null
                    ? Text(
                        '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey),
                      )
                    : null,
              );
            },
          ),
        );
      },
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'emergency':        return Icons.warning;
      case 'maintenance':      return Icons.build;
      case 'payment_reminder': return Icons.payment;
      default:                 return Icons.campaign;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'emergency':        return Colors.red;
      case 'maintenance':      return Colors.orange;
      case 'payment_reminder': return Colors.blue;
      default:                 return Colors.green;
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Announcements Tab ──────────────────────────────────────────────────────

class _AnnouncementsTab extends StatelessWidget {
  const _AnnouncementsTab();

  Stream<QuerySnapshot<Map<String, dynamic>>> get _announcementsStream =>
      FirebaseFirestore.instance
          .collection('messages')
          .where('type', isEqualTo: 'announcement')
          .orderBy('createdAt', descending: true)
          .snapshots();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _announcementsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final announcements = snapshot.data?.docs ?? [];

        if (announcements.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.campaign_outlined,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('No announcements yet',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.grey[600])),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => context.go('/communications/compose'),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Announcement'),
                ),
              ],
            ),
          );
        }

        return Card(
          child: ListView.separated(
            itemCount: announcements.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data      = announcements[index].data();
              final title     = data['title']   as String? ?? '';
              final body      = data['body']    as String? ?? '';
              final sentTo    = data['sentTo']  as int?    ?? 0;
              final createdAt = data['createdAt'] as Timestamp?;

              return ExpansionTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.campaign,
                      color: Colors.white, size: 20),
                ),
                title: Text(title.isNotEmpty ? title : body),
                subtitle: Text(
                  'Sent to $sentTo tenant${sentTo == 1 ? '' : 's'}'
                  '${createdAt != null ? ' • ${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}' : ''}',
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
}