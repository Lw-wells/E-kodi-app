import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/widgets/app_layout.dart';
import '../../../config/routes.dart';

class AssignTenantScreen extends StatefulWidget {
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
  State<AssignTenantScreen> createState() => _AssignTenantScreenState();
}

class _AssignTenantScreenState extends State<AssignTenantScreen> {
  final _formKey           = GlobalKey<FormState>();
  final _nameController    = TextEditingController();
  final _phoneController   = TextEditingController();
  final _idController      = TextEditingController();
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

  Future<void> _assignTenant() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final firestore   = FirebaseFirestore.instance;
      final propertyRef = firestore.collection('properties').doc(widget.propertyId);

      // 1️⃣ Fetch property name to denormalise onto tenant doc
      final propertySnap = await propertyRef.get();
      final propertyName = propertySnap.data()?['name'] as String? ?? 'Unknown Property';

      // 2️⃣ Create tenant document inside the property's tenants subcollection
      final tenantRef = await propertyRef.collection('tenants').add({
        'name':         _nameController.text.trim(),
        'phone':        _phoneController.text.trim(),
        'nationalId':   _idController.text.trim(),
        'unitId':       widget.unitId,
        'unitName':     widget.unitName,
        'propertyId':   widget.propertyId,
        'propertyName': propertyName,
        'leaseStart':   Timestamp.fromDate(_leaseStart),
        'isActive':     true,
        'createdAt':    FieldValue.serverTimestamp(),
      });

      final batch = firestore.batch();

      // 3️⃣ Mirror tenant to top-level tenants collection for global listing
      batch.set(
        firestore.collection('tenants').doc(tenantRef.id),
        {
          'name':         _nameController.text.trim(),
          'phone':        _phoneController.text.trim(),
          'nationalId':   _idController.text.trim(),
          'unitId':       widget.unitId,
          'unitName':     widget.unitName,
          'propertyId':   widget.propertyId,
          'propertyName': propertyName,
          'leaseStart':   Timestamp.fromDate(_leaseStart),
          'isActive':     true,
          'createdAt':    FieldValue.serverTimestamp(),
        },
      );

      // 4️⃣ Mark unit as occupied and link tenant
      batch.update(
        propertyRef.collection('units').doc(widget.unitId),
        {
          'isOccupied': true,
          'tenantId':   tenantRef.id,
          'tenantName': _nameController.text.trim(),
        },
      );

      // 5️⃣ Record deposit as a finance entry if amount was entered
      final depositAmount = double.tryParse(_depositController.text) ?? 0;
      if (depositAmount > 0) {
        batch.set(
          firestore.collection('finances').doc(),
          {
            'type':         'deposit',
            'amount':       depositAmount,
            'tenantId':     tenantRef.id,
            'tenantName':   _nameController.text.trim(),
            'unitId':       widget.unitId,
            'unitName':     widget.unitName,
            'propertyId':   widget.propertyId,
            'propertyName': propertyName,
            'createdAt':    FieldValue.serverTimestamp(),
          },
        );
      }

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${_nameController.text.trim()} successfully assigned to ${widget.unitName}!'),
          backgroundColor: Colors.green,
        ),
      );

      // 6️⃣ Navigate back to the property detail page
      context.go('/properties/${widget.propertyId}');

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error assigning tenant: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
              // ── Header ─────────────────────────────────────────────────
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _isLoading
                        ? null
                        : () => context.go('/properties/${widget.propertyId}'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Assign Tenant to ${widget.unitName}',
                      style: isMobile
                          ? Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)
                          : Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ── Form card ───────────────────────────────────────────────
              Card(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tenant Registration Info',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        'CRITICAL: Ensure the phone number accurately matches '
                        "the tenant's active WhatsApp and M-Pesa number.",
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                      const Divider(height: 32),

                      // Name + Phone
                      if (isMobile) ...[
                        _buildNameField(),
                        const SizedBox(height: 16),
                        _buildPhoneField(),
                      ] else
                        Row(
                          children: [
                            Expanded(child: _buildNameField()),
                            const SizedBox(width: 24),
                            Expanded(child: _buildPhoneField()),
                          ],
                        ),
                      const SizedBox(height: 24),

                      // ID + Deposit
                      if (isMobile) ...[
                        _buildIdField(),
                        const SizedBox(height: 16),
                        _buildDepositField(),
                      ] else
                        Row(
                          children: [
                            Expanded(child: _buildIdField()),
                            const SizedBox(width: 24),
                            Expanded(child: _buildDepositField()),
                          ],
                        ),
                      const SizedBox(height: 32),

                      // ── Lease start date ──────────────────────────────
                      const Text('Lease Dates',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Lease Start Date'),
                        subtitle: Text(
                            '${_leaseStart.day}/${_leaseStart.month}/${_leaseStart.year}'),
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

              // ── Submit row ──────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => context.go('/properties/${widget.propertyId}'),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _assignTenant,
                    icon: _isLoading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle),
                    label: Text(_isLoading
                        ? 'Processing...'
                        : 'Onboard Tenant & Start Lease'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 20 : 32,
                        vertical: isMobile ? 14 : 20,
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

  // ── Field helpers ──────────────────────────────────────────────────────────

  Widget _buildNameField() => TextFormField(
        controller: _nameController,
        decoration: const InputDecoration(
          labelText: 'Full Name',
          hintText: 'e.g. Jane Doe',
          prefixIcon: Icon(Icons.person),
        ),
        validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
      );

  Widget _buildPhoneField() => TextFormField(
        controller: _phoneController,
        decoration: const InputDecoration(
          labelText: 'WhatsApp / M-Pesa Number',
          hintText: '07XX XXX XXX',
          prefixIcon: Icon(Icons.phone),
        ),
        keyboardType: TextInputType.phone,
        validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
      );

  Widget _buildIdField() => TextFormField(
        controller: _idController,
        decoration: const InputDecoration(
          labelText: 'National ID',
          prefixIcon: Icon(Icons.badge),
        ),
        keyboardType: TextInputType.number,
        validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
      );

  Widget _buildDepositField() => TextFormField(
        controller: _depositController,
        decoration: const InputDecoration(
          labelText: 'Security Deposit Paid (KES)',
          prefixIcon: Icon(Icons.account_balance_wallet),
        ),
        keyboardType: TextInputType.number,
      );
}