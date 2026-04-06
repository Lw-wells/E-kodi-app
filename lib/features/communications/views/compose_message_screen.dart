import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../shared/widgets/app_layout.dart';
import '../../../config/routes.dart';

class ComposeMessageScreen extends StatefulWidget {
  const ComposeMessageScreen({super.key});

  @override
  State<ComposeMessageScreen> createState() => _ComposeMessageScreenState();
}

class _ComposeMessageScreenState extends State<ComposeMessageScreen> {
  final _titleController = TextEditingController();
  final _bodyController  = TextEditingController();

  String _type    = 'announcement';
  String _channel = 'sms';
  String _target  = 'all';

  String? _selectedPropertyId;
  String? _selectedPropertyName;
  String? _selectedUnitId;
  String? _selectedUnitName;

  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message body cannot be empty')),
      );
      return;
    }

    if (_target == 'property' && _selectedPropertyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a property')),
      );
      return;
    }

    if (_target == 'unit' && _selectedUnitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a unit')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final callable = FirebaseFunctions.instance
          .httpsCallable('sendBulkMessage');

      final result = await callable.call({
        'title':            _titleController.text.trim(),
        'body':             _bodyController.text.trim(),
        'type':             _type,
        'channel':          _channel,
        'target':           _target,
        'targetPropertyId': _selectedPropertyId,
        'targetUnitId':     _selectedUnitId,
      });

      if (!mounted) return;

      final sentTo = result.data['sentTo'] as int? ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ Message sent to $sentTo tenant${sentTo == 1 ? '' : 's'}!'),
          backgroundColor: Colors.green,
        ),
      );
      context.go(AppRoutes.communications);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return AppLayout(
      currentLocation: AppRoutes.communications,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go(AppRoutes.communications),
                ),
                const SizedBox(width: 16),
                Text('Compose Message',
                    style: Theme.of(context).textTheme.headlineMedium),
              ],
            ),
            const SizedBox(height: 24),

            if (isMobile)
              Column(
                children: [
                  _buildMessageCard(),
                  const SizedBox(height: 16),
                  _buildSettingsCard(),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildMessageCard()),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: _buildSettingsCard()),
                ],
              ),

            const SizedBox(height: 24),
            _buildSubmitRow(),
          ],
        ),
      ),
    );
  }

  // ── Message card ───────────────────────────────────────────────────────────

  Widget _buildMessageCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Message Content',
                style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 32),

            // Message type chips
            Text('Message Type',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _typeChip('announcement', 'Announcement', Icons.campaign),
                _typeChip('maintenance',  'Maintenance',  Icons.build),
                _typeChip('emergency',    'Emergency',    Icons.warning),
                _typeChip('payment_reminder', 'Payment Reminder', Icons.payment),
              ],
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title (optional)',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Message Body *',
                hintText: 'Type your message here...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 6,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),

            // Character count
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_bodyController.text.length} characters'
                '${_bodyController.text.length > 160 ? ' (${(_bodyController.text.length / 160).ceil()} SMS pages)' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: _bodyController.text.length > 160
                      ? Colors.orange
                      : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Settings card ──────────────────────────────────────────────────────────

  Widget _buildSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delivery Settings',
                style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 32),

            // Channel
            Text('Channel', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _channelCard('sms',       'SMS',       Icons.sms)),
                const SizedBox(width: 12),
                Expanded(child: _channelCard('whatsapp',  'WhatsApp',  Icons.chat)),
                const SizedBox(width: 12),
                Expanded(child: _channelCard('both',      'Both',      Icons.send)),
              ],
            ),
            const SizedBox(height: 24),

            // Target
            Text('Recipients', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            _targetOption('all',      'All Tenants',    Icons.people),
            _targetOption('property', 'By Property',    Icons.business),
            _targetOption('unit',     'Specific Unit',  Icons.meeting_room),
            const SizedBox(height: 16),

            // Property selector
            if (_target == 'property' || _target == 'unit')
              _buildPropertySelector(),

            // Unit selector
            if (_target == 'unit' && _selectedPropertyId != null)
              _buildUnitSelector(),

            const SizedBox(height: 16),

            // Preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Preview:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Sending via ${_channel.toUpperCase()} to '
                    '${_target == 'all' ? 'all tenants' : _target == 'property' ? (_selectedPropertyName ?? 'selected property') : (_selectedUnitName ?? 'selected unit')}',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertySelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('properties')
            .snapshots(),
        builder: (context, snapshot) {
          final properties = snapshot.data?.docs ?? [];
          return DropdownButtonFormField<String>(
            value: _selectedPropertyId,
            decoration: const InputDecoration(
              labelText: 'Select Property',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.business),
            ),
            items: properties.map((doc) {
              return DropdownMenuItem(
                value: doc.id,
                child: Text(doc.data()['name'] as String? ?? 'Unknown'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedPropertyId   = value;
                _selectedPropertyName = properties
                    .firstWhere((d) => d.id == value)
                    .data()['name'] as String?;
                _selectedUnitId   = null;
                _selectedUnitName = null;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildUnitSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('properties')
            .doc(_selectedPropertyId)
            .collection('units')
            .where('isOccupied', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          final units = snapshot.data?.docs ?? [];
          return DropdownButtonFormField<String>(
            value: _selectedUnitId,
            decoration: const InputDecoration(
              labelText: 'Select Unit',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.meeting_room),
            ),
            items: units.map((doc) {
              final data = doc.data();
              return DropdownMenuItem(
                value: doc.id,
                child: Text(
                  '${data['unitName']} — ${data['tenantName'] ?? 'Tenant'}',
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              final unit = units.firstWhere((d) => d.id == value);
              setState(() {
                _selectedUnitId   = value;
                _selectedUnitName = unit.data()['unitName'] as String?;
              });
            },
          );
        },
      ),
    );
  }

  // ── Submit row ─────────────────────────────────────────────────────────────

  Widget _buildSubmitRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isSending
              ? null
              : () => context.go(AppRoutes.communications),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: _isSending ? null : _sendMessage,
          icon: _isSending
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.send),
          label: Text(_isSending ? 'Sending...' : 'Send Message'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            backgroundColor: _type == 'emergency' ? Colors.red : null,
          ),
        ),
      ],
    );
  }

  // ── Helper widgets ─────────────────────────────────────────────────────────

  Widget _typeChip(String value, String label, IconData icon) {
    final isSelected = _type == value;
    return ChoiceChip(
      avatar: Icon(icon,
          size: 16, color: isSelected ? Colors.white : Colors.grey),
      label: Text(label),
      selected: isSelected,
      selectedColor: value == 'emergency'
          ? Colors.red
          : Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
          color: isSelected ? Colors.white : null),
      onSelected: (_) => setState(() => _type = value),
    );
  }

  Widget _channelCard(String value, String label, IconData icon) {
    final isSelected = _channel == value;
    return GestureDetector(
      onTap: () => setState(() => _channel = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[700]!,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withAlpha(25)
              : null,
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
                size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : null)),
          ],
        ),
      ),
    );
  }

  Widget _targetOption(String value, String label, IconData icon) {
    return RadioListTile<String>(
      value: value,
      groupValue: _target,
      title: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
      contentPadding: EdgeInsets.zero,
      onChanged: (v) => setState(() {
        _target = v!;
        _selectedPropertyId   = null;
        _selectedPropertyName = null;
        _selectedUnitId       = null;
        _selectedUnitName     = null;
      }),
    );
  }
}