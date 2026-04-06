import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Central authentication service wrapping Firebase Auth
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Current user (null if not signed in)
  User? get currentUser => _auth.currentUser;

  /// Whether a user is currently signed in
  bool get isSignedIn => _auth.currentUser != null;

  /// Stream of auth state changes (login/logout)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// UID of the current user
  String get uid => _auth.currentUser?.uid ?? '';

  /// Display name of the current user
  String get displayName =>
      _auth.currentUser?.displayName ??
      _auth.currentUser?.email?.split('@').first ??
      'User';

  /// Email of the current user
  String get email => _auth.currentUser?.email ?? '';

  /// Sign up with email, password, and display name
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Set the display name
    await credential.user?.updateDisplayName(displayName);
    await credential.user?.reload();

    // Save user profile to Firestore
    if (credential.user != null) {
      await _saveUserProfile(
        uid: credential.user!.uid,
        displayName: displayName,
        email: email,
      );
    }

    return credential;
  }

  /// Sign in with email and password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Ensure user profile exists in Firestore (in case of legacy account)
    if (credential.user != null) {
      final doc =
          await _db.collection('users').doc(credential.user!.uid).get();
      if (!doc.exists) {
        await _saveUserProfile(
          uid: credential.user!.uid,
          displayName: credential.user!.displayName ??
              email.split('@').first,
          email: email,
        );
      }
    }

    return credential;
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Update display name (both Auth and Firestore)
  Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name);
    await _auth.currentUser?.reload();
    // Also update Firestore profile
    if (_auth.currentUser != null) {
      await _db.collection('users').doc(_auth.currentUser!.uid).update({
        'displayName': name,
      });
    }
  }

  /// Save user profile to Firestore users collection
  Future<void> _saveUserProfile({
    required String uid,
    required String displayName,
    required String email,
  }) async {
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'displayName': displayName,
      'email': email.toLowerCase(),
    });
  }
}
