import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_healing/screens/login_screen.dart';
import 'package:health_healing/screens/main_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to authentication state changes
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Handle potential errors (optional: show an error screen)
        if (snapshot.hasError) {
          // Consider logging the error
          // print("AuthWrapper Error: ${snapshot.error}");
          return const Scaffold(
            body: Center(
              child: Text("Error loading authentication state."),
            ),
          );
        }

        // If user is logged in, show MainScreen
        if (snapshot.hasData && snapshot.data != null) {
          // TODO: Check if user profile exists in Firestore, if not, navigate to ProfileSetupScreen
          return const MainScreen();
        }

        // If user is not logged in, show LoginScreen
        return const LoginScreen();
      },
    );
  }
}

