import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Current user ───────────────────────────────────────────────────────────
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Get user role from Firestore ───────────────────────────────────────────
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) return doc.data()?['role'] as String?;
      return null;
    } catch (e) {
      return null;
    }
  }

  // ── Landlord login ─────────────────────────────────────────────────────────
  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ── Landlord register ──────────────────────────────────────────────────────
  Future<UserCredential> registerLandlord({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Write landlord role to Firestore
    await _db.collection('users').doc(credential.user!.uid).set({
      'uid': credential.user!.uid,
      'email': email,
      'name': name,
      'role': 'landlord',
      'phone': phone,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return credential;
  }

  // ── Create tenant account (called during onboarding) ──────────────────────
  // Future<String> createTenantAccount({
  //   required String email,
  //   required String phone,
  //   required String name,
  //   required String tenantId,
  //   required String unitId,
  //   required String unitName,
  //   required String propertyId,
  //   required String propertyName,
  // }) async {
  //   // Use a secondary app instance to avoid logging out the landlord
  //   // final tempApp = await FirebaseAuth.instance.app.options.asMap().isEmpty
  //   //     ? null
  //   //     : null;

  //   // Generate a default password from phone number
  //   final defaultPassword = 'Ekodi@${phone.replaceAll(' ', '')}';

  //   try {
  //     // Create auth account
  //     final credential = await FirebaseAuth.instance
  //         .createUserWithEmailAndPassword(
  //       email: email,
  //       password: defaultPassword,
  //     );

  //     // Write tenant role to users collection
  //     await _db.collection('users').doc(credential.user!.uid).set({
  //       'uid':          credential.user!.uid,
  //       'email':        email,
  //       'name':         name,
  //       'role':         'tenant',
  //       'tenantId':     tenantId,
  //       'unitId':       unitId,
  //       'unitName':     unitName,
  //       'propertyId':   propertyId,
  //       'propertyName': propertyName,
  //       'createdAt':    FieldValue.serverTimestamp(),
  //     });

  //     return credential.user!.uid;
  //   } catch (e) {
  //     rethrow;
  //   }
  // }
  Future<String> createTenantAccount({
    required String email,
    required String phone,
    required String name,
    required String tenantId,
    required String unitId,
    required String unitName,
    required String propertyId,
    required String propertyName,
  }) async {
    final defaultPassword = 'Ekodi@${phone.replaceAll(' ', '')}';

    try {
      // ✅ Use Cloud Function — doesn't affect landlord's session
      final callable = FirebaseFunctions.instance.httpsCallable(
        'createTenantAuthAccount',
      );

      final result = await callable.call({
        'email': email,
        'password': defaultPassword,
        'name': name,
        'phone': phone,
        'tenantId': tenantId,
        'unitId': unitId,
        'unitName': unitName,
        'propertyId': propertyId,
        'propertyName': propertyName,
      });

      return result.data['uid'] as String;
    } catch (e) {
      rethrow;
    }
  }

  // ── Sign out ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
  }
}








































// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   // Get current user
//   User? get currentUser => _auth.currentUser;

//   // Get user stream
//   Stream<User?> get user => _auth.authStateChanges();

//   // Register with email and password
//   Future<UserCredential?> registerWithEmail({
//     required String email,
//     required String password,
//     required String fullName,
//     required String phone,
//   }) async {
//     try {
//       // Create user
//       UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
//         email: email.trim(),
//         password: password,
//       );

//       // Update profile
//       await userCredential.user?.updateDisplayName(fullName);
//       await userCredential.user?.reload();

//       // Save to Firestore
//       await _firestore.collection('users').doc(userCredential.user!.uid).set({
//         'fullName': fullName,
//         'email': email.toLowerCase().trim(),
//         'phone': phone,
//         'role': 'landlord',
//         'createdAt': FieldValue.serverTimestamp(),
//         'updatedAt': FieldValue.serverTimestamp(),
//         'isActive': true,
//         'emailVerified': false,
//       });

//       // Send verification email
//       await userCredential.user?.sendEmailVerification();

//       return userCredential;
//     } on FirebaseAuthException catch (e) {
//       throw _handleAuthException(e);
//     } catch (e) {
//       throw Exception('Registration failed: $e');
//     }
//   }

//   // Login with email and password
//   Future<UserCredential> loginWithEmail({
//     required String email,
//     required String password,
//   }) async {
//     try {
//       return await _auth.signInWithEmailAndPassword(
//         email: email.trim(),
//         password: password,
//       );
//     } on FirebaseAuthException catch (e) {
//       throw _handleAuthException(e);
//     }
//   }

//   // Sign out
//   Future<void> signOut() async {
//     await _auth.signOut();
//   }

//   // Handle Firebase Auth exceptions
//   String _handleAuthException(FirebaseAuthException e) {
//     switch (e.code) {
//       case 'email-already-in-use':
//         return 'This email is already registered. Please login instead.';
//       case 'invalid-email':
//         return 'Please enter a valid email address.';
//       case 'operation-not-allowed':
//         return 'Email/password registration is currently disabled.';
//       case 'weak-password':
//         return 'Password should be at least 6 characters.';
//       case 'user-not-found':
//         return 'No user found with this email.';
//       case 'wrong-password':
//         return 'Incorrect password.';
//       case 'invalid-credential':
//         return 'Invalid login credentials.';
//       default:
//         return 'Authentication failed: ${e.message}';
//     }
//   }

//   // Check if user is logged in
//   bool get isLoggedIn => _auth.currentUser != null;

//   // Get user role from Firestore
//   Future<String?> getUserRole(String uid) async {
//     try {
//       DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
//       return doc.get('role');
//     } catch (e) {
//       return null;
//     }
//   }
// }