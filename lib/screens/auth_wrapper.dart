import 'package:flutter/material.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Temporarily replaced StreamBuilder with a simple placeholder
    // to isolate the runtime issue.
    return const Scaffold(
      body: Center(
        child: Text('AuthWrapper Placeholder'),
      ),
    );

    /* Original code:
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          // User is logged in
          return const MainScreen(); // Navigate to the main app screen
        } else {
          // User is not logged in
          return const LoginScreen(); // Navigate to the login screen
        }
      },
    );
    */
  }
}

// We might need these imports later when restoring
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:health_healing/services/auth_service.dart';
// import 'package:health_healing/screens/main_screen.dart';
// import 'package:health_healing/screens/login_screen.dart';

