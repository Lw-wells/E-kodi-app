import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../shared/widgets/app_layout.dart';
import '../../../config/routes.dart';
import '../../../core/services/auth_service.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController(); // ✅ new
  final _idController = TextEditingController();
  final _depositController = TextEditingController();

  DateTime _leaseStart = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _idController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  Future<void> _assignTenant() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final propertyRef = firestore
          .collection('properties')
          .doc(widget.propertyId);

      final propertySnap = await propertyRef.get();
      final propertyName =
          propertySnap.data()?['name'] as String? ?? 'Unknown Property';

      // 1️⃣ Create tenant document
      final tenantRef = await propertyRef.collection('tenants').add({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'nationalId': _idController.text.trim(),
        'unitId': widget.unitId,
        'unitName': widget.unitName,
        'propertyId': widget.propertyId,
        'propertyName': propertyName,
        'leaseStart': Timestamp.fromDate(_leaseStart),
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final batch = firestore.batch();

      // 2️⃣ Mirror to top-level tenants collection
      batch.set(firestore.collection('tenants').doc(tenantRef.id), {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'nationalId': _idController.text.trim(),
        'unitId': widget.unitId,
        'unitName': widget.unitName,
        'propertyId': widget.propertyId,
        'propertyName': propertyName,
        'leaseStart': Timestamp.fromDate(_leaseStart),
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3️⃣ Mark unit as occupied
      batch.update(propertyRef.collection('units').doc(widget.unitId), {
        'isOccupied': true,
        'tenantId': tenantRef.id,
        'tenantName': _nameController.text.trim(),
      });

      // 4️⃣ Record deposit
      final depositAmount = double.tryParse(_depositController.text) ?? 0;
      if (depositAmount > 0) {
        batch.set(firestore.collection('finances').doc(), {
          'type': 'deposit',
          'amount': depositAmount,
          'tenantId': tenantRef.id,
          'tenantName': _nameController.text.trim(),
          'unitId': widget.unitId,
          'unitName': widget.unitName,
          'propertyId': widget.propertyId,
          'propertyName': propertyName,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      // 5️⃣ Create Firebase Auth account via Cloud Function
      final defaultPassword =
          'Ekodi@${_phoneController.text.trim().replaceAll(' ', '')}';
      final authService = AuthService();

      String tenantUid = '';
      try {
        tenantUid = await authService.createTenantAccount(
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          name: _nameController.text.trim(),
          tenantId: tenantRef.id,
          unitId: widget.unitId,
          unitName: widget.unitName,
          propertyId: widget.propertyId,
          propertyName: propertyName,
        );
      } catch (authError) {
        debugPrint('Auth account creation failed: $authError');
      }

      // 6️⃣ Send welcome email with credentials via Trigger Email
      try {
        await firestore.collection('mail').add({
          'to': _emailController.text.trim(),
          'message': {
            'subject': 'Welcome to E-Kodi — Your Tenant Portal Credentials',
            'html':
                '''
              <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                <div style="background-color: #1976D2; padding: 24px; text-align: center;">
                  <h1 style="color: white; margin: 0;">🏠 E-Kodi</h1>
                  <p style="color: #E3F2FD; margin: 8px 0 0;">Smart Property Management</p>
                </div>
                <div style="padding: 32px; background: #f9f9f9;">
                  <h2>Welcome, ${_nameController.text.trim()}!</h2>
                  <p>You have been successfully onboarded as a tenant at <strong>$propertyName</strong>, Unit <strong>${widget.unitName}</strong>.</p>
                  
                  <div style="background: white; border: 1px solid #e0e0e0; border-radius: 8px; padding: 24px; margin: 24px 0;">
                    <h3 style="margin-top: 0; color: #1976D2;">🔑 Your Login Credentials</h3>
                    <p><strong>Email:</strong> ${_emailController.text.trim()}</p>
                    <p><strong>Password:</strong> $defaultPassword</p>
                    <p><strong>Portal URL:</strong> Your landlord will share the app link</p>
                  </div>

                  <div style="background: #FFF3E0; border-left: 4px solid #FF9800; padding: 16px; margin: 16px 0;">
                    <p style="margin: 0;"><strong>⚠️ Important:</strong> Please change your password after your first login for security.</p>
                  </div>

                  <h3>Your Tenancy Details:</h3>
                  <ul>
                    <li><strong>Property:</strong> $propertyName</li>
                    <li><strong>Unit:</strong> ${widget.unitName}</li>
                    <li><strong>Lease Start:</strong> ${_leaseStart.day}/${_leaseStart.month}/${_leaseStart.year}</li>
                  </ul>

                  <p>Through the E-Kodi portal you can:</p>
                  <ul>
                    <li>💳 Pay rent via M-Pesa</li>
                    <li>📋 View and pay utility bills</li>
                    <li>📊 Track your payment history</li>
                    <li>💬 Send messages to your landlord</li>
                  </ul>
                </div>
                <div style="padding: 16px; text-align: center; color: #999; font-size: 12px;">
                  <p>This is an automated message from E-Kodi Property Management System.</p>
                </div>
              </div>
            ''',
          },
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (emailError) {
        debugPrint('Welcome email failed: $emailError');
      }

      if (!mounted) return;

      // 7️⃣ Show success dialog with credentials
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Tenant Onboarded!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_nameController.text.trim()} has been assigned to ${widget.unitName}.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withAlpha(80)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '✅ Welcome email sent to:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(_emailController.text.trim()),
                    const SizedBox(height: 12),
                    const Text(
                      '🔑 Login Credentials:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('Email: ${_emailController.text.trim()}'),
                    Text('Password: $defaultPassword'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );

      if (mounted) context.go('/properties/${widget.propertyId}');
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
                          ? Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            )
                          : Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Card(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tenant Registration Info',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'CRITICAL: Ensure the phone number accurately matches '
                        "the tenant's active M-Pesa number.",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
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
                      const SizedBox(height: 16),

                      // Email (full width — used for login)
                      _buildEmailField(),
                      const SizedBox(height: 16),

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

                      // Lease date
                      const Text(
                        'Lease Dates',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Lease Start Date'),
                        subtitle: Text(
                          '${_leaseStart.day}/${_leaseStart.month}/${_leaseStart.year}',
                        ),
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
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.check_circle),
                    label: Text(
                      _isLoading
                          ? 'Processing...'
                          : 'Onboard Tenant & Start Lease',
                    ),
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
      labelText: 'M-Pesa Number',
      hintText: '07XX XXX XXX',
      prefixIcon: Icon(Icons.phone),
    ),
    keyboardType: TextInputType.phone,
    validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
  );

  // ✅ New email field
  Widget _buildEmailField() => TextFormField(
    controller: _emailController,
    decoration: const InputDecoration(
      labelText: 'Email Address (used for tenant login)',
      hintText: 'e.g. jane@gmail.com',
      prefixIcon: Icon(Icons.email),
    ),
    keyboardType: TextInputType.emailAddress,
    validator: (v) {
      if (v == null || v.isEmpty) return 'Required field';
      if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
        return 'Enter a valid email address';
      }
      return null;
    },
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
