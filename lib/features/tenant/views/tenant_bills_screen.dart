import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../shared/widgets/tenant_app_layout.dart';

class TenantBillsScreen extends StatelessWidget {
  const TenantBillsScreen({super.key});

  Future<String?> _getTenantId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    return doc.data()?['tenantId'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    return TenantAppLayout(
      currentLocation: '/tenant/bills',
      child: FutureBuilder<String?>(
        future: _getTenantId(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final tenantId = snap.data ?? '';

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Bills',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 24),

                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('utility_bills')
                        .where('tenantId', isEqualTo: tenantId)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      final bills = snapshot.data?.docs ?? [];

                      if (bills.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.receipt_outlined,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text('No bills yet',
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
                          itemCount: bills.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final data    = bills[index].data();
                            final billId  = bills[index].id;
                            final type    = data['type']    as String? ?? 'utility';
                            final amount  = (data['amount'] as num?)?.toDouble() ?? 0;
                            final isPaid  = data['isPaid']  as bool?   ?? false;
                            final month   = data['month']   as int?    ?? 0;
                            final year    = data['year']    as int?    ?? 0;
                            final tenantName = data['tenantName'] as String? ?? '';
                            final unitName   = data['unitName']   as String? ?? '';

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isPaid
                                    ? Colors.green.withAlpha(30)
                                    : Colors.red.withAlpha(30),
                                child: Icon(
                                  _utilityIcon(type),
                                  color: isPaid ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                '${_capitalize(type)} — ${_monthName(month)} $year',
                              ),
                              subtitle: Text(unitName),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'KES ${amount.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isPaid
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (!isPaid)
                                    ElevatedButton(
                                      onPressed: () => _payBill(
                                        context,
                                        billId,
                                        amount,
                                        tenantId,
                                        tenantName,
                                        unitName,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                      ),
                                      child: const Text('Pay'),
                                    )
                                  else
                                    const Chip(
                                      label: Text('Paid',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11)),
                                      backgroundColor: Colors.green,
                                      padding: EdgeInsets.zero,
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
            ),
          );
        },
      ),
    );
  }

  Future<void> _payBill(
    BuildContext context,
    String billId,
    double amount,
    String tenantId,
    String tenantName,
    String unitName,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final phone = userDoc.data()?['phone'] as String? ?? '';

    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('stkPush');
      await callable.call({
        'phone':      phone,
        'amount':     amount,
        'tenantId':   tenantId,
        'tenantName': tenantName,
        'unitName':   unitName,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ M-Pesa prompt sent to your phone!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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