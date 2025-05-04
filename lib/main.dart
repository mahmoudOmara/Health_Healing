import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:health_healing/firebase_options.dart'; // Ensure this import is correct
import 'package:health_healing/theme/theme.dart';
// import 'package:health_healing/screens/auth_wrapper.dart'; // Keep commented for now

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    print('Attempting Firebase initialization...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully.');
  } catch (e) {
    print('!!!!!!!!!!!!!! Firebase Initialization Error !!!!!!!!!!!!!!');
    print(e);
    // Optionally, display an error screen instead of running the app
    // runApp(ErrorScreen(error: e.toString()));
    // return;
  }

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
      // Temporarily replace AuthWrapper with a simple Scaffold
      home: const Scaffold(
        body: Center(
          child: Text('MaterialApp Test Screen'),
        ),
      ),
      // home: const AuthWrapper(), // Original home
    );
  }
}

