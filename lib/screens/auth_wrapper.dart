import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_healing/screens/login_screen.dart'; // To be created
import 'package:health_healing/screens/main_screen.dart';
import 'package:provider/provider.dart'; // Will add provider later if needed for state management

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Using StreamBuilder to listen to authentication state changes
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is logged in, show MainScreen
        if (snapshot.hasData && snapshot.data != null) {
          // TODO: Check if user profile exists in Firestore, if not, navigate to ProfileSetupScreen
          return const MainScreen();
        }

        // If user is not logged in, show LoginScreen
        return const LoginScreen(); // To be created
      },
    );
  }
}

