import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/widgets/tenant_app_layout.dart';
import '../../../core/services/receipt_service.dart';

class TenantPaymentsScreen extends StatelessWidget {
  const TenantPaymentsScreen({super.key});

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
      currentLocation: '/tenant/payments',
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
                Text(
                  'Payment History',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),

                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('finances')
                        .where('tenantId', isEqualTo: tenantId)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final payments = snapshot.data?.docs ?? [];

                      if (payments.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.payment_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No payments yet',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        );
                      }

                      // Total paid
                      final totalPaid = payments.fold<double>(
                        0,
                        (sum, doc) =>
                            sum +
                            ((doc.data()['amount'] as num?)?.toDouble() ?? 0),
                      );

                      return Column(
                        children: [
                          // Total card
                          Card(
                            color: Colors.green.withAlpha(20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.green.withAlpha(80),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.account_balance_wallet,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Total Paid',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      Text(
                                        'KES ${totalPaid.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Expanded(
                            child: Card(
                              child: ListView.separated(
                                itemCount: payments.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final data = payments[index].data();
                                  final type =
                                      data['type'] as String? ?? 'payment';
                                  final amount =
                                      (data['amount'] as num?)?.toDouble() ?? 0;
                                  final mpesaCode =
                                      data['mpesaCode'] as String? ?? 'N/A';
                                  final createdAt =
                                      data['createdAt'] as Timestamp?;

                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.green.withAlpha(
                                        30,
                                      ),
                                      child: const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      type == 'payment'
                                          ? 'Rent Payment'
                                          : 'Deposit',
                                    ),
                                    subtitle: Text('Receipt: $mpesaCode'),
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'KES ${amount.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                        if (createdAt != null)
                                          Text(
                                            '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        // ✅ Receipt button
                                        if (mpesaCode != 'N/A')
                                          GestureDetector(
                                            onTap: () =>
                                                ReceiptService.generateAndShowReceipt(
                                                  context: context,
                                                  tenantName:
                                                      data['tenantName']
                                                          as String? ??
                                                      '',
                                                  unitName:
                                                      data['unitName']
                                                          as String? ??
                                                      '',
                                                  propertyName:
                                                      data['propertyName']
                                                          as String? ??
                                                      '',
                                                  amount: amount,
                                                  mpesaCode: mpesaCode,
                                                  paymentType: type == 'payment'
                                                      ? 'Rent Payment'
                                                      : 'Deposit',
                                                  paidAt: createdAt!.toDate(),
                                                ),
                                            child: const Text(
                                              '🧾 Receipt',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.blue,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    // trailing: Column(
                                    //   mainAxisAlignment:
                                    //       MainAxisAlignment.center,
                                    //   crossAxisAlignment:
                                    //       CrossAxisAlignment.end,
                                    //   children: [
                                    //     Text(
                                    //       'KES ${amount.toStringAsFixed(0)}',
                                    //       style: const TextStyle(
                                    //         fontWeight: FontWeight.bold,
                                    //         color: Colors.green,
                                    //       ),
                                    //     ),
                                    //     if (createdAt != null)
                                    //       Text(
                                    //         '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}',
                                    //         style: const TextStyle(
                                    //             fontSize: 11,
                                    //             color: Colors.grey),
                                    //       ),
                                    //   ],
                                    // ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
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
}
