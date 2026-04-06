import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/widgets/app_layout.dart';
import '../../../config/routes.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // ── Firestore streams ──────────────────────────────────────────────────────

  Stream<QuerySnapshot<Map<String, dynamic>>> get _propertiesStream =>
      FirebaseFirestore.instance.collection('properties').snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> get _tenantsStream =>
      FirebaseFirestore.instance.collection('tenants').snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> get _recentPaymentsStream =>
      FirebaseFirestore.instance
          .collection('finances')
          .where('type', isEqualTo: 'payment')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return AppLayout(
      currentLocation: AppRoutes.dashboard,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard Overview',
              style: isMobile
                  ? Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)
                  : Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),

            // ── Summary Cards ──────────────────────────────────────────────
            // Single StreamBuilder that listens to both properties + tenants
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _propertiesStream,
              builder: (context, propertySnap) {
                

                final properties = propertySnap.data?.docs ?? [];
                final totalProperties = properties.length;

                // Monthly revenue = sum of all baseRent * occupied units
                double monthlyRevenue = 0;
                for (final p in properties) {
                  final unitCount = p.data()['unitCount'] as int? ?? 0;
                  final baseRent  = (p.data()['baseRent'] as num?)?.toDouble() ?? 0;
                  monthlyRevenue += unitCount * baseRent;
                }

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _tenantsStream,
                  builder: (context, tenantSnap) {
                    final totalTenants = tenantSnap.data?.docs.length ?? 0;

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final cards = [
                          _buildSummaryCard(
                            context,
                            'Total Properties',
                            propertySnap.connectionState == ConnectionState.waiting
                                ? '...'
                                : '$totalProperties',
                            Icons.business,
                            Colors.blue,
                          ),
                          _buildSummaryCard(
                            context,
                            'Total Tenants',
                            tenantSnap.connectionState == ConnectionState.waiting
                                ? '...'
                                : '$totalTenants',
                            Icons.people,
                            Colors.green,
                          ),
                          _buildSummaryCard(
                            context,
                            'Monthly Revenue',
                            propertySnap.connectionState == ConnectionState.waiting
                                ? '...'
                                : 'KES ${_formatAmount(monthlyRevenue)}',
                            Icons.attach_money,
                            Colors.orange,
                          ),
                          // Pending utilities — placeholder until utilities feature is built
                          _buildSummaryCard(
                            context,
                            'Pending Utilities',
                            'KES 0',
                            Icons.electrical_services,
                            Colors.red,
                          ),
                        ];

                        if (constraints.maxWidth > 1100) {
                          return Row(
                            children: [
                              Expanded(child: cards[0]),
                              const SizedBox(width: 16),
                              Expanded(child: cards[1]),
                              const SizedBox(width: 16),
                              Expanded(child: cards[2]),
                              const SizedBox(width: 16),
                              Expanded(child: cards[3]),
                            ],
                          );
                        } else if (constraints.maxWidth > 600) {
                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 2.2,
                            children: cards,
                          );
                        } else {
                          return Column(
                            children: [
                              cards[0],
                              const SizedBox(height: 12),
                              cards[1],
                              const SizedBox(height: 12),
                              cards[2],
                              const SizedBox(height: 12),
                              cards[3],
                            ],
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 32),

            // ── Main Content Area ──────────────────────────────────────────
            if (screenWidth > 900)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildRecentPayments(context)),
                  const SizedBox(width: 24),
                  Expanded(flex: 1, child: _buildQuickActions(context)),
                ],
              )
            else
              Column(
                children: [
                  _buildRecentPayments(context),
                  const SizedBox(height: 24),
                  _buildQuickActions(context),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ── Recent Payments ────────────────────────────────────────────────────────

  Widget _buildRecentPayments(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent M-Pesa Payments',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _recentPaymentsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ));
                }

                final payments = snapshot.data?.docs ?? [];

                if (payments.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'No payments yet',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final data        = payments[index].data();
                    final tenantName  = data['tenantName']  as String? ?? 'Unknown Tenant';
                    final unitName    = data['unitName']    as String? ?? 'Unknown Unit';
                    final amount      = (data['amount'] as num?)?.toDouble() ?? 0;
                    final createdAt   = data['createdAt'] as Timestamp?;
                    final timeAgo     = createdAt != null
                        ? _timeAgo(createdAt.toDate())
                        : 'Recently';

                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.money)),
                      title: Text('$tenantName - $unitName'),
                      subtitle: Text('Paid KES ${_formatAmount(amount)}'),
                      trailing: Text(timeAgo,
                          style: const TextStyle(color: Colors.grey)),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick Actions ──────────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.add_home),
              title: const Text('Add Property'),
              onTap: () => context.go(AppRoutes.addProperty),
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Add Tenant'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Select a property, then tap "Assign Tenant" on a vacant unit.'),
                    duration: Duration(seconds: 4),
                  ),
                );
                context.go(AppRoutes.properties);
              },
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Send Announcement'),
              onTap: () => context.go('/communications/compose'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Summary Card ───────────────────────────────────────────────────────────

  Widget _buildSummaryCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: color, size: 28),
              ],
            ),
            const SizedBox(height: 16),
            // ✅ Shows '...' while loading, real value once loaded
            value == '...'
                ? SizedBox(
                    height: 20,
                    width: 60,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.grey[800],
                      color: color,
                    ),
                  )
                : Text(
                    value,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatAmount(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    if (diff.inDays < 7)     return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}