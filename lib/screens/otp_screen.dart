import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health_healing/services/auth_service.dart'; // Import AuthService
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuthException
import 'package:health_healing/services/user_service.dart'; // Import UserService

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId; // Receive verificationId from LoginScreen
  // final int? resendToken; // Optional: For resending OTP

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    // this.resendToken,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final AuthService _authService = AuthService();
  final UserService _userService = UserService(); // Instantiate UserService

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final String smsCode = _otpController.text.trim();

      try {
        print('Attempting to verify OTP: $smsCode for ${widget.phoneNumber}');
        UserCredential? userCredential = await _authService.signInWithCredential(
          widget.verificationId,
          smsCode,
        );

        if (userCredential?.user != null) {
          print('OTP Verification Successful for user: ${userCredential!.user!.uid}');
          // Create user document in Firestore if it doesn't exist
          await _userService.createUserDocumentIfNotExists(userCredential.user!);
          // AuthWrapper will handle navigation to MainScreen
        } else {
          // Handle case where sign-in returns null (should not happen if no exception)
          throw Exception('Sign in returned null user credential.');
        }

      } on FirebaseAuthException catch (e) {
        // Handle specific Firebase errors (e.g., invalid-verification-code)
        String errorMessage = 'Failed to verify OTP.';
        if (e.code == 'invalid-verification-code') {
          errorMessage = 'Invalid OTP code. Please try again.';
        } else if (e.code == 'session-expired') {
           errorMessage = 'The OTP session has expired. Please request a new OTP.';
        }
        // Add more specific error handling as needed

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
        print('Error verifying OTP: ${e.code} - ${e.message}');
      } catch (e) {
        // Handle other generic errors
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('An unexpected error occurred: ${e.toString()}')),
          );
        }
        print('Generic error verifying OTP: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // TODO: Implement Resend OTP functionality using verificationId and resendToken if available
  Future<void> _resendOtp() async {
    setState(() { _isLoading = true; });
    print('Resending OTP to: ${widget.phoneNumber}');
    try {
      // Need to call verifyPhoneNumber again, potentially with resendToken
      await _authService.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        context: context, // Context might not be ideal here, consider alternative feedback
        // forceResendingToken: widget.resendToken, // Pass resend token if available
        codeSent: (String verificationId, int? resendToken) {
          // Update verificationId and potentially resendToken if needed
          // Inform user code was resent
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('New OTP Sent Successfully')),
             );
           }
           print('New OTP sent. New verification ID: $verificationId');
           // Potentially update state with new verificationId/resendToken if UI needs it
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to resend OTP: ${e.message ?? 'Unknown error'}')),
            );
          }
        },
        verificationCompleted: (PhoneAuthCredential credential) {
          // Handle auto-retrieval on resend
          print('Verification Completed Automatically on Resend');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('Resend code auto retrieval timeout');
        },
      );

    } catch (e) {
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to resend OTP: ${e.toString()}')),
          );
        }
    } finally {
       if (mounted) {
          setState(() { _isLoading = false; });
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter OTP'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Enter the 6-digit code sent to',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.phoneNumber,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _otpController,
                    decoration: const InputDecoration(
                      labelText: 'OTP Code',
                      hintText: 'Enter 6-digit code',
                      counterText: "",
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, letterSpacing: 8),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the OTP';
                      }
                      if (value.length != 6) {
                        return 'OTP must be 6 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _verifyOtp,
                          child: const Text('Verify OTP'),
                        ),
                  const SizedBox(height: 16),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: _isLoading ? null : _resendOtp,
                    child: const Text('Resend OTP'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

