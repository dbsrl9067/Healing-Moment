import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'firebase_options.dart';
import 'screens/error_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';
import 'services/notification_service.dart';

bool isFirebaseInitialized = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Timezone
  tz.initializeTimeZones();
  try {
    // Attempt to get local timezone
    // Note: In a real app, you might use flutter_timezone package here
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
  } catch (e) {
    debugPrint("Timezone initialization failed: $e");
    tz.setLocalLocation(tz.getLocation('UTC'));
  }
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    isFirebaseInitialized = true;
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
    isFirebaseInitialized = false;
  }

  // Initialize Notifications
  if (isFirebaseInitialized) {
    await NotificationService.initialize();
  }

  runApp(const HealingMomentsApp());
}

class HealingMomentsApp extends StatelessWidget {
  const HealingMomentsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Healing Moments',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0502),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF472B6),
          brightness: Brightness.dark,
          surface: const Color(0xFF1A1512),
        ),
      ),
      home: isFirebaseInitialized ? const AuthWrapper() : const FirebaseErrorScreen(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const MainNavigationScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
