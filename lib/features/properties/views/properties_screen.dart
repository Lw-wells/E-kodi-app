import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/widgets/app_layout.dart';
import '../../../config/routes.dart';

class PropertiesScreen extends StatelessWidget {
  const PropertiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return AppLayout(
      currentLocation: AppRoutes.properties,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Properties Management',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.go(AppRoutes.addProperty),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Property'),
                    ),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Properties Management',
                      style: Theme.of(context).textTheme.headlineMedium),
                  ElevatedButton.icon(
                    onPressed: () => context.go(AppRoutes.addProperty),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Property'),
                  ),
                ],
              ),
            const SizedBox(height: 24),

            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                // ✅ Real-time list from Firestore, newest first
                stream: FirebaseFirestore.instance
                    .collection('properties')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {

                  // Loading
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Error
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final properties = snapshot.data?.docs ?? [];

                  // Empty state
                  if (properties.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.business_outlined,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('No properties yet',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: Colors.grey[600])),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => context.go(AppRoutes.addProperty),
                            icon: const Icon(Icons.add),
                            label: const Text('Add your first property'),
                          ),
                        ],
                      ),
                    );
                  }

                  return Card(
                    child: ListView.separated(
                      itemCount: properties.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final doc  = properties[index];
                        final data = doc.data();

                        final name     = data['name']     as String? ?? 'Unnamed Property';
                        final location = data['location'] as String? ?? 'Unknown Location';
                        final unitCount = data['unitCount'] as int? ?? 0;

                        return ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.business,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          title: Text(name),
                          // ✅ Shows real unit count and location from Firestore
                          subtitle: Text('$unitCount Units • $location'),
                          trailing: IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, size: 16),
                            onPressed: () => context.go('/properties/${doc.id}'),
                          ),
                          // ✅ Uses real Firestore doc.id, not a loop index
                          onTap: () => context.go('/properties/${doc.id}'),
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
}







































// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import '../../../shared/widgets/app_layout.dart';
// import '../../../config/routes.dart';

// class PropertiesScreen extends StatelessWidget {
//   const PropertiesScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return AppLayout(
//       currentLocation: AppRoutes.properties,
//       child: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text('Properties Management', style: Theme.of(context).textTheme.headlineMedium),
//                 ElevatedButton.icon(
//                   onPressed: () => context.go(AppRoutes.addProperty),
//                   icon: const Icon(Icons.add),
//                   label: const Text('Add Property'),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 24),
//             Expanded(
//               child: Card(
//                 child: ListView.builder(
//                   itemCount: 4,
//                   itemBuilder: (context, index) {
//                     return ListTile(
//                       leading: Container(
//                         width: 50,
//                         height: 50,
//                         color: Colors.grey[300],
//                         child: const Icon(Icons.business),
//                       ),
//                       title: Text('Property Block ${String.fromCharCode(65 + index)}'),
//                       subtitle: const Text('10 Units • 2 Vacant • Nairobi'),
//                       trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
//                       onTap: () {
//                         context.go('/properties/$index');
//                       },
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
