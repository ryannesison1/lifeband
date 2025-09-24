// main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'services/background_service.dart'; // This import is necessary
import 'screens/auth_screen.dart';
import 'screens/main_screen.dart';

// Global instance of the notifications plugin.
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> main() async {
  // Ensure Flutter engine is initialized.
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase.
  await Firebase.initializeApp();

  // The order of these calls is critical to prevent the "Bad notification" crash.
  await initializeNotifications(); // 1. Initialize the plugin FIRST.
  await setupNotificationChannels(); // 2. Create channels SECOND.
  await initializeService(); // 3. Start the service LAST.

  runApp(const MyApp());
}

/// Initializes the notification plugin instance with platform settings.
Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

/// Creates ALL necessary notification channels for the app.
Future<void> setupNotificationChannels() async {
  const AndroidNotificationChannel serviceChannel = AndroidNotificationChannel(
    'lifeband_service', // ID for the persistent background service notification
    'LifeBand Background Service',
    description: 'Keeps the app service running in the background.',
    importance: Importance.low, // Low importance to be non-intrusive
  );

  const AndroidNotificationChannel alertChannel = AndroidNotificationChannel(
    'lifeband_alerts', // ID for high-priority alerts from the database
    'LifeBand Alerts',
    description: 'Channel for critical LifeBand alerts.',
    importance: Importance.max, // High importance to alert the user
  );

  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();

  // Create the channels and request permission
  if (androidPlugin != null) {
    await androidPlugin.createNotificationChannel(serviceChannel);
    await androidPlugin.createNotificationChannel(alertChannel);
    await androidPlugin.requestNotificationsPermission();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeBand',
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.grey[100],
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.red,
        ).copyWith(
          secondary: Colors.white,
          error: Colors.redAccent,
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          // Check if a user is logged in
          if (userSnapshot.hasData) {
            final user = userSnapshot.data!;
            // **CRITICAL FIX**: Check if the user's email is verified.
            if (user.emailVerified) {
              // If verified, show the main content.
              return const MainScreen(deviceId: 'esp32_device_01');
            }
          }
          // If there is no user, or the user's email is NOT verified,
          // show the authentication screen.
          return const AuthScreen();
        },
      ),
    );
  }
}