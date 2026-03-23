import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/widgets/app_layout.dart';
import '../../../config/routes.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController     = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController  = TextEditingController();

  int    _numberOfUnits = 1;
  double _defaultRent   = 0.0;
  String _unitPrefix    = 'A';
  bool   _isSaving      = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveProperty() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final firestore = FirebaseFirestore.instance;

      final propertyRef = await firestore.collection('properties').add({
        'name':       _nameController.text.trim(),
        'location':   _locationController.text.trim(),
        'address':    _addressController.text.trim(),
        'unitCount':  _numberOfUnits,
        'baseRent':   _defaultRent,
        'unitPrefix': _unitPrefix,
        'createdAt':  FieldValue.serverTimestamp(),
      });

      final batch = firestore.batch();
      for (int i = 1; i <= _numberOfUnits; i++) {
        final unitRef = propertyRef.collection('units').doc();
        batch.set(unitRef, {
          'unitName':   '$_unitPrefix$i',
          'rent':       _defaultRent,
          'isOccupied': false,
          'tenantId':   null,
          'createdAt':  FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Property "${_nameController.text.trim()}" created with $_numberOfUnits units!'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/properties/${propertyRef.id}');

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving property: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Property details card ──────────────────────────────────────────────────

  Widget _buildPropertyDetailsSection() {
    return Card(
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
              validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
            ),
            const SizedBox(height: 16),

            // On mobile, stack these vertically
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 500) {
                  return Row(
                    children: [
                      Expanded(child: _buildLocationField()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildAddressField()),
                    ],
                  );
                }
                return Column(
                  children: [
                    _buildLocationField(),
                    const SizedBox(height: 16),
                    _buildAddressField(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationField() {
    return TextFormField(
      controller: _locationController,
      decoration: const InputDecoration(
        labelText: 'Location / Estate',
        hintText: 'e.g., Ruaka, Utawala',
        prefixIcon: Icon(Icons.map),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
    );
  }

  Widget _buildAddressField() {
    return TextFormField(
      controller: _addressController,
      decoration: const InputDecoration(
        labelText: 'Specific Address',
        hintText: 'e.g., Plot 123, Off Limuru Road',
        prefixIcon: Icon(Icons.location_on),
      ),
    );
  }

  // ── Units generation card ──────────────────────────────────────────────────

  Widget _buildUnitsGenerationSection() {
    return Card(
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
              onChanged: (v) => setState(() => _numberOfUnits = int.tryParse(v) ?? 1),
              validator: (v) {
                final val = int.tryParse(v ?? '');
                if (val == null || val < 1) return 'Must be at least 1';
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
                    onChanged: (v) => setState(() => _unitPrefix = v),
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
                    onChanged: (v) => setState(() => _defaultRent = double.tryParse(v) ?? 0.0),
                    validator: (v) {
                      final val = double.tryParse(v ?? '');
                      if (val == null || val < 0) return 'Invalid amount';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Preview box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withAlpha(100)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Preview:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Will generate $_numberOfUnits units:\n'
                    '${_unitPrefix}1, ${_unitPrefix}2 ... $_unitPrefix$_numberOfUnits\n'
                    'Base rent: KES ${_defaultRent.toStringAsFixed(2)}',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return AppLayout(
      currentLocation: AppRoutes.properties,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────────
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _isSaving ? null : () => context.go(AppRoutes.properties),
                  ),
                  SizedBox(width: isMobile ? 8 : 16),
                  Expanded(
                    child: Text(
                      'Add New Property',
                      style: isMobile
                          ? Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
                          : Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 16 : 32),

              // ── Cards: stacked on mobile, side-by-side on desktop ────────
              if (isMobile)
                Column(
                  children: [
                    _buildPropertyDetailsSection(),
                    const SizedBox(height: 16),
                    _buildUnitsGenerationSection(),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildPropertyDetailsSection()),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: _buildUnitsGenerationSection()),
                  ],
                ),

              SizedBox(height: isMobile ? 16 : 32),

              // ── Submit row ───────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => context.go(AppRoutes.properties),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveProperty,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Saving...' : 'Save Property & Units'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 24 : 32,
                        vertical:   isMobile ? 16 : 20,
                      ),
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