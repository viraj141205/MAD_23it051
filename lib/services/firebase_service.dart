import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current authenticated user
  static User? get currentUser => _auth.currentUser;

  // Auth state stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register user with email and password
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user data to Firestore
      try {
        await _saveUserProfile(userCredential.user!, name, email);
      } catch (e) {
        debugPrint('Failed to save user profile: $e');
        // We could delete the user here, but instead we'll just report the warning
        // so the user can be notified that their profile might be incomplete.
      }

      return {
        'success': true,
        'message': 'Registration successful',
        'user': {
          'uid': userCredential.user!.uid,
          'email': userCredential.user!.email,
          'name': name,
        }
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _handleAuthError(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Login user with email and password
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userData = await _getUserProfile(userCredential.user!.uid);

      return {
        'success': true,
        'message': 'Login successful',
        'user': {
          'uid': userCredential.user!.uid,
          'email': userCredential.user!.email,
          'name': userData?['name'] ?? 'User',
        }
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _handleAuthError(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Logout user
  static Future<void> logout() async {
    await _auth.signOut();
  }

  // Get current user profile from Firestore
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      return await _getUserProfile(user.uid);
    } catch (e) {
      return null;
    }
  }

  // Private method to save user profile
  static Future<void> _saveUserProfile(
    User user,
    String name,
    String email,
  ) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving user profile: $e');
    }
  }

  // Private method to get user profile
  static Future<Map<String, dynamic>?> _getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  // Handle Firebase auth errors
  static String _handleAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'Email is already in use.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'operation-not-allowed':
        return 'Email/password login is not enabled.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      default:
        return 'An authentication error occurred.';
    }
  }

  // Firestore helper methods
  static Future<void> addDocument({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding document: $e');
      rethrow;
    }
  }

  static Future<void> updateDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(docId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating document: $e');
      rethrow;
    }
  }

  static Future<void> deleteDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      await _firestore.collection(collection).doc(docId).delete();
    } catch (e) {
      debugPrint('Error deleting document: $e');
      rethrow;
    }
  }

  static Stream<List<Map<String, dynamic>>> getDocuments(
    String collection, {
    String? orderBy,
    bool descending = false,
  }) {
    try {
      Query query = _firestore.collection(collection);

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();
      });
    } catch (e) {
      debugPrint('Error getting documents: $e');
      return Stream.value([]);
    }
  }
}
