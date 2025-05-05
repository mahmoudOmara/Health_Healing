import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health_healing/screens/otp_screen.dart';
import 'package:health_healing/services/auth_service.dart'; // Import AuthService
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuthException

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _selectedCountryCode = "+20"; // Default country code set to Egypt
  final AuthService _authService = AuthService(); // Instantiate AuthService

  // TODO: Replace with a better country code picker if needed
  final List<String> _countryCodes = ['+1', '+44', '+91', '+20']; // Example codes

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final String phoneNumber = _selectedCountryCode + _phoneController.text.trim();

      try {
        print('Attempting to send OTP to: $phoneNumber');
        await _authService.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          context: context,
          codeSent: (String verificationId, int? resendToken) {
            // Navigate to OTP screen when code is sent
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OtpScreen(
                    phoneNumber: phoneNumber,
                    verificationId: verificationId, // Pass verificationId
                    // resendToken: resendToken, // Pass resendToken if needed for resend functionality
                  ),
                ),
              );
            }
             if (mounted) {
              setState(() {
                _isLoading = false; // Stop loading indicator after navigation
              });
            }
          },
          verificationFailed: (FirebaseAuthException e) {
            // Handle verification failure
            print('Verification Failed: ${e.code} - ${e.message}');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to send OTP: ${e.message ?? 'Unknown error'}')),
              );
              setState(() {
                _isLoading = false;
              });
            }
          },
          verificationCompleted: (PhoneAuthCredential credential) async {
            // Handle auto-retrieval or instant verification (less common)
            print('Verification Completed Automatically');
            // Optionally sign in the user directly
            // await _authService.signInWithCredential(credential); 
            // AuthWrapper will handle navigation
             if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            // Handle timeout (e.g., show a message)
            print('Code auto retrieval timeout');
            // You might want to keep the verificationId for manual entry
             if (mounted) {
              // Optionally inform the user or update UI
              // setState(() { _isLoading = false; }); // Decide if loading stops here
            }
          },
        );

      } catch (e) {
        // Catch any other unexpected errors during the initiation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('An unexpected error occurred: ${e.toString()}')),
          );
           setState(() {
             _isLoading = false;
           });
        }
        print('Error initiating phone verification: $e');
      }
      // Note: _isLoading is set to false within the callbacks (codeSent, verificationFailed, etc.)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    'Welcome to Health Healing',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your phone number to continue',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButton<String>(
                        value: _selectedCountryCode,
                        items: _countryCodes.map((String code) {
                          return DropdownMenuItem<String>(
                            value: code,
                            child: Text(code),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCountryCode = newValue!;
                          });
                        },
                        underline: Container(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            hintText: 'e.g., 5551234567',
                          ),
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            if (value.length < 7) {
                              return 'Enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _sendOtp,
                          child: const Text('Send OTP'),
                        ),
                  const SizedBox(height: 16),
                  Text(
                    'By continuing, you agree to our Terms of Service and Privacy Policy.',
                    style: Theme.of(context).textTheme.labelSmall,
                    textAlign: TextAlign.center,
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

