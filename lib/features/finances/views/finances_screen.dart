import 'package:flutter/material.dart';
import '../../../shared/widgets/app_layout.dart';
import '../../../config/routes.dart';

class FinancesScreen extends StatelessWidget {
  const FinancesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentLocation: AppRoutes.finances,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Finances & M-Pesa', style: Theme.of(context).textTheme.headlineMedium),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download),
                  label: const Text('Export Report'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'M-Pesa Ledger'),
                        Tab(text: 'Utility Bills'),
                        Tab(text: 'Expenses'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        children: [
                          Card(
                            child: ListView.builder(
                              itemCount: 10,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  leading: const Icon(Icons.money, color: Colors.green),
                                  title: Text('M-Pesa Paybill - KES ${10000 + (index * 500)}'),
                                  subtitle: Text('Receipt QWX... • from 0700... • ${index + 1} hrs ago'),
                                  trailing: Chip(
                                    label: const Text('Matched', style: TextStyle(color: Colors.white)),
                                    backgroundColor: Colors.green[400],
                                  ),
                                );
                              },
                            ),
                          ),
                          const Center(child: Text('Utility Bills Tracking (Water / Electricity)')),
                          const Center(child: Text('Property Expenses log')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
