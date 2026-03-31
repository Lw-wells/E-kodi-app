import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../shared/widgets/app_layout.dart';
import '../../../config/routes.dart';

class PropertyDetailScreen extends StatelessWidget {
  final String propertyId;

  const PropertyDetailScreen({super.key, required this.propertyId});

  // ── Firestore helpers ──────────────────────────────────────────────────────

  Stream<DocumentSnapshot<Map<String, dynamic>>> get _propertyStream =>
      FirebaseFirestore.instance
          .collection('properties')
          .doc(propertyId)
          .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> get _unitsStream =>
      FirebaseFirestore.instance
          .collection('properties')
          .doc(propertyId)
          .collection('units')
          .orderBy('unitName')
          .snapshots();

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentLocation: AppRoutes.properties,
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _propertyStream,
        builder: (context, propertySnap) {
          if (propertySnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!propertySnap.hasData || !propertySnap.data!.exists) {
            return const Center(child: Text('Property not found.'));
          }

          final property     = propertySnap.data!.data()!;
          final propertyName = property['name'] as String? ?? 'Unnamed Property';
          final screenWidth  = MediaQuery.of(context).size.width;
          final isMobile     = screenWidth < 768;

          return Padding(
            padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ───────────────────────────────────────────────────
                if (isMobile)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => context.go(AppRoutes.properties),
                          ),
                          Expanded(
                            child: Text(propertyName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _showEditBlockDialog(context, property),
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Edit Block'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showUnitDialog(context, null),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Unit'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.go(AppRoutes.properties),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(propertyName,
                            style:
                                Theme.of(context).textTheme.headlineMedium),
                      ),
                      OutlinedButton.icon(
                        onPressed: () =>
                            _showEditBlockDialog(context, property),
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Block'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showUnitDialog(context, null),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Unit'),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),

                // ── Stats ─────────────────────────────────────────────────
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _unitsStream,
                  builder: (context, unitsSnap) {
                    final units    = unitsSnap.data?.docs ?? [];
                    final total    = units.length;
                    final occupied = units
                        .where((u) => u['isOccupied'] == true)
                        .length;
                    final vacant       = total - occupied;
                    final baseRent     = (property['baseRent'] as num?)?.toDouble() ?? 0;
                    final monthlyRevenue = occupied * baseRent;

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final cards = [
                          _buildStatCard(context, 'Total Units', '$total', Icons.home_work, Colors.blue),
                          _buildStatCard(context, 'Occupied', '$occupied', Icons.person, Colors.green),
                          _buildStatCard(context, 'Vacant', '$vacant', Icons.door_front_door, Colors.orange),
                          _buildStatCard(context, 'Monthly Revenue', 'KES ${monthlyRevenue.toStringAsFixed(0)}', Icons.attach_money, Colors.purple),
                        ];

                        if (constraints.maxWidth > 900) {
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
                        } else if (constraints.maxWidth > 550) {
                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            childAspectRatio: 2.5,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
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
                ),
                const SizedBox(height: 32),

                Text('Units Management',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),

                // ── Units List ────────────────────────────────────────────
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _unitsStream,
                    builder: (context, unitsSnap) {
                      if (unitsSnap.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      final units = unitsSnap.data?.docs ?? [];
                      if (units.isEmpty) {
                        return const Center(
                            child: Text('No units yet. Add one above.'));
                      }

                      return Card(
                        child: ListView.separated(
                          itemCount: units.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final unit       = units[index];
                            final data       = unit.data();
                            final unitName   = data['unitName']   as String? ?? 'Unit';
                            final isOccupied = data['isOccupied'] as bool?   ?? false;
                            final tenantName = data['tenantName'] as String?;
                            final rent = (data['rent'] as num?)?.toDouble() ?? 0;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isOccupied
                                    ? Colors.green.withAlpha(50)
                                    : Colors.orange.withAlpha(50),
                                child: Icon(
                                  Icons.meeting_room,
                                  color: isOccupied
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                              title: Text(unitName),
                              subtitle: Text(isOccupied
                                  ? 'Occupied • ${tenantName ?? "Tenant"}'
                                  : 'Vacant'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'KES ${rent.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  PopupMenuButton<String>(
                                    onSelected: (value) =>
                                        _handleUnitAction(context, value,
                                            unit, unitName, isOccupied),
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Edit Unit Details'),
                                      ),
                                      if (isOccupied) ...[
                                        const PopupMenuItem(
                                          value: 'tenant',
                                          child: Text('View Tenant Info'),
                                        ),
                                        // ✅ STK Push — only for occupied units
                                        const PopupMenuItem(
                                          value: 'stk',
                                          child: Row(
                                            children: [
                                              Icon(Icons.phone_android,
                                                  size: 18,
                                                  color: Colors.green),
                                              SizedBox(width: 8),
                                              Text('Request M-Pesa Payment'),
                                            ],
                                          ),
                                        ),
                                      ] else
                                        const PopupMenuItem(
                                          value: 'assign',
                                          child: Text('Assign Tenant'),
                                        ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete Unit',
                                            style: TextStyle(
                                                color: Colors.red)),
                                      ),
                                    ],
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

  // ── Actions ────────────────────────────────────────────────────────────────

  void _handleUnitAction(
    BuildContext context,
    String action,
    QueryDocumentSnapshot<Map<String, dynamic>> unit,
    String unitName,
    bool isOccupied,
  ) {
    switch (action) {
      case 'edit':
        _showUnitDialog(context, unit);
        break;
      case 'assign':
        context.go(
          '/properties/$propertyId/units/${unit.id}/assign?unitName=$unitName',
        );
        break;
      case 'delete':
        _confirmDeleteUnit(context, unit.id, unitName);
        break;
      case 'tenant':
        // Wire to tenant detail screen when ready
        break;
      case 'stk':
        // ✅ Trigger STK Push dialog
        _showStkPushDialog(context, unit, unitName);
        break;
    }
  }

  // ── STK Push dialog ────────────────────────────────────────────────────────

  void _showStkPushDialog(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> unit,
    String unitName,
  ) {
    final data       = unit.data();
    final tenantName = data['tenantName'] as String? ?? 'Tenant';
    final tenantId   = data['tenantId']   as String? ?? '';
    final rent       = (data['rent'] as num?)?.toDouble() ?? 0;

    // Sandbox test number — replace with tenant's real phone in production
    const testPhone  = '254708374149';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Request Payment — $unitName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tenant: $tenantName'),
            Text('Amount: KES ${rent.toStringAsFixed(0)}'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '🧪 Sandbox mode: STK Push will go to Safaricom test number 254708374149. No real money moves.',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.phone_android),
            label: const Text('Send STK Push'),
            onPressed: () async {
              Navigator.pop(ctx);

              // Show loading snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      ),
                      SizedBox(width: 12),
                      Text('Sending STK Push...'),
                    ],
                  ),
                  duration: Duration(seconds: 3),
                ),
              );

              try {
                final callable = FirebaseFunctions.instance
                    .httpsCallable('stkPush');
                final result = await callable.call({
                  'phone':      testPhone,
                  'amount':     rent,
                  'tenantId':   tenantId,
                  'tenantName': tenantName,
                  'unitName':   unitName,
                });

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '✅ STK Push sent! Checkout ID: ${result.data['checkoutRequestId']}',
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('STK Push failed: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // ── Delete unit ────────────────────────────────────────────────────────────

  Future<void> _confirmDeleteUnit(
      BuildContext context, String unitId, String unitName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Unit'),
        content: Text(
            'Are you sure you want to delete $unitName? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('properties')
          .doc(propertyId)
          .collection('units')
          .doc(unitId)
          .delete();
    }
  }

  // ── Edit block dialog ──────────────────────────────────────────────────────

  void _showEditBlockDialog(
      BuildContext context, Map<String, dynamic> property) {
    final nameCtrl     = TextEditingController(text: property['name']     ?? '');
    final locationCtrl = TextEditingController(text: property['location'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Block Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Block Name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: locationCtrl,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('properties')
                  .doc(propertyId)
                  .update({
                'name':     nameCtrl.text.trim(),
                'location': locationCtrl.text.trim(),
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  // ── Add/Edit unit dialog ───────────────────────────────────────────────────

  void _showUnitDialog(
      BuildContext context,
      QueryDocumentSnapshot<Map<String, dynamic>>? unit) {
    final isEditing = unit != null;
    final nameCtrl  = TextEditingController(
        text: unit?.data()['unitName'] ?? '');
    final rentCtrl  = TextEditingController(
        text: (unit?.data()['rent'] as num?)?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit Unit' : 'Add New Unit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameCtrl,
              decoration:
                  const InputDecoration(labelText: 'Unit Identifier'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: rentCtrl,
              decoration:
                  const InputDecoration(labelText: 'Base Rent (KES)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final unitsRef = FirebaseFirestore.instance
                  .collection('properties')
                  .doc(propertyId)
                  .collection('units');

              final data = {
                'unitName': nameCtrl.text.trim(),
                'rent':     double.tryParse(rentCtrl.text) ?? 0.0,
              };

              if (isEditing) {
                await unitsRef.doc(unit!.id).update(data);
              } else {
                await unitsRef.add({
                  ...data,
                  'isOccupied': false,
                  'tenantId':   null,
                  'createdAt':  FieldValue.serverTimestamp(),
                });
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save Unit'),
          ),
        ],
      ),
    );
  }

  // ── Stat card ──────────────────────────────────────────────────────────────

  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                        .bodySmall
                        ?.copyWith(color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}


























































// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../../../shared/widgets/app_layout.dart';
// import '../../../config/routes.dart';

// class PropertyDetailScreen extends StatelessWidget {
//   final String propertyId;

//   const PropertyDetailScreen({super.key, required this.propertyId});

//   // ── Firestore helpers ──────────────────────────────────────────────────────

//   Stream<DocumentSnapshot<Map<String, dynamic>>> get _propertyStream =>
//       FirebaseFirestore.instance
//           .collection('properties')
//           .doc(propertyId)
//           .snapshots();

//   Stream<QuerySnapshot<Map<String, dynamic>>> get _unitsStream =>
//       FirebaseFirestore.instance
//           .collection('properties')
//           .doc(propertyId)
//           .collection('units')
//           .orderBy('unitName')
//           .snapshots();

//   // ── Build ──────────────────────────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     return AppLayout(
//       currentLocation: AppRoutes.properties,
//       child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
//         stream: _propertyStream,
//         builder: (context, propertySnap) {
//           // Loading state
//           if (propertySnap.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           // Error or missing doc
//           if (!propertySnap.hasData || !propertySnap.data!.exists) {
//             return const Center(child: Text('Property not found.'));
//           }

//           final property = propertySnap.data!.data()!;
//           final propertyName = property['name'] as String? ?? 'Unnamed Property';
//           final screenWidth = MediaQuery.of(context).size.width;
//           final isMobile = screenWidth < 768;

//           return Padding(
//             padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // ── Header ───────────────────────────────────────────────────
//                 if (isMobile)
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           IconButton(
//                             icon: const Icon(Icons.arrow_back),
//                             onPressed: () => context.go(AppRoutes.properties),
//                           ),
//                           Expanded(
//                             child: Text(propertyName,
//                                 style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 12),
//                       Row(
//                         children: [
//                           Expanded(
//                             child: OutlinedButton.icon(
//                               onPressed: () => _showEditBlockDialog(context, property),
//                               icon: const Icon(Icons.edit, size: 18),
//                               label: const Text('Edit Block'),
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: ElevatedButton.icon(
//                               onPressed: () => _showUnitDialog(context, null),
//                               icon: const Icon(Icons.add, size: 18),
//                               label: const Text('Add Unit'),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   )
//                 else
//                   Row(
//                     children: [
//                       IconButton(
//                         icon: const Icon(Icons.arrow_back),
//                         onPressed: () => context.go(AppRoutes.properties),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Text(propertyName,
//                             style: Theme.of(context).textTheme.headlineMedium),
//                       ),
//                       OutlinedButton.icon(
//                         onPressed: () => _showEditBlockDialog(context, property),
//                         icon: const Icon(Icons.edit),
//                         label: const Text('Edit Block'),
//                       ),
//                       const SizedBox(width: 16),
//                       ElevatedButton.icon(
//                         onPressed: () => _showUnitDialog(context, null),
//                         icon: const Icon(Icons.add),
//                         label: const Text('Add Unit'),
//                       ),
//                     ],
//                   ),
//                 const SizedBox(height: 24),

//                 // ── Stats (driven by units stream) ────────────────────────
//                 StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//                   stream: _unitsStream,
//                   builder: (context, unitsSnap) {
//                     final units = unitsSnap.data?.docs ?? [];
//                     final total = units.length;
//                     final occupied = units.where((u) => u['isOccupied'] == true).length;
//                     final vacant = total - occupied;
//                     final baseRent = (property['baseRent'] as num?)?.toDouble() ?? 0;
//                     final monthlyRevenue = occupied * baseRent;

//                     return LayoutBuilder(
//                       builder: (context, constraints) {
//                         if (constraints.maxWidth > 900) {
//                           return Row(
//                             children: [
//                               Expanded(child: _buildStatCard(context, 'Total Units', '$total', Icons.home_work, Colors.blue)),
//                               const SizedBox(width: 16),
//                               Expanded(child: _buildStatCard(context, 'Occupied', '$occupied', Icons.person, Colors.green)),
//                               const SizedBox(width: 16),
//                               Expanded(child: _buildStatCard(context, 'Vacant', '$vacant', Icons.door_front_door, Colors.orange)),
//                               const SizedBox(width: 16),
//                               Expanded(child: _buildStatCard(context, 'Monthly Revenue', 'KES ${monthlyRevenue.toStringAsFixed(0)}', Icons.attach_money, Colors.purple)),
//                             ],
//                           );
//                         } else if (constraints.maxWidth > 550) {
//                           return GridView.count(
//                             shrinkWrap: true,
//                             physics: const NeverScrollableScrollPhysics(),
//                             crossAxisCount: 2,
//                             childAspectRatio: 2.5,
//                             crossAxisSpacing: 16,
//                             mainAxisSpacing: 16,
//                             children: [
//                               _buildStatCard(context, 'Total Units', '$total', Icons.home_work, Colors.blue),
//                               _buildStatCard(context, 'Occupied', '$occupied', Icons.person, Colors.green),
//                               _buildStatCard(context, 'Vacant', '$vacant', Icons.door_front_door, Colors.orange),
//                               _buildStatCard(context, 'Monthly Revenue', 'KES ${monthlyRevenue.toStringAsFixed(0)}', Icons.attach_money, Colors.purple),
//                             ],
//                           );
//                         } else {
//                           return Column(
//                             children: [
//                               _buildStatCard(context, 'Total Units', '$total', Icons.home_work, Colors.blue),
//                               const SizedBox(height: 12),
//                               _buildStatCard(context, 'Occupied', '$occupied', Icons.person, Colors.green),
//                               const SizedBox(height: 12),
//                               _buildStatCard(context, 'Vacant', '$vacant', Icons.door_front_door, Colors.orange),
//                               const SizedBox(height: 12),
//                               _buildStatCard(context, 'Monthly Revenue', 'KES ${monthlyRevenue.toStringAsFixed(0)}', Icons.attach_money, Colors.purple),
//                             ],
//                           );
//                         }
//                       },
//                     );
//                   },
//                 ),
//                 const SizedBox(height: 32),

//                 Text('Units Management',
//                     style: Theme.of(context).textTheme.titleLarge),
//                 const SizedBox(height: 16),

//                 // ── Units List ────────────────────────────────────────────
//                 Expanded(
//                   child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//                     stream: _unitsStream,
//                     builder: (context, unitsSnap) {
//                       if (unitsSnap.connectionState == ConnectionState.waiting) {
//                         return const Center(child: CircularProgressIndicator());
//                       }

//                       final units = unitsSnap.data?.docs ?? [];
//                       if (units.isEmpty) {
//                         return const Center(
//                             child: Text('No units yet. Add one above.'));
//                       }

//                       return Card(
//                         child: ListView.separated(
//                           itemCount: units.length,
//                           separatorBuilder: (_, __) =>
//                               const Divider(height: 1),
//                           itemBuilder: (context, index) {
//                             final unit     = units[index];
//                             final data     = unit.data();
//                             final unitName = data['unitName'] as String? ?? 'Unit';
//                             final isOccupied = data['isOccupied'] as bool? ?? false;
//                             final tenantName = data['tenantName'] as String?;
//                             final rent = (data['rent'] as num?)?.toDouble() ?? 0;

//                             return ListTile(
//                               leading: CircleAvatar(
//                                 backgroundColor: isOccupied
//                                     ? Colors.green.withAlpha(50)
//                                     : Colors.orange.withAlpha(50),
//                                 child: Icon(
//                                   Icons.meeting_room,
//                                   color: isOccupied ? Colors.green : Colors.orange,
//                                 ),
//                               ),
//                               title: Text(unitName),
//                               subtitle: Text(isOccupied
//                                   ? 'Occupied • ${tenantName ?? "Tenant"}'
//                                   : 'Vacant'),
//                               trailing: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   Text(
//                                     'KES ${rent.toStringAsFixed(0)}',
//                                     style: TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       color: Theme.of(context).colorScheme.primary,
//                                     ),
//                                   ),
//                                   const SizedBox(width: 16),
//                                   PopupMenuButton<String>(
//                                     onSelected: (value) =>
//                                         _handleUnitAction(context, value, unit, unitName, isOccupied),
//                                     itemBuilder: (_) => [
//                                       const PopupMenuItem(
//                                         value: 'edit',
//                                         child: Text('Edit Unit Details'),
//                                       ),
//                                       if (isOccupied)
//                                         const PopupMenuItem(
//                                           value: 'tenant',
//                                           child: Text('View Tenant Info'),
//                                         )
//                                       else
//                                         const PopupMenuItem(
//                                           value: 'assign',
//                                           child: Text('Assign Tenant'),
//                                         ),
//                                       const PopupMenuItem(
//                                         value: 'delete',
//                                         child: Text('Delete Unit',
//                                             style: TextStyle(color: Colors.red)),
//                                       ),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                             );
//                           },
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   // ── Actions ────────────────────────────────────────────────────────────────

//   void _handleUnitAction(
//     BuildContext context,
//     String action,
//     QueryDocumentSnapshot<Map<String, dynamic>> unit,
//     String unitName,
//     bool isOccupied,
//   ) {
//     switch (action) {
//       case 'edit':
//         _showUnitDialog(context, unit);
//         break;
//       case 'assign':
//         context.go(
//           '/properties/$propertyId/units/${unit.id}/assign?unitName=$unitName',
//         );
//         break;
//       case 'delete':
//         _confirmDeleteUnit(context, unit.id, unitName);
//         break;
//       case 'tenant':
//         // Navigate to tenant detail — wire up when that screen is ready
//         break;
//     }
//   }

//   Future<void> _confirmDeleteUnit(
//       BuildContext context, String unitId, String unitName) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Delete Unit'),
//         content: Text('Are you sure you want to delete $unitName? This cannot be undone.'),
//         actions: [
//           TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: const Text('Cancel')),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       await FirebaseFirestore.instance
//           .collection('properties')
//           .doc(propertyId)
//           .collection('units')
//           .doc(unitId)
//           .delete();
//     }
//   }

//   void _showEditBlockDialog(BuildContext context, Map<String, dynamic> property) {
//     final nameCtrl     = TextEditingController(text: property['name'] ?? '');
//     final locationCtrl = TextEditingController(text: property['location'] ?? '');

//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text('Edit Block Details'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextFormField(
//               controller: nameCtrl,
//               decoration: const InputDecoration(labelText: 'Block Name'),
//             ),
//             const SizedBox(height: 16),
//             TextFormField(
//               controller: locationCtrl,
//               decoration: const InputDecoration(labelText: 'Location'),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//               onPressed: () => Navigator.pop(ctx),
//               child: const Text('Cancel')),
//           ElevatedButton(
//             onPressed: () async {
//               await FirebaseFirestore.instance
//                   .collection('properties')
//                   .doc(propertyId)
//                   .update({
//                 'name':     nameCtrl.text.trim(),
//                 'location': locationCtrl.text.trim(),
//               });
//               if (ctx.mounted) Navigator.pop(ctx);
//             },
//             child: const Text('Save Changes'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showUnitDialog(
//       BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>>? unit) {
//     final isEditing  = unit != null;
//     final nameCtrl   = TextEditingController(text: unit?.data()['unitName'] ?? '');
//     final rentCtrl   = TextEditingController(
//         text: (unit?.data()['rent'] as num?)?.toString() ?? '');

//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: Text(isEditing ? 'Edit Unit' : 'Add New Unit'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextFormField(
//               controller: nameCtrl,
//               decoration: const InputDecoration(labelText: 'Unit Identifier'),
//             ),
//             const SizedBox(height: 16),
//             TextFormField(
//               controller: rentCtrl,
//               decoration: const InputDecoration(labelText: 'Base Rent (KES)'),
//               keyboardType: TextInputType.number,
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//               onPressed: () => Navigator.pop(ctx),
//               child: const Text('Cancel')),
//           ElevatedButton(
//             onPressed: () async {
//               final unitsRef = FirebaseFirestore.instance
//                   .collection('properties')
//                   .doc(propertyId)
//                   .collection('units');

//               final data = {
//                 'unitName': nameCtrl.text.trim(),
//                 'rent':     double.tryParse(rentCtrl.text) ?? 0.0,
//               };

//               if (isEditing) {
//                 await unitsRef.doc(unit!.id).update(data);
//               } else {
//                 await unitsRef.add({
//                   ...data,
//                   'isOccupied': false,
//                   'tenantId':   null,
//                   'createdAt':  FieldValue.serverTimestamp(),
//                 });
//               }
//               if (ctx.mounted) Navigator.pop(ctx);
//             },
//             child: const Text('Save Unit'),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Stat card ──────────────────────────────────────────────────────────────

//   Widget _buildStatCard(BuildContext context, String title, String value,
//       IconData icon, Color color) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Expanded(
//                   child: Text(
//                     title,
//                     style: Theme.of(context)
//                         .textTheme
//                         .bodySmall
//                         ?.copyWith(color: Colors.grey[600]),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//                 const SizedBox(width: 4),
//                 Icon(icon, color: color, size: 20),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text(
//               value,
//               style: Theme.of(context)
//                   .textTheme
//                   .titleLarge
//                   ?.copyWith(fontWeight: FontWeight.bold),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
































































// // import 'package:flutter/material.dart';
// // import 'package:go_router/go_router.dart';
// // import '../../../shared/widgets/app_layout.dart';
// // import '../../../config/routes.dart';

// // class PropertyDetailScreen extends StatelessWidget {
// //   final String propertyId;
  
// //   const PropertyDetailScreen({super.key, required this.propertyId});

// //   @override
// //   Widget build(BuildContext context) {
// //     // Mock data based on propertyId
// //     final propertyName = 'Property Block $propertyId';

// //     return AppLayout(
// //       currentLocation: AppRoutes.properties, // Keep sidebar highlighted on Properties
// //       child: Padding(
// //         padding: const EdgeInsets.all(24.0),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Row(
// //               children: [
// //                 IconButton(
// //                   icon: const Icon(Icons.arrow_back),
// //                   onPressed: () => context.go(AppRoutes.properties),
// //                 ),
// //                 const SizedBox(width: 16),
// //                 Text(propertyName, style: Theme.of(context).textTheme.headlineMedium),
// //                 const Spacer(),
// //                 OutlinedButton.icon(
// //                   onPressed: () => _showEditBlockDialog(context, propertyName),
// //                   icon: const Icon(Icons.edit),
// //                   label: const Text('Edit Block Details'),
// //                 ),
// //                 const SizedBox(width: 16),
// //                 ElevatedButton.icon(
// //                   onPressed: () => _showUnitDialog(context, null),
// //                   icon: const Icon(Icons.add),
// //                   label: const Text('Add Individual Unit'),
// //                 ),
// //               ],
// //             ),
// //             const SizedBox(height: 24),
            
// //             // Overall Stats
// //             Row(
// //               children: [
// //                 _buildStatCard(context, 'Total Units', '10', Icons.home_work, Colors.blue),
// //                 const SizedBox(width: 16),
// //                 _buildStatCard(context, 'Occupied', '8', Icons.person, Colors.green),
// //                 const SizedBox(width: 16),
// //                 _buildStatCard(context, 'Vacant', '2', Icons.door_front_door, Colors.orange),
// //                 const SizedBox(width: 16),
// //                 _buildStatCard(context, 'Monthly Revenue', 'KES 120K', Icons.attach_money, Colors.purple),
// //               ],
// //             ),
// //             const SizedBox(height: 32),
            
// //             Text('Units Management', style: Theme.of(context).textTheme.titleLarge),
// //             const SizedBox(height: 16),
            
// //             Expanded(
// //               child: Card(
// //                 child: ListView.separated(
// //                   itemCount: 10,
// //                   separatorBuilder: (context, index) => const Divider(height: 1),
// //                   itemBuilder: (context, index) {
// //                     final isOccupied = index < 8; // Mock logic
// //                     final unitName = 'Unit A${index + 1}';
// //                     return ListTile(
// //                       leading: CircleAvatar(
// //                         backgroundColor: isOccupied ? Colors.green.withAlpha(50) : Colors.orange.withAlpha(50),
// //                         child: Icon(
// //                           Icons.meeting_room, 
// //                           color: isOccupied ? Colors.green : Colors.orange,
// //                         ),
// //                       ),
// //                       title: Text(unitName),
// //                       subtitle: Text(isOccupied ? 'Occupied • John Doe' : 'Vacant'),
// //                       trailing: Row(
// //                         mainAxisSize: MainAxisSize.min,
// //                         children: [
// //                           Text(
// //                             'KES 15,000',
// //                             style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
// //                           ),
// //                           const SizedBox(width: 16),
// //                           PopupMenuButton(
// //                             itemBuilder: (context) => [
// //                               PopupMenuItem(
// //                                 value: 'edit',
// //                                 child: const Text('Edit Unit Details'),
// //                                 onTap: () {
// //                                   // Wait for popup to close then show dialog
// //                                   WidgetsBinding.instance.addPostFrameCallback((_) {
// //                                     if (context.mounted) {
// //                                       _showUnitDialog(context, unitName);
// //                                     }
// //                                   });
// //                                 },
// //                               ),
// //                               if (isOccupied)
// //                                 PopupMenuItem(
// //                                   value: 'tenant',
// //                                   child: const Text('View Tenant Info'),
// //                                   onTap: () {},
// //                                 )
// //                               else
// //                                 PopupMenuItem(
// //                                   value: 'assign',
// //                                   child: const Text('Assign Tenant'),
// //                                   onTap: () {
// //                                     WidgetsBinding.instance.addPostFrameCallback((_) {
// //                                       if (context.mounted) {
// //                                         context.go('/properties/$propertyId/units/unit_${index}_id/assign?unitName=$unitName');
// //                                       }
// //                                     });
// //                                   },
// //                                 ),
// //                               const PopupMenuItem(
// //                                 value: 'delete',
// //                                 child: Text('Delete Unit', style: TextStyle(color: Colors.red)),
// //                               ),
// //                             ],
// //                           ),
// //                         ],
// //                       ),
// //                     );
// //                   },
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   void _showEditBlockDialog(BuildContext context, String currentName) {
// //     showDialog(
// //       context: context,
// //       builder: (context) {
// //         return AlertDialog(
// //           title: const Text('Edit Block Details'),
// //           content: Column(
// //             mainAxisSize: MainAxisSize.min,
// //             children: [
// //               TextFormField(
// //                 initialValue: currentName,
// //                 decoration: const InputDecoration(labelText: 'Block Name'),
// //               ),
// //               const SizedBox(height: 16),
// //               TextFormField(
// //                 initialValue: 'Ruaka',
// //                 decoration: const InputDecoration(labelText: 'Location'),
// //               ),
// //             ],
// //           ),
// //           actions: [
// //             TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
// //             ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Save Changes')),
// //           ],
// //         );
// //       },
// //     );
// //   }

// //   void _showUnitDialog(BuildContext context, String? currentUnitName) {
// //     final isEditing = currentUnitName != null;
// //     showDialog(
// //       context: context,
// //       builder: (context) {
// //         return AlertDialog(
// //           title: Text(isEditing ? 'Edit Unit' : 'Add New Unit'),
// //           content: Column(
// //             mainAxisSize: MainAxisSize.min,
// //             children: [
// //               TextFormField(
// //                 initialValue: currentUnitName,
// //                 decoration: const InputDecoration(labelText: 'Unit Identifier/Number'),
// //               ),
// //               const SizedBox(height: 16),
// //               TextFormField(
// //                 initialValue: isEditing ? '15000' : '',
// //                 decoration: const InputDecoration(labelText: 'Base Rent (KES)'),
// //                 keyboardType: TextInputType.number,
// //               ),
// //             ],
// //           ),
// //           actions: [
// //             TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
// //             ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Save Unit')),
// //           ],
// //         );
// //       },
// //     );
// //   }

// //   Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
// //     return Expanded(
// //       child: Card(
// //         child: Padding(
// //           padding: const EdgeInsets.all(16.0),
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               Row(
// //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                 children: [
// //                   Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
// //                   Icon(icon, color: color, size: 20),
// //                 ],
// //               ),
// //               const SizedBox(height: 8),
// //               Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
