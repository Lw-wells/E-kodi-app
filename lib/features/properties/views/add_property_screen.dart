import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_layout.dart';
import '../../../config/routes.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Property Controllers
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  
  // Units Generator State
  int _numberOfUnits = 1;
  double _defaultRent = 0.0;
  String _unitPrefix = "A"; // e.g., A1, A2...

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _saveProperty() {
    if (_formKey.currentState!.validate()) {
      // Logic to save property + auto-generate units would go here
      // Example: We generate `_numberOfUnits` units starting from `_unitPrefix`1
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property and Units successfully created!')),
      );
      
      context.go(AppRoutes.properties);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentLocation: AppRoutes.properties, // Keep sidebar on properties
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
                    onPressed: () => context.go(AppRoutes.properties),
                  ),
                  const SizedBox(width: 16),
                  Text('Add New Property Building', style: Theme.of(context).textTheme.headlineMedium),
                ],
              ),
              const SizedBox(height: 32),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Side: Property Main Details
                  Expanded(
                    flex: 3,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Property Details', style: Theme.of(context).textTheme.titleLarge),
                            const Divider(height: 32),
                            
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Property Name (Block Name)',
                                hintText: 'e.g., Sunrise Apartments Block A',
                                prefixIcon: Icon(Icons.business),
                              ),
                              validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
                            ),
                            const SizedBox(height: 16),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _locationController,
                                    decoration: const InputDecoration(
                                      labelText: 'Location / Estate',
                                      hintText: 'e.g., Ruaka, Utawala',
                                      prefixIcon: Icon(Icons.map),
                                    ),
                                    validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _addressController,
                                    decoration: const InputDecoration(
                                      labelText: 'Specific Address',
                                      hintText: 'e.g., Plot 123, Off Limuru Road',
                                      prefixIcon: Icon(Icons.location_on),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  
                  // Right Side: Bulk Unit Generation
                  Expanded(
                    flex: 2,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Units Generation', style: Theme.of(context).textTheme.titleLarge),
                            const Text(
                              'Quickly generate multiple units for this property block.',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const Divider(height: 32),
                            
                            TextFormField(
                              initialValue: _numberOfUnits.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Number of Units',
                                prefixIcon: Icon(Icons.format_list_numbered),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setState(() {
                                  _numberOfUnits = int.tryParse(value) ?? 1;
                                });
                              },
                              validator: (value) {
                                final val = int.tryParse(value ?? '');
                                if (val == null || val < 1) return 'Must be at least 1 unit';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: _unitPrefix,
                                    decoration: const InputDecoration(
                                      labelText: 'Unit Prefix',
                                      hintText: 'e.g., A, B, Rm-',
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _unitPrefix = value;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: _defaultRent.toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'Base Rent (KES)',
                                      prefixIcon: Icon(Icons.money),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      setState(() {
                                        _defaultRent = double.tryParse(value) ?? 0.0;
                                      });
                                    },
                                    validator: (value) {
                                      final val = double.tryParse(value ?? '');
                                      if (val == null || val < 0) return 'Invalid rent amount';
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha(100)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Preview:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text(
                                    'This will generate $_numberOfUnits units:\n'
                                    '${_unitPrefix}1, ${_unitPrefix}2, ${_unitPrefix}3 ... $_unitPrefix$_numberOfUnits\n'
                                    'Each with a base rent of KES ${_defaultRent.toStringAsFixed(2)}',
                                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Submit Area
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => context.go(AppRoutes.properties),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _saveProperty,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Property & Units'),
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
