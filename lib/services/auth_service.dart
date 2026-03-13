import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Sign in
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print("Login Error: $e");
      return null;
    }
  }

  // Register
  Future<User?> registerWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // Create a new document for the user with language preference defaults
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'name': name,
          'language': 'en', // Default to English, can change in settings
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      return user;
    } catch (e) {
      print("Registration Error: $e");
      return null;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await NotificationService().deleteToken();
      return await _auth.signOut();
    } catch (e) {
      print("SignOut Error: $e");
    }
  }

  // Check current user state
  Stream<User?> get user {
    return _auth.authStateChanges();
  }
}
