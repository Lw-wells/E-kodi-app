import 'package:flutter/material.dart';
import '../../../shared/widgets/app_layout.dart';
import '../../../config/routes.dart';

class CommunicationsScreen extends StatelessWidget {
  const CommunicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentLocation: AppRoutes.communications,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tenant Communications', style: Theme.of(context).textTheme.headlineMedium),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.send),
                  label: const Text('New Announcement'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Card(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.call, color: Colors.white)),
                          title: Text('WhatsApp Issue Report #${1000 + index}'),
                          subtitle: const Text('"The toilet in block A unit 12 is leaking..."'),
                          trailing: Text('${index * 2} mins ago', style: const TextStyle(color: Colors.grey)),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Broadcast History', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 16),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Maintenance Reminder'),
                            subtitle: const Text('To: Block A • Sent 2 days ago'),
                            trailing: Chip(
                              label: const Text('12 Read', style: TextStyle(color: Colors.white, fontSize: 10)),
                              backgroundColor: Colors.blue[400],
                            ),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Rent Due'),
                            subtitle: const Text('To: All Tenants • Sent 5 days ago'),
                            trailing: Chip(
                              label: const Text('40 Read', style: TextStyle(color: Colors.white, fontSize: 10)),
                              backgroundColor: Colors.blue[400],
                            ),
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
}
