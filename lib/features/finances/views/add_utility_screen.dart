import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/widgets/app_layout.dart';
import '../../../config/routes.dart';

class AddUtilityScreen extends StatefulWidget {
  const AddUtilityScreen({super.key});

  @override
  State<AddUtilityScreen> createState() => _AddUtilityScreenState();
}

class _AddUtilityScreenState extends State<AddUtilityScreen> {
  // ── Step state ─────────────────────────────────────────────────────────────
  int _step = 0; // 0: pick property, 1: configure, 2: enter readings/amounts

  // ── Step 1 state ───────────────────────────────────────────────────────────
  String? _selectedPropertyId;
  String? _selectedPropertyName;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _occupiedUnits = [];

  // ── Step 2 state ───────────────────────────────────────────────────────────
  String _utilityType  = 'water';
  String _billingType  = 'fixed';
  int    _selectedMonth = DateTime.now().month;
  int    _selectedYear  = DateTime.now().year;

  // ── Step 3 state ───────────────────────────────────────────────────────────
  // For fixed billing: one controller for all units
  final _fixedAmountController = TextEditingController();

  // For metered billing: per-unit controllers
  // Map<unitId, {prev, curr, rate}>
  final Map<String, TextEditingController> _prevControllers = {};
  final Map<String, TextEditingController> _currControllers = {};
  final Map<String, TextEditingController> _rateControllers = {};

  bool _isSaving = false;

  @override
  void dispose() {
    _fixedAmountController.dispose();
    for (final c in _prevControllers.values) c.dispose();
    for (final c in _currControllers.values) c.dispose();
    for (final c in _rateControllers.values) c.dispose();
    super.dispose();
  }

  // ── Step 1: Load occupied units for selected property ─────────────────────

  Future<void> _loadOccupiedUnits(String propertyId) async {
    final snap = await FirebaseFirestore.instance
        .collection('properties')
        .doc(propertyId)
        .collection('units')
        .where('isOccupied', isEqualTo: true)
        .get();

    setState(() {
      _occupiedUnits = snap.docs;

      // Initialise per-unit controllers for metered billing
      for (final unit in _occupiedUnits) {
        final id = unit.id;
        _prevControllers[id] ??= TextEditingController();
        _currControllers[id] ??= TextEditingController();
        _rateControllers[id] ??= TextEditingController(text: '0');
      }
    });
  }

  // ── Save all bills ─────────────────────────────────────────────────────────

