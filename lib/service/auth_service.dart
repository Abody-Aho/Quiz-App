import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Web Client ID from Firebase Console
  static const String _webClientId =
      '776332381264-q04sv4v65thtmmca4gp7upfupf8lvpgt.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId: _webClientId,
  );

  bool get isGuest => _auth.currentUser == null;

  Future<User?> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut().catchError((_) => null);

      GoogleSignInAccount? googleUser;
      try {
        googleUser = await _googleSignIn.signIn();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Google Sign-In with serverClientId failed, trying fallback: $e');
        }
        final fallbackSignIn = GoogleSignIn(scopes: ['email']);
        googleUser = await fallbackSignIn.signIn();
      }

      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      return userCredential.user;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Google Sign-In Exception: $e');
      }
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}
