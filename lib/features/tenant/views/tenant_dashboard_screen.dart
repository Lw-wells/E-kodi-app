import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../shared/widgets/tenant_app_layout.dart';

class TenantDashboardScreen extends StatelessWidget {
  const TenantDashboardScreen({super.key});

  // ── Get current tenant's data from users collection ────────────────────────
  Future<Map<String, dynamic>?> _getTenantData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (!userDoc.exists) return null;
    return userDoc.data();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return TenantAppLayout(
      currentLocation: '/tenant/dashboard',
      child: FutureBuilder<Map<String, dynamic>?>(
        future: _getTenantData(),
        builder: (context, userSnap) {
          if (userSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = userSnap.data;
          final tenantId = userData?['tenantId'] as String? ?? '';
          final unitName = userData?['unitName'] as String? ?? 'Your Unit';
          final propertyName =
              userData?['propertyName'] as String? ?? 'Your Property';
          final tenantName = userData?['name'] as String? ?? 'Tenant';
          final phone = userData?['phone'] as String? ?? '';

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Welcome header ──────────────────────────────────────
                Text(
                  'Welcome, $tenantName 👋',
                  style: isMobile
                      ? Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        )
                      : Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  '$unitName • $propertyName',
                  style: TextStyle(color: Colors.grey[500]),
                ),
                const SizedBox(height: 24),

                // ── Summary cards ───────────────────────────────────────
                _TenantSummaryCards(tenantId: tenantId),
                const SizedBox(height: 32),

                // ── Pay rent card ───────────────────────────────────────
                _PayRentCard(
                  tenantId: tenantId,
                  tenantName: tenantName,
                  unitName: unitName,
                  phone: phone,
                ),
                const SizedBox(height: 24),

                // ── Recent transactions ─────────────────────────────────
                _RecentTransactions(tenantId: tenantId),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Summary cards ──────────────────────────────────────────────────────────

class _TenantSummaryCards extends StatelessWidget {
  final String tenantId;
  const _TenantSummaryCards({required this.tenantId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('utility_bills')
          .where('tenantId', isEqualTo: tenantId)
          .where('isPaid', isEqualTo: false)
          .snapshots(),
      builder: (context, billsSnap) {
        final unpaidBills = billsSnap.data?.docs ?? [];
        final totalUnpaid = unpaidBills.fold<double>(
          0,
          (sum, doc) => sum + ((doc.data()['amount'] as num?)?.toDouble() ?? 0),
        );

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('finances')
              .where('tenantId', isEqualTo: tenantId)
              .where('type', isEqualTo: 'payment')
              .snapshots(),
          builder: (context, paymentsSnap) {
            final totalPaid = (paymentsSnap.data?.docs ?? []).fold<double>(
              0,
              (sum, doc) =>
                  sum + ((doc.data()['amount'] as num?)?.toDouble() ?? 0),
            );

            final isMobile = MediaQuery.of(context).size.width < 768;
            final cards = [
              _statCard(
                context,
                'Unpaid Bills',
                'KES ${totalUnpaid.toStringAsFixed(0)}',
                Icons.receipt_outlined,
                Colors.red,
              ),
              _statCard(
                context,
                'Total Paid',
                'KES ${totalPaid.toStringAsFixed(0)}',
                Icons.check_circle_outline,
                Colors.green,
              ),
              _statCard(
                context,
                'Pending Bills',
                '${unpaidBills.length}',
                Icons.pending_outlined,
                Colors.orange,
              ),
            ];

            if (isMobile) {
              return Column(
                children: [
                  cards[0],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: cards[1]),
                      const SizedBox(width: 12),
                      Expanded(child: cards[2]),
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 16),
                Expanded(child: cards[1]),
                const SizedBox(width: 16),
                Expanded(child: cards[2]),
              ],
            );
          },
        );
      },
    );
  }

  Widget _statCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pay rent card ──────────────────────────────────────────────────────────

class _PayRentCard extends StatefulWidget {
  final String tenantId;
  final String tenantName;
  final String unitName;
  final String phone;

  const _PayRentCard({
    required this.tenantId,
    required this.tenantName,
    required this.unitName,
    required this.phone,
  });

  @override
  State<_PayRentCard> createState() => _PayRentCardState();
}

class _PayRentCardState extends State<_PayRentCard> {
  bool _isSending = false;

  Future<void> _triggerStkPush(double amount) async {
    setState(() => _isSending = true);

    // ✅ Fetch phone fresh from Firestore in case widget.phone is empty
    String phone = widget.phone;
    if (phone.isEmpty) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        phone = doc.data()?['phone'] as String? ?? '';
      }
    }

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number found. Please contact your landlord.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isSending = false);
      return;
    }

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('stkPush');
      await callable.call({
        'phone': phone,
        'amount': amount,
        'tenantId': widget.tenantId,
        'tenantName': widget.tenantName,
        'unitName': widget.unitName,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ M-Pesa prompt sent to your phone!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('tenants')
          .doc(widget.tenantId)
          .collection('units')
          .limit(1)
          .snapshots(),
      builder: (context, _) {
        // Get rent from users collection instead
        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .get(),
          builder: (context, userSnap) {
            final unitId = userSnap.data?.data()?['unitId'] as String? ?? '';
            final propertyId =
                userSnap.data?.data()?['propertyId'] as String? ?? '';

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('properties')
                  .doc(propertyId)
                  .collection('units')
                  .doc(unitId)
                  .snapshots(),
              builder: (context, unitSnap) {
                final rent =
                    (unitSnap.data?.data()?['rent'] as num?)?.toDouble() ?? 0;

                return Card(
                  color: Theme.of(context).colorScheme.primary.withAlpha(20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha(80),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.home,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Monthly Rent',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'KES ${rent.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.unitName}',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isSending || rent == 0
                                ? null
                                : () => _triggerStkPush(rent),
                            icon: _isSending
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.phone_android),
                            label: Text(
                              _isSending
                                  ? 'Sending M-Pesa prompt...'
                                  : 'Pay Rent via M-Pesa',
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ── Recent transactions ────────────────────────────────────────────────────

class _RecentTransactions extends StatelessWidget {
  final String tenantId;
  const _RecentTransactions({required this.tenantId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Transactions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('finances')
              .where('tenantId', isEqualTo: tenantId)
              .orderBy('createdAt', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final transactions = snapshot.data?.docs ?? [];

            if (transactions.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No transactions yet',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                ),
              );
            }

            return Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final data = transactions[index].data();
                  final type = data['type'] as String? ?? 'payment';
                  final amount = (data['amount'] as num?)?.toDouble() ?? 0;
                  final createdAt = data['createdAt'] as Timestamp?;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: type == 'payment'
                          ? Colors.green.withAlpha(30)
                          : Colors.blue.withAlpha(30),
                      child: Icon(
                        type == 'payment' ? Icons.arrow_upward : Icons.receipt,
                        color: type == 'payment' ? Colors.green : Colors.blue,
                        size: 18,
                      ),
                    ),
                    title: Text(type == 'payment' ? 'Rent Payment' : 'Deposit'),
                    subtitle: createdAt != null
                        ? Text(
                            '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}',
                          )
                        : null,
                    trailing: Text(
                      'KES ${amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: type == 'payment' ? Colors.green : Colors.blue,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
