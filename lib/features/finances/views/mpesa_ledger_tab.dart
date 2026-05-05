import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/receipt_service.dart';

class MpesaLedgerTab extends StatelessWidget {
  const MpesaLedgerTab({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> get _ledgerStream =>
      FirebaseFirestore.instance
          .collection('finances')
          .where('type', isEqualTo: 'payment')
          .orderBy('createdAt', descending: true)
          .snapshots();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Summary cards ──────────────────────────────────────────────
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _ledgerStream,
          builder: (context, snapshot) {
            final payments = snapshot.data?.docs ?? [];
            final total = payments.fold<double>(
              0,
              (sum, doc) =>
                  sum + ((doc.data()['amount'] as num?)?.toDouble() ?? 0),
            );
            final matched = payments
                .where((d) => d.data()['status'] == 'matched')
                .length;
            final unmatched = payments
                .where((d) => d.data()['status'] == 'unmatched')
                .length;

            return Row(
              children: [
                _statCard(
                  context,
                  'Total Received',
                  'KES ${_fmt(total)}',
                  Icons.account_balance_wallet,
                  Colors.green,
                ),
                const SizedBox(width: 12),
                _statCard(
                  context,
                  'Matched',
                  '$matched',
                  Icons.check_circle,
                  Colors.blue,
                ),
                const SizedBox(width: 12),
                _statCard(
                  context,
                  'Unmatched',
                  '$unmatched',
                  Icons.help_outline,
                  Colors.orange,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // ── Transactions list ──────────────────────────────────────────
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _ledgerStream,
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
                        Icons.phone_android,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No M-Pesa payments yet',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Payments will appear here automatically\nonce tenants pay via M-Pesa.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }

              return Card(
                child: ListView.separated(
                  itemCount: payments.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final data = payments[index].data();
                    final tenantName =
                        data['tenantName'] as String? ?? 'Unknown';
                    final unitName = data['unitName'] as String? ?? '';
                    final propertyName = data['propertyName'] as String? ?? '';
                    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
                    final mpesaCode = data['mpesaCode'] as String? ?? 'N/A';
                    final status = data['status'] as String? ?? 'unmatched';
                    final createdAt = data['createdAt'] as Timestamp?;
                    final timeAgo = createdAt != null
                        ? _timeAgo(createdAt.toDate())
                        : 'Recently';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.withAlpha(30),
                        child: const Icon(Icons.money, color: Colors.green),
                      ),
                      title: Text(
                        '$tenantName${unitName.isNotEmpty ? ' — $unitName' : ''}',
                      ),
                      subtitle: Text('Receipt: $mpesaCode • $timeAgo'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'KES ${amount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              // ✅ Receipt button
                              if (mpesaCode != 'N/A')
                                GestureDetector(
                                  onTap: () =>
                                      ReceiptService.generateAndShowReceipt(
                                        context: context,
                                        tenantName: tenantName,
                                        unitName: unitName,
                                        propertyName: propertyName,
                                        amount: amount,
                                        mpesaCode: mpesaCode,
                                        paymentType: 'Rent Payment',
                                        paidAt:
                                            createdAt?.toDate() ??
                                            DateTime.now(),
                                      ),
                                  child: const Text(
                                    '🧾 Receipt',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(
                              status == 'matched' ? 'Matched' : 'Unmatched',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                            backgroundColor: status == 'matched'
                                ? Colors.green
                                : Colors.orange,
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
    );
  }

  Widget _statCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}




// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:cloud_functions/cloud_functions.dart';

// class MpesaLedgerTab extends StatelessWidget {
//   const MpesaLedgerTab({super.key});

//   Stream<QuerySnapshot<Map<String, dynamic>>> get _ledgerStream =>
//       FirebaseFirestore.instance
//           .collection('finances')
//           .where('type', isEqualTo: 'payment')
//           .orderBy('createdAt', descending: true)
//           .snapshots();

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         // ── Summary cards ────────────────────────────────────────────────
//         StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//           stream: _ledgerStream,
//           builder: (context, snapshot) {
//             final payments = snapshot.data?.docs ?? [];
//             final total    = payments.fold<double>(
//               0, (sum, doc) => sum + ((doc.data()['amount'] as num?)?.toDouble() ?? 0));
//             final matched   = payments.where((d) => d.data()['status'] == 'matched').length;
//             final unmatched = payments.where((d) => d.data()['status'] == 'unmatched').length;

//             return Row(
//               children: [
//                 _statCard(context, 'Total Received',
//                     'KES ${_fmt(total)}', Icons.account_balance_wallet, Colors.green),
//                 const SizedBox(width: 12),
//                 _statCard(context, 'Matched',
//                     '$matched', Icons.check_circle, Colors.blue),
//                 const SizedBox(width: 12),
//                 _statCard(context, 'Unmatched',
//                     '$unmatched', Icons.help_outline, Colors.orange),
//               ],
//             );
//           },
//         ),
//         const SizedBox(height: 16),

//         // ── Transactions list ────────────────────────────────────────────
//         Expanded(
//           child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//             stream: _ledgerStream,
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator());
//               }

//               final payments = snapshot.data?.docs ?? [];

//               if (payments.isEmpty) {
//                 return Center(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(Icons.phone_android, size: 64, color: Colors.grey[400]),
//                       const SizedBox(height: 16),
//                       Text('No M-Pesa payments yet',
//                           style: TextStyle(color: Colors.grey[600])),
//                       const SizedBox(height: 8),
//                       const Text(
//                         'Payments will appear here automatically\nonce tenants pay via M-Pesa.',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(color: Colors.grey, fontSize: 13),
//                       ),
//                     ],
//                   ),
//                 );
//               }

//               return Card(
//                 child: ListView.separated(
//                   itemCount: payments.length,
//                   separatorBuilder: (_, __) => const Divider(height: 1),
//                   itemBuilder: (context, index) {
//                     final data       = payments[index].data();
//                     final tenantName = data['tenantName'] as String? ?? 'Unknown';
//                     final unitName   = data['unitName']   as String? ?? '';
//                     final amount     = (data['amount'] as num?)?.toDouble() ?? 0;
//                     final mpesaCode  = data['mpesaCode']  as String? ?? 'N/A';
//                     final status     = data['status']     as String? ?? 'unmatched';
//                     final createdAt  = data['createdAt']  as Timestamp?;
//                     final timeAgo    = createdAt != null
//                         ? _timeAgo(createdAt.toDate()) : 'Recently';

//                     return ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Colors.green.withAlpha(30),
//                         child: const Icon(Icons.money, color: Colors.green),
//                       ),
//                       title: Text('$tenantName${unitName.isNotEmpty ? ' — $unitName' : ''}'),
//                       subtitle: Text('Receipt: $mpesaCode • $timeAgo'),
//                       trailing: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Text(
//                             'KES ${amount.toStringAsFixed(0)}',
//                             style: const TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.green),
//                           ),
//                           const SizedBox(width: 8),
//                           Chip(
//                             label: Text(
//                               status == 'matched' ? 'Matched' : 'Unmatched',
//                               style: const TextStyle(
//                                   color: Colors.white, fontSize: 11),
//                             ),
//                             backgroundColor:
//                                 status == 'matched' ? Colors.green : Colors.orange,
//                             padding: EdgeInsets.zero,
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _statCard(BuildContext context, String title, String value,
//       IconData icon, Color color) {
//     return Expanded(
//       child: Card(
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Row(
//             children: [
//               Icon(icon, color: color, size: 28),
//               const SizedBox(width: 12),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(title,
//                       style: TextStyle(
//                           color: Colors.grey[600], fontSize: 12)),
//                   Text(value,
//                       style: const TextStyle(
//                           fontWeight: FontWeight.bold, fontSize: 18)),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   String _fmt(double amount) {
//     if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
//     if (amount >= 1000)    return '${(amount / 1000).toStringAsFixed(0)}K';
//     return amount.toStringAsFixed(0);
//   }

//   String _timeAgo(DateTime date) {
//     final diff = DateTime.now().difference(date);
//     if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
//     if (diff.inHours < 24)   return '${diff.inHours}h ago';
//     if (diff.inDays < 7)     return '${diff.inDays}d ago';
//     return '${date.day}/${date.month}/${date.year}';
//   }
// }