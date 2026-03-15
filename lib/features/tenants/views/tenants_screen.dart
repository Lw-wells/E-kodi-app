import 'package:flutter/material.dart';
import '../../../shared/widgets/app_layout.dart';
import '../../../config/routes.dart';

class TenantsScreen extends StatelessWidget {
  const TenantsScreen({super.key});

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
                Text('Tenants', style: Theme.of(context).textTheme.headlineMedium),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Tenant'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Card(
                child: ListView.builder(
                  itemCount: 8,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text('John Doe ${index + 1}'),
                      subtitle: Text('Block A • Unit ${100 + index} • 0700000000'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.bolt, color: Colors.orange), tooltip: 'Utility Bills', onPressed: () {}),
                          IconButton(icon: const Icon(Icons.chat_bubble_outline), tooltip: 'WhatsApp Message', onPressed: () {}),
                          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
