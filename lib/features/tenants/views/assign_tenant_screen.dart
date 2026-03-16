import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_layout.dart';
import '../../../config/routes.dart';

class AssignTenantScreen extends ConsumerStatefulWidget {
  final String unitId;
  final String propertyId;
  final String unitName;

  const AssignTenantScreen({
    super.key, 
    required this.unitId,
    required this.propertyId,
    required this.unitName,
  });

  @override
  ConsumerState<AssignTenantScreen> createState() => _AssignTenantScreenState();
}

class _AssignTenantScreenState extends ConsumerState<AssignTenantScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController(); // Essential for Whatsapp Bot
  final _idController = TextEditingController();
  final _depositController = TextEditingController();
  DateTime _leaseStart = DateTime.now();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _idController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  void _assignTenant() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      // We will interact with TenantRepository and PropertyRepository here:
      // 1. Create Tenant Model linked to Landlord, Property, and Unit
      // 2. Add 'deposit' Payment record in finances linked to this Tenant if deposit entered
      // 3. Update Unit document to `isOccupied = true` and `currentTenantId` = New Tenant ID
      // 4. Send Welcome WhatsApp Message via Cloud Functions Trigger
      
      // Simulating a Firebase write delay for UI feedback
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tenant successfully assigned to ${widget.unitName}!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Go back to property details
        context.go('/properties/${widget.propertyId}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentLocation: AppRoutes.properties, // Nested inside properties visually
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go('/properties/${widget.propertyId}'),
                  ),
                  const SizedBox(width: 16),
                  Text('Assign Tenant to ${widget.unitName}', style: Theme.of(context).textTheme.headlineMedium),
                ],
              ),
              const SizedBox(height: 32),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tenant Registration Info', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        'CRITICAL: Ensure the phone number accurately matches the tenant\'s active WhatsApp and MPesa number for bot interactions.',
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                      const Divider(height: 32),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                hintText: 'e.g. Jane Doe',
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'WhatsApp / MPesa Number',
                                hintText: '07XX XXX XXX',
                                prefixIcon: Icon(Icons.phone),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _idController,
                              decoration: const InputDecoration(
                                labelText: 'National ID',
                                prefixIcon: Icon(Icons.badge),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: TextFormField(
                              controller: _depositController,
                              decoration: const InputDecoration(
                                labelText: 'Security Deposit Paid (KES)',
                                prefixIcon: Icon(Icons.account_balance_wallet),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      const Text('Lease Dates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Lease Start Date'),
                        subtitle: Text('${_leaseStart.day}/${_leaseStart.month}/${_leaseStart.year}'),
                        trailing: OutlinedButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _leaseStart,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) {
                              setState(() => _leaseStart = date);
                            }
                          },
                          child: const Text('Select Date'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => context.go('/properties/${widget.propertyId}'),
                    child: const Text('Cancel Request'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _assignTenant,
                    icon: _isLoading 
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check_circle),
                    label: Text(_isLoading ? 'Processing...' : 'Onboard Tenant & Start Lease'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