  Future<void> _saveBills() async {
    if (_occupiedUnits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No occupied units found for this property.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final batch     = firestore.batch();

      // 1️⃣ Create parent utility document
      final utilityRef = firestore.collection('utilities').doc();
      batch.set(utilityRef, {
        'propertyId':   _selectedPropertyId,
        'propertyName': _selectedPropertyName,
        'type':         _utilityType,
        'billingType':  _billingType,
        'month':        _selectedMonth,
        'year':         _selectedYear,
        'createdAt':    FieldValue.serverTimestamp(),
      });

      // 2️⃣ Create one bill per occupied unit
      for (final unit in _occupiedUnits) {
        final unitData   = unit.data();
        final unitId     = unit.id;
        final unitName   = unitData['unitName']   as String? ?? 'Unit';
        final tenantId   = unitData['tenantId']   as String? ?? '';
        final tenantName = unitData['tenantName'] as String? ?? 'Tenant';

        double amount = 0;
        Map<String, dynamic> meteredFields = {};

        if (_billingType == 'fixed') {
          amount = double.tryParse(_fixedAmountController.text) ?? 0;
        } else {
          final prev  = double.tryParse(_prevControllers[unitId]?.text ?? '') ?? 0;
          final curr  = double.tryParse(_currControllers[unitId]?.text ?? '') ?? 0;
          final rate  = double.tryParse(_rateControllers[unitId]?.text ?? '') ?? 0;
          final units = (curr - prev).clamp(0, double.infinity);
          amount = units * rate;
          meteredFields = {
            'previousReading': prev,
            'currentReading':  curr,
            'unitsConsumed':   units,
            'ratePerUnit':     rate,
          };
        }

        final billRef = firestore.collection('utility_bills').doc();
        batch.set(billRef, {
          'utilityId':    utilityRef.id,
          'tenantId':     tenantId,
          'tenantName':   tenantName,
          'unitId':       unitId,
          'unitName':     unitName,
          'propertyId':   _selectedPropertyId,
          'propertyName': _selectedPropertyName,
          'type':         _utilityType,
          'billingType':  _billingType,
          'amount':       amount,
          'month':        _selectedMonth,
          'year':         _selectedYear,
          'isPaid':       false,
          'createdAt':    FieldValue.serverTimestamp(),
          ...meteredFields,
        });
      }

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Utility bills created for ${_occupiedUnits.length} units!'),
          backgroundColor: Colors.green,
        ),
      );
      context.go(AppRoutes.finances);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error saving bills: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return AppLayout(
      currentLocation: AppRoutes.finances,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go(AppRoutes.finances),
                ),
                const SizedBox(width: 16),
                Text('Add Utility Bill',
                    style: Theme.of(context).textTheme.headlineMedium),
              ],
            ),
            const SizedBox(height: 24),

            // ── Step indicator ────────────────────────────────────────────
            _buildStepIndicator(),
            const SizedBox(height: 32),

            // ── Step content ──────────────────────────────────────────────
            if (_step == 0) _buildStep1(),
            if (_step == 1) _buildStep2(),
            if (_step == 2) _buildStep3(isMobile),
          ],
        ),
      ),
    );
  }

  // ── Step indicator ─────────────────────────────────────────────────────────

  Widget _buildStepIndicator() {
    final steps = ['Select Property', 'Configure', 'Enter Data'];
    return Row(
      children: List.generate(steps.length, (i) {
        final isActive   = i == _step;
        final isComplete = i < _step;
        return Expanded(
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: isComplete
                    ? Colors.green
                    : isActive
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[700],
                child: isComplete
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text('${i + 1}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(steps[i],
                    style: TextStyle(
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? null : Colors.grey,
                      fontSize: 13,
                    )),
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Divider(
                    color: isComplete ? Colors.green : Colors.grey[700],
                    thickness: 1.5,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  // ── Step 1: Pick property ──────────────────────────────────────────────────

  Widget _buildStep1() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Property',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Choose the property to bill utilities for.',
                style: TextStyle(color: Colors.grey)),
            const Divider(height: 32),

            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('properties')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final properties = snapshot.data?.docs ?? [];

                if (properties.isEmpty) {
                  return const Text(
                      'No properties found. Add a property first.');
                }

                return Column(
                  children: properties.map((doc) {
                    final data     = doc.data();
                    final name     = data['name']     as String? ?? 'Unnamed';
                    final location = data['location'] as String? ?? '';
                    final isSelected = _selectedPropertyId == doc.id;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.business,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey),
                        title: Text(name),
                        subtitle: Text(location),
                        trailing: isSelected
                            ? Icon(Icons.check_circle,
                                color:
                                    Theme.of(context).colorScheme.primary)
                            : null,
                        onTap: () async {
                          setState(() {
                            _selectedPropertyId   = doc.id;
                            _selectedPropertyName = name;
                          });
                          await _loadOccupiedUnits(doc.id);
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: _selectedPropertyId == null
                      ? null
                      : () => setState(() => _step = 1),
                  child: const Text('Next →'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 2: Configure utility ──────────────────────────────────────────────

  Widget _buildStep2() {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Configure Utility',
                style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 32),

            // Utility type
            Text('Utility Type',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [
                _utilityTypeChip('water',       'Water',       Icons.water_drop),
                _utilityTypeChip('electricity', 'Electricity', Icons.bolt),
                _utilityTypeChip('garbage',     'Garbage',     Icons.delete_outline),
                _utilityTypeChip('internet',    'Internet',    Icons.wifi),
              ],
            ),
            const SizedBox(height: 24),

            // Billing type
            Text('Billing Method',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _billingTypeCard(
                    'fixed',
                    'Fixed Charge',
                    'Same amount for all units',
                    Icons.attach_money,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _billingTypeCard(
                    'metered',
                    'Meter Reading',
                    'Based on units consumed',
                    Icons.speed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Billing period
            Text('Billing Period',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedMonth,
                    decoration: const InputDecoration(
                        labelText: 'Month', border: OutlineInputBorder()),
                    items: List.generate(
                      12,
                      (i) => DropdownMenuItem(
                          value: i + 1, child: Text(months[i])),
                    ),
                    onChanged: (v) =>
                        setState(() => _selectedMonth = v ?? _selectedMonth),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedYear,
                    decoration: const InputDecoration(
                        labelText: 'Year', border: OutlineInputBorder()),
                    items: [2024, 2025, 2026, 2027]
                        .map((y) =>
                            DropdownMenuItem(value: y, child: Text('$y')))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedYear = v ?? _selectedYear),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => setState(() => _step = 0),
                  child: const Text('← Back'),
                ),
                ElevatedButton(
                  onPressed: () => setState(() => _step = 2),
                  child: const Text('Next →'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _utilityTypeChip(String value, String label, IconData icon) {
    final isSelected = _utilityType == value;
    return ChoiceChip(
      avatar: Icon(icon,
          size: 16,
          color: isSelected ? Colors.white : Colors.grey),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _utilityType = value),
    );
  }

  Widget _billingTypeCard(
      String value, String title, String subtitle, IconData icon) {
    final isSelected = _billingType == value;
    return GestureDetector(
      onTap: () => setState(() => _billingType = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[700]!,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withAlpha(25)
              : null,
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey),
            const SizedBox(height: 8),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : null)),
            Text(subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ── Step 3: Enter amounts / readings ──────────────────────────────────────

  Widget _buildStep3(bool isMobile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _billingType == 'fixed'
                  ? 'Enter Fixed Amount'
                  : 'Enter Meter Readings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _billingType == 'fixed'
                  ? 'This amount will be applied to all ${_occupiedUnits.length} occupied units.'
                  : 'Enter previous and current readings for each unit.',
              style: const TextStyle(color: Colors.grey),
            ),
            const Divider(height: 32),

            // ── Fixed billing ─────────────────────────────────────────────
            if (_billingType == 'fixed') ...[
              TextFormField(
                controller: _fixedAmountController,
                decoration: const InputDecoration(
                  labelText: 'Amount per Unit (KES)',
                  prefixIcon: Icon(Icons.money),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              // Preview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Total bill: KES ${((double.tryParse(_fixedAmountController.text) ?? 0) * _occupiedUnits.length).toStringAsFixed(0)}'
                  ' across ${_occupiedUnits.length} units',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ],

            // ── Metered billing ───────────────────────────────────────────
            if (_billingType == 'metered')
              ..._occupiedUnits.map((unit) {
                final unitData   = unit.data();
                final unitId     = unit.id;
                final unitName   = unitData['unitName']   as String? ?? 'Unit';
                final tenantName = unitData['tenantName'] as String? ?? 'Tenant';

                final prev = double.tryParse(
                        _prevControllers[unitId]?.text ?? '') ??
                    0;
                final curr = double.tryParse(
                        _currControllers[unitId]?.text ?? '') ??
                    0;
                final rate = double.tryParse(
                        _rateControllers[unitId]?.text ?? '') ??
                    0;
                final consumed = (curr - prev).clamp(0, double.infinity);
                final total    = consumed * rate;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.meeting_room, size: 18),
                            const SizedBox(width: 8),
                            Text('$unitName — $tenantName',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (isMobile) ...[
                          _readingField(
                              'Previous Reading', _prevControllers[unitId]!, unitId),
                          const SizedBox(height: 12),
                          _readingField(
                              'Current Reading', _currControllers[unitId]!, unitId),
                          const SizedBox(height: 12),
                          _readingField(
                              'Rate per Unit (KES)', _rateControllers[unitId]!, unitId),
                        ] else
                          Row(
                            children: [
                              Expanded(child: _readingField(
                                  'Previous Reading', _prevControllers[unitId]!, unitId)),
                              const SizedBox(width: 12),
                              Expanded(child: _readingField(
                                  'Current Reading', _currControllers[unitId]!, unitId)),
                              const SizedBox(width: 12),
                              Expanded(child: _readingField(
                                  'Rate per Unit (KES)', _rateControllers[unitId]!, unitId)),
                            ],
                          ),
                        const SizedBox(height: 12),
                        Text(
                          'Units consumed: ${consumed.toStringAsFixed(1)}  •  '
                          'Bill: KES ${total.toStringAsFixed(0)}',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _isSaving ? null : () => setState(() => _step = 1),
                  child: const Text('← Back'),
                ),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveBills,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving
                      ? 'Saving...'
                      : 'Save Bills for ${_occupiedUnits.length} Units'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _readingField(
      String label, TextEditingController controller, String unitId) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}), // rebuild to update totals
    );
  }
}