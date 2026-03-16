import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/property_model.dart';
import '../../../core/models/unit_model.dart';
import '../../../core/providers/firebase_providers.dart';

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  return PropertyRepository(ref.watch(firestoreProvider));
});

class PropertyRepository {
  final FirebaseFirestore _firestore;

  PropertyRepository(this._firestore);

  // Get properties specifically for the logged in landlord
  Stream<List<PropertyModel>> watchLandlordProperties(String landlordId) {
    return _firestore
        .collection('properties')
        .where('landlordId', isEqualTo: landlordId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PropertyModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Create a new Property Block
  Future<void> createProperty(PropertyModel property) async {
    await _firestore
        .collection('properties')
        .doc(property.id)
        .set(property.toMap());
  }

  // Get units attached to a specific property block
  Stream<List<UnitModel>> watchPropertyUnits(String propertyId) {
    return _firestore
        .collection('units')
        .where('propertyId', isEqualTo: propertyId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UnitModel.fromMap(doc.data(), doc.id))
            .toList());
  }
  
  // Create / Batch Generate multiple units at once
  Future<void> createUnits(List<UnitModel> units) async {
    final batch = _firestore.batch();
    for (var unit in units) {
      final docRef = _firestore.collection('units').doc(unit.id);
      batch.set(docRef, unit.toMap());
    }
    await batch.commit();
  }

  // Update Unit Status (usually triggered when a tenant is assigned)
  Future<void> updateUnitOccupancy(String unitId, String? tenantId, bool isOccupied) async {
    await _firestore.collection('units').doc(unitId).update({
      'currentTenantId': tenantId,
      'isOccupied': isOccupied,
    });
  }
}
