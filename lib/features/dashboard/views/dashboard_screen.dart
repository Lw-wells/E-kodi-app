import 'package:flutter/material.dart';
import '../../../shared/widgets/app_layout.dart';
import '../../../config/routes.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentLocation: AppRoutes.dashboard,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard Overview',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildSummaryCard(context, 'Total Properties', '12', Icons.business, Colors.blue),
                const SizedBox(width: 16),
                _buildSummaryCard(context, 'Total Tenants', '45', Icons.people, Colors.green),
                const SizedBox(width: 16),
                _buildSummaryCard(context, 'Monthly Revenue', 'KES 1.2M', Icons.attach_money, Colors.orange),
                const SizedBox(width: 16),
                _buildSummaryCard(context, 'Pending Utilities', 'KES 45K', Icons.electrical_services, Colors.red),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Recent M-Pesa Payments', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 16),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 5,
                            itemBuilder: (context, index) {
                              return ListTile(
                                leading: const CircleAvatar(child: Icon(Icons.money)),
                                title: Text('Tenant ${index + 1} - A2 Block'),
                                subtitle: Text('Paid KES ${15000 + (index * 1000)}'),
                                trailing: const Text('2 hours ago', style: TextStyle(color: Colors.grey)),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: Card(
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
                            onTap: () {},
                          ),
                          ListTile(
                            leading: const Icon(Icons.person_add),
                            title: const Text('Add Tenant'),
                            onTap: () {},
                          ),
                          ListTile(
                            leading: const Icon(Icons.message),
                            title: const Text('Send Announcement'),
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[600])),
                  Icon(icon, color: color, size: 28),
                ],
              ),
              const SizedBox(height: 16),
              Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
