import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:health_healing/screens/otp_screen.dart'; // For navigation on codeSent

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Phone Authentication ---

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required BuildContext context, // Needed for navigation
    required Function(String verificationId, int? resendToken) codeSent,
    required Function(FirebaseAuthException e) verificationFailed,
    required Function(PhoneAuthCredential credential) verificationCompleted,
    required Function(String verificationId) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted, // Auto-retrieval or instant verification
      verificationFailed: verificationFailed, // Handle errors like invalid phone number
      codeSent: codeSent, // Handle when code is sent to the device
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout, // Handle auto-retrieval timeout
      timeout: const Duration(seconds: 60), // Timeout duration
      // forceResendingToken: resendToken, // TODO: Add resendToken parameter if implementing resend
    );
  }

  Future<UserCredential?> signInWithCredential(String verificationId, String smsCode) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle specific errors like invalid OTP
      print("Error signing in with credential: ${e.code} - ${e.message}");
      rethrow; // Rethrow to be caught in the UI layer
    } catch (e) {
      print("Generic error signing in with credential: $e");
      rethrow;
    }
  }

  // --- Auth State --- 

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // --- Sign Out ---

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

