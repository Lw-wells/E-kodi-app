import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
final authProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

// Provider to get current landlord's ID easily across the app
final currentLandlordIdProvider = Provider<String?>((ref) {
  // Mock logic until Firebase Auth is hooked up exactly. 
  // Normally this would be: return ref.watch(authProvider).currentUser?.uid;
  return "demo_landlord_123"; 
});
