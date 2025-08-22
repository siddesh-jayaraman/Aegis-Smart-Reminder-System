import 'package:aegis_smart_medicine_reminder_system/feature/auth/pages/login_page.dart';
import 'package:aegis_smart_medicine_reminder_system/core/theme/app_theme.dart';
import 'package:aegis_smart_medicine_reminder_system/core/services/notification_service.dart';
import 'package:aegis_smart_medicine_reminder_system/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Initialize theme settings
  await AppTheme.loadSettings();

  // Initialize notification service
  await NotificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aegis - Smart Medicine Reminder',
      debugShowCheckedModeBanner: false, // Remove debug banner
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        fontFamily: 'CalSans',
      ),
      home: const LoginPage(),
    );
  }
}
