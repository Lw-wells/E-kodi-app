import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/widgets/app_layout.dart';
import '../../../config/routes.dart';

class TenantsScreen extends StatelessWidget {
  const TenantsScreen({super.key});

  // ✅ Top-level collection — no special index needed
  Stream<QuerySnapshot<Map<String, dynamic>>> get _tenantsStream =>
      FirebaseFirestore.instance
          .collection('tenants')
          .orderBy('createdAt', descending: true)
          .snapshots();

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentLocation: AppRoutes.tenants,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tenants',
                    style: Theme.of(context).textTheme.headlineMedium),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Select a property, then tap "Assign Tenant" on a vacant unit.'),
                        duration: Duration(seconds: 4),
                      ),
                    );
                    context.go(AppRoutes.properties);
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Tenant'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _tenantsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final tenants = snapshot.data?.docs ?? [];

                  if (tenants.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('No tenants yet',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: Colors.grey[600])),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => context.go(AppRoutes.properties),
                            icon: const Icon(Icons.person_add),
                            label: const Text('Assign your first tenant'),
                          ),
                        ],
                      ),
                    );
                  }

                  return Card(
                    child: ListView.separated(
                      itemCount: tenants.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final data = tenants[index].data();

                        final name         = data['name']         as String? ?? 'Unknown';
                        final phone        = data['phone']        as String? ?? 'No phone';
                        final unitName     = data['unitName']     as String? ?? 'Unknown Unit';
                        final propertyName = data['propertyName'] as String? ?? 'Unknown Property';
                        final propertyId   = data['propertyId']   as String? ?? '';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withAlpha(30),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(name),
                          subtitle: Text('$propertyName • $unitName • $phone'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.bolt, color: Colors.orange),
                                tooltip: 'Utility Bills',
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Icon(Icons.chat_bubble_outline),
                                tooltip: 'WhatsApp Message',
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Icon(Icons.more_vert),
                                onPressed: () => _showTenantOptions(
                                    context,
                                    tenants[index].id,
                                    propertyId,
                                    data),
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
      ),
    );
  }

  void _showTenantOptions(
    BuildContext context,
    String tenantId,
    String propertyId,
    Map<String, dynamic> data,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                // wire to tenant detail screen when ready
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Remove Tenant',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmRemoveTenant(context, tenantId, propertyId, data);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRemoveTenant(
    BuildContext context,
    String tenantId,
    String propertyId,
    Map<String, dynamic> data,
  ) async {
    final unitId = data['unitId'] as String? ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Tenant'),
        content: Text(
            'Are you sure you want to remove ${data['name']}? The unit will be marked vacant.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && propertyId.isNotEmpty && unitId.isNotEmpty) {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      // ✅ Delete from subcollection
      batch.delete(
        firestore
            .collection('properties')
            .doc(propertyId)
            .collection('tenants')
            .doc(tenantId),
      );

      // ✅ Delete from top-level collection
      batch.delete(
        firestore.collection('tenants').doc(tenantId),
      );

      // ✅ Mark unit as vacant
      batch.update(
        firestore
            .collection('properties')
            .doc(propertyId)
            .collection('units')
            .doc(unitId),
        {'isOccupied': false, 'tenantId': null, 'tenantName': null},
      );

      await batch.commit();
    }
  }
}