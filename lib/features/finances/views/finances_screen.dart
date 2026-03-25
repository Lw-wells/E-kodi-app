import 'package:flutter/material.dart';
import '../../../shared/widgets/app_layout.dart';
import '../../../config/routes.dart';
import 'utility_bills_tab.dart';

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
                Text('Finances & M-Pesa',
                    style: Theme.of(context).textTheme.headlineMedium),
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
                    const Expanded(
                      child: TabBarView(
                        children: [
                          // M-Pesa tab — placeholder until M-Pesa integration
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.phone_android,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('M-Pesa integration coming soon',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),

                          // ✅ Utility Bills tab — fully wired
                          UtilityBillsTab(),

                          // Expenses tab — placeholder
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.receipt_long,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('Expenses log coming soon',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
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