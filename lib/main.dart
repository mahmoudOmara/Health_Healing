import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:health_healing/firebase_options.dart'; // Ensure this import is correct
import 'package:health_healing/theme/theme.dart';
import 'package:health_healing/screens/auth_wrapper.dart'; // Restore this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase initialization confirmed working, removing logs for now
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Healing',
      theme: AppTheme.lightTheme,
      // darkTheme: AppTheme.darkTheme, // Optional: Add dark theme later
      themeMode: ThemeMode.light, // Or ThemeMode.system
      debugShowCheckedModeBanner: false,
      // Restore AuthWrapper (still simplified version) as home
      home: const AuthWrapper(),
    );
  }
}

