import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // معرف العميل الخاص بوظيفة Web Client ID من الفايربيز
  static const String _webClientId =
      '776332381264-q04sv4v65thtmmca4gp7upfupf8lvpgt.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId: _webClientId,
  );

  // هل المستخدم ضيف
  bool get isGuest => _auth.currentUser == null;

  // تسجيل الدخول باستخدام Google
  Future<User?> signInWithGoogle() async {
    try {
      // تفريغ الجلسة السابقة لضمان ظهور شاشة الحسابات
      await _googleSignIn.signOut().catchError((_) => null);

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // المستخدم ألغى خيار الحسابات
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

  // تسجيل الخروج
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}
