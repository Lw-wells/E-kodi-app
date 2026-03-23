import 'package:flutter/material.dart';
import '../../../shared/widgets/app_layout.dart';
import '../../../config/routes.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isDesktop = screenWidth >= 1024;

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
                ? Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
                : Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            
            // Summary Cards Section
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 1100) {
                  return Row(
                    children: [
                      Expanded(child: _buildSummaryCard(context, 'Total Properties', '12', Icons.business, Colors.blue)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSummaryCard(context, 'Total Tenants', '45', Icons.people, Colors.green)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSummaryCard(context, 'Monthly Revenue', 'KES 1.2M', Icons.attach_money, Colors.orange)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSummaryCard(context, 'Pending Utilities', 'KES 45K', Icons.electrical_services, Colors.red)),
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
                    children: [
                      _buildSummaryCard(context, 'Total Properties', '12', Icons.business, Colors.blue),
                      _buildSummaryCard(context, 'Total Tenants', '45', Icons.people, Colors.green),
                      _buildSummaryCard(context, 'Monthly Revenue', 'KES 1.2M', Icons.attach_money, Colors.orange),
                      _buildSummaryCard(context, 'Pending Utilities', 'KES 45K', Icons.electrical_services, Colors.red),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildSummaryCard(context, 'Total Properties', '12', Icons.business, Colors.blue),
                      const SizedBox(height: 12),
                      _buildSummaryCard(context, 'Total Tenants', '45', Icons.people, Colors.green),
                      const SizedBox(height: 12),
                      _buildSummaryCard(context, 'Monthly Revenue', 'KES 1.2M', Icons.attach_money, Colors.orange),
                      const SizedBox(height: 12),
                      _buildSummaryCard(context, 'Pending Utilities', 'KES 45K', Icons.electrical_services, Colors.red),
                    ],
                  );
                }
              },
            ),
            
            const SizedBox(height: 32),
            
            // Main Content Area
            if (screenWidth > 900)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildRecentPayments(context),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 1,
                    child: _buildQuickActions(context),
                  ),
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

  Widget _buildRecentPayments(BuildContext context) {
    return Card(
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
    );
  }

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
            // ✅ Guide landlord to pick a property first, then assign from unit
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Select a property, then tap "Assign Tenant" on a vacant unit.'),
                  duration: Duration(seconds: 4),
                ),
              );
              context.go(AppRoutes.properties);
            },
          ),
          ListTile(
            leading: const Icon(Icons.message),
            title: const Text('Send Announcement'),
            onTap: () {},
          ),
        ],
      ),
    ),
  );
}

  // Widget _buildQuickActions(BuildContext context) {
  //   return Card(
  //     child: Padding(
  //       padding: const EdgeInsets.all(16.0),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
  //           const SizedBox(height: 16),
  //           ListTile(
  //             leading: const Icon(Icons.add_home),
  //             title: const Text('Add Property'),
  //             onTap: () => context.go(AppRoutes.addProperty),
  //           ),
  //           ListTile(
  //             leading: const Icon(Icons.person_add),
  //             title: const Text('Add Tenant'),
  //             onTap: () {},
  //           ),
  //           ListTile(
  //             leading: const Icon(Icons.message),
  //             title: const Text('Send Announcement'),
  //             onTap: () {},
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildSummaryCard(BuildContext context, String title, String value, IconData icon, Color color) {
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
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: color, size: 28),
              ],
            ),
            const SizedBox(height: 16),
            Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
