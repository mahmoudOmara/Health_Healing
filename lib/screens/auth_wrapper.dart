import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_healing/screens/login_screen.dart';
import 'package:health_healing/screens/main_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    print("AuthWrapper: Building...");
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        // More detailed initial logging
        print("AuthWrapper StreamBuilder: START");
        print("  ConnectionState: ${snapshot.connectionState}");
        print("  HasData: ${snapshot.hasData}");
        print("  Data: ${snapshot.data}"); // Log the actual user object or null
        print("  HasError: ${snapshot.hasError}");
        if (snapshot.hasError) {
          print("  Error: ${snapshot.error}");
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          print("AuthWrapper StreamBuilder: State is waiting...");
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // This check needs to be robust
        if (snapshot.hasData && snapshot.data != null) {
          // Check if user object is valid (e.g., UID is not empty)
          // Although Firebase Auth usually handles this, adding extra checks for debugging
          final user = snapshot.data!;
          print("AuthWrapper StreamBuilder: User data received (UID: ${user.uid}). Returning MainScreen.");
          return const MainScreen();
        } else {
          // This case should cover !snapshot.hasData or snapshot.data == null
          print("AuthWrapper StreamBuilder: No valid user data found. Returning LoginScreen.");
          return const LoginScreen();
        }
      },
    );
  }
}

