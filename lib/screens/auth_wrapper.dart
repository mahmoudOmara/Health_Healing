import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Keep for potential future use
import 'package:health_healing/screens/login_screen.dart';
import 'package:health_healing/screens/main_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    print("AuthWrapper: Building...");
    print("AuthWrapper: Bypassing StreamBuilder, directly returning MainScreen for debugging.");

    // --- Temporarily bypass StreamBuilder for debugging navigation ---
    // Check if a user is currently logged in synchronously (less ideal, but for testing)
    if (FirebaseAuth.instance.currentUser != null) {
       print("AuthWrapper: Current user exists, returning MainScreen.");
       return const MainScreen();
    } else {
       print("AuthWrapper: No current user, returning LoginScreen.");
       return const LoginScreen(); // Fallback if no user on initial build
    }

    /* --- Original StreamBuilder Code ---
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        print("AuthWrapper StreamBuilder: ConnectionState = ${snapshot.connectionState}");

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
          return const Scaffold(
            body: Center(
              child: Text("Error loading authentication state."),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          print("AuthWrapper StreamBuilder: User is logged in (UID: ${snapshot.data!.uid}). Returning MainScreen.");
          return const MainScreen();
        }

        print("AuthWrapper StreamBuilder: User is not logged in. Returning LoginScreen.");
        return const LoginScreen();
      },
    );
    */
  }
}

