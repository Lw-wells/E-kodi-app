import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class UtilityBillsTab extends StatelessWidget {
  const UtilityBillsTab({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> get _billsStream =>
      FirebaseFirestore.instance
          .collection('utility_bills')
          .orderBy('createdAt', descending: true)
          .snapshots();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Action bar ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Utility Bills',
                  style: Theme.of(context).textTheme.titleMedium),
              ElevatedButton.icon(
                onPressed: () => context.go('/finances/add-utility'),
                icon: const Icon(Icons.add),
                label: const Text('Add Utility Bill'),
              ),
            ],
          ),
        ),

        // ── Filter chips ─────────────────────────────────────────────────
        _FilterBar(),

        const SizedBox(height: 12),

        // ── Bills list ───────────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _billsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final bills = snapshot.data?.docs ?? [];

              if (bills.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.electrical_services_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No utility bills yet',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () =>
                            context.go('/finances/add-utility'),
                        icon: const Icon(Icons.add),
                        label: const Text('Add your first utility bill'),
                      ),
                    ],
                  ),
                );
              }

              return Card(
                child: ListView.separated(
                  itemCount: bills.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final data       = bills[index].data();
                    final billId     = bills[index].id;
                    final tenantName = data['tenantName'] as String? ?? 'Unknown';
                    final unitName   = data['unitName']   as String? ?? 'Unknown';
                    final type       = data['type']       as String? ?? 'utility';
                    final amount     = (data['amount'] as num?)?.toDouble() ?? 0;
                    final isPaid     = data['isPaid']     as bool? ?? false;
                    final month      = data['month']      as int? ?? 0;
                    final year       = data['year']       as int? ?? 0;
                    final billingType = data['billingType'] as String? ?? 'fixed';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            _utilityColor(type).withAlpha(30),
                        child: Icon(_utilityIcon(type),
                            color: _utilityColor(type), size: 20),
                      ),
                      title: Text('$tenantName — $unitName'),
                      subtitle: Text(
                        '${_capitalize(type)} • ${_monthName(month)} $year'
                        '${billingType == 'metered' ? ' • ${data['unitsConsumed']} units' : ''}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'KES ${amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isPaid
                                  ? Colors.green
                                  : Theme.of(context).colorScheme.error,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () =>
                                _togglePaid(context, billId, isPaid),
                            child: Chip(
                              label: Text(
                                isPaid ? 'Paid' : 'Unpaid',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                              backgroundColor:
                                  isPaid ? Colors.green : Colors.red,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
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

  Future<void> _togglePaid(
      BuildContext context, String billId, bool currentStatus) async {
    await FirebaseFirestore.instance
        .collection('utility_bills')
        .doc(billId)
        .update({'isPaid': !currentStatus});
  }

  IconData _utilityIcon(String type) {
    switch (type) {
      case 'water':       return Icons.water_drop;
      case 'electricity': return Icons.bolt;
      case 'garbage':     return Icons.delete_outline;
      case 'internet':    return Icons.wifi;
      default:            return Icons.receipt;
    }
  }

  Color _utilityColor(String type) {
    switch (type) {
      case 'water':       return Colors.blue;
      case 'electricity': return Colors.orange;
      case 'garbage':     return Colors.brown;
      case 'internet':    return Colors.purple;
      default:            return Colors.grey;
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return month >= 1 && month <= 12 ? months[month] : '';
  }
}

// ── Filter bar widget ──────────────────────────────────────────────────────

class _FilterBar extends StatefulWidget {
  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  String _selected = 'All';

  final _filters = ['All', 'Water', 'Electricity', 'Garbage', 'Internet'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selected == filter;
          return ChoiceChip(
            label: Text(filter),
            selected: isSelected,
            onSelected: (_) => setState(() => _selected = filter),
          );
        },
      ),
    );
  }
}