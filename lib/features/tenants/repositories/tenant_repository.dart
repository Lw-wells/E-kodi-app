import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/tenant_model.dart';
import '../../../core/providers/firebase_providers.dart';

final tenantRepositoryProvider = Provider<TenantRepository>((ref) {
  return TenantRepository(ref.watch(firestoreProvider));
});

class TenantRepository {
  final FirebaseFirestore _firestore;

  TenantRepository(this._firestore);

  // Get all active tenants bound to a landlord
  Stream<List<TenantModel>> watchLandlordTenants(String landlordId) {
    return _firestore
        .collection('tenants')
        .where('landlordId', isEqualTo: landlordId)
        .where('isActive', isEqualTo: true) // Filter to active tenants
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TenantModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get single tenant by ID
  Future<TenantModel?> getTenantById(String tenantId) async {
    final doc = await _firestore.collection('tenants').doc(tenantId).get();
    if (doc.exists) {
      return TenantModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // Assign a new tenant (Create Record)
  Future<String> createTenant(TenantModel tenant) async {
    // Scaffold doc ref so we can get its ID cleanly
    final docRef = _firestore.collection('tenants').doc();
    
    // Save to Firestore
    await docRef.set(tenant.copyWith().toMap()); // Assuming model map logic
    return docRef.id;
  }

  // Update Tenant details (e.g. Account Balances after payments)
  Future<void> updateTenantBalance(String tenantId, double newBalance) async {
    await _firestore.collection('tenants').doc(tenantId).update({
      'accountBalance': newBalance,
    });
  }
}
