import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_layout.dart';
import '../../../config/routes.dart';

class PropertyDetailScreen extends StatelessWidget {
  final String propertyId;
  
  const PropertyDetailScreen({super.key, required this.propertyId});

  @override
  Widget build(BuildContext context) {
    // Mock data based on propertyId
    final propertyName = 'Property Block $propertyId';

    return AppLayout(
      currentLocation: AppRoutes.properties, // Keep sidebar highlighted on Properties
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go(AppRoutes.properties),
                ),
                const SizedBox(width: 16),
                Text(propertyName, style: Theme.of(context).textTheme.headlineMedium),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => _showEditBlockDialog(context, propertyName),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Block Details'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showUnitDialog(context, null),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Individual Unit'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Overall Stats
            Row(
              children: [
                _buildStatCard(context, 'Total Units', '10', Icons.home_work, Colors.blue),
                const SizedBox(width: 16),
                _buildStatCard(context, 'Occupied', '8', Icons.person, Colors.green),
                const SizedBox(width: 16),
                _buildStatCard(context, 'Vacant', '2', Icons.door_front_door, Colors.orange),
                const SizedBox(width: 16),
                _buildStatCard(context, 'Monthly Revenue', 'KES 120K', Icons.attach_money, Colors.purple),
              ],
            ),
            const SizedBox(height: 32),
            
            Text('Units Management', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            
            Expanded(
              child: Card(
                child: ListView.separated(
                  itemCount: 10,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final isOccupied = index < 8; // Mock logic
                    final unitName = 'Unit A${index + 1}';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isOccupied ? Colors.green.withAlpha(50) : Colors.orange.withAlpha(50),
                        child: Icon(
                          Icons.meeting_room, 
                          color: isOccupied ? Colors.green : Colors.orange,
                        ),
                      ),
                      title: Text(unitName),
                      subtitle: Text(isOccupied ? 'Occupied • John Doe' : 'Vacant'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'KES 15,000',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                          ),
                          const SizedBox(width: 16),
                          PopupMenuButton(
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: const Text('Edit Unit Details'),
                                onTap: () {
                                  // Wait for popup to close then show dialog
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (context.mounted) {
                                      _showUnitDialog(context, unitName);
                                    }
                                  });
                                },
                              ),
                              if (isOccupied)
                                PopupMenuItem(
                                  value: 'tenant',
                                  child: const Text('View Tenant Info'),
                                  onTap: () {},
                                )
                              else
                                PopupMenuItem(
                                  value: 'assign',
                                  child: const Text('Assign Tenant'),
                                  onTap: () {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (context.mounted) {
                                        context.go('/properties/$propertyId/units/unit_${index}_id/assign?unitName=$unitName');
                                      }
                                    });
                                  },
                                ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete Unit', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
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

  void _showEditBlockDialog(BuildContext context, String currentName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Block Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: currentName,
                decoration: const InputDecoration(labelText: 'Block Name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: 'Ruaka',
                decoration: const InputDecoration(labelText: 'Location'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Save Changes')),
          ],
        );
      },
    );
  }

  void _showUnitDialog(BuildContext context, String? currentUnitName) {
    final isEditing = currentUnitName != null;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Unit' : 'Add New Unit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: currentUnitName,
                decoration: const InputDecoration(labelText: 'Unit Identifier/Number'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: isEditing ? '15000' : '',
                decoration: const InputDecoration(labelText: 'Base Rent (KES)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Save Unit')),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                  Icon(icon, color: color, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
