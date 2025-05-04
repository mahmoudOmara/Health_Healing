import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_healing/screens/login_screen.dart';
import 'package:health_healing/screens/main_screen.dart';
// import 'package:provider/provider.dart'; // Not used currently

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    print("AuthWrapper: Building..."); // Log when the widget builds
    // Using StreamBuilder to listen to authentication state changes
    // Switched to userChanges() for potentially more reliable updates
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(), // Changed from authStateChanges()
      builder: (context, snapshot) {
        print("AuthWrapper StreamBuilder: ConnectionState = ${snapshot.connectionState}");

        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          print("AuthWrapper StreamBuilder: State is waiting...");
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          print("AuthWrapper StreamBuilder: Error in stream: ${snapshot.error}");
          // Optionally return an error screen
          return const Scaffold(
            body: Center(
              child: Text("Error loading authentication state."),
            ),
          );
        }

        // If user is logged in, show MainScreen
        if (snapshot.hasData && snapshot.data != null) {
          print("AuthWrapper StreamBuilder: User is logged in (UID: ${snapshot.data!.uid}). Returning MainScreen.");
          // TODO: Check if user profile exists in Firestore, if not, navigate to ProfileSetupScreen
          return const MainScreen();
        }

        // If user is not logged in, show LoginScreen
        print("AuthWrapper StreamBuilder: User is not logged in. Returning LoginScreen.");
        return const LoginScreen();
      },
    );
  }
}

