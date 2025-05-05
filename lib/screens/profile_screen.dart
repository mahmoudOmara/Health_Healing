import 'package:flutter/material.dart';
import 'package:health_healing/services/auth_service.dart'; // Import AuthService

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print("ProfileScreen: Building..."); // Add log
    final AuthService authService = AuthService(); // Get instance of AuthService

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Profile Screen Content'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                print("Sign Out button pressed");
                try {
                  await authService.signOut();
                  print("Sign out successful, AuthWrapper should handle navigation.");
                  // No explicit navigation needed here, AuthWrapper handles it.
                } catch (e) {
                  print("Error signing out: $e");
                  // Optionally show a snackbar or dialog on error
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error signing out: $e")),
                  );
                }
              },
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}

