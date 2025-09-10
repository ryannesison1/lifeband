import 'dart:async';
import 'dart:developer';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_service.dart';

/// The entry point for the background service on all platforms.
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Standard plugin initialization for the background isolate.
  DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp();

  // --- Complete Notification Setup Within the Isolate ---
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // 1. Initialize the plugin for this isolate.
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(android: initializationSettingsAndroid),
  );

  // 2. Create ALL notification channels this service might use.
  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();

  // Channel for the foreground service's persistent notification.
  const AndroidNotificationChannel serviceChannel = AndroidNotificationChannel(
    'lifeband_service', // Must match the ID in initializeService
    'LifeBand Background Service',
    description: 'Keeps LifeBand running in the background.',
    importance: Importance.low,
  );

  // Channel for high-priority alerts from Firebase.
  const AndroidNotificationChannel alertChannel = AndroidNotificationChannel(
    'lifeband_alerts', // Must match the ID used in notification_service.dart
    'LifeBand Alerts',
    description: 'Channel for critical LifeBand alerts.',
    importance: Importance.max,
  );

  await androidPlugin?.createNotificationChannel(serviceChannel);
  await androidPlugin?.createNotificationChannel(alertChannel);

  // 3. Promote the service to the foreground now that setup is complete.
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  // Listen for a 'stopService' event from the UI to terminate the service.
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // --- Firebase Realtime Database Listener ---
  // This will now work correctly.
  final DatabaseReference databaseReference =
  FirebaseDatabase.instance.ref('users/esp32_device_01/alerts');

  databaseReference.onValue.listen((event) {
    log('BACKGROUND: Alert data changed!');
    final data = event.snapshot.value;
    if (data is Map) {
      final title = data['type'] as String? ?? 'New Alert';
      final body =
          'Value: ${data['value']} - ${data['details'] as String? ?? 'Check the app.'}';

      // This function can now successfully show a notification
      // because the 'lifeband_alerts' channel was created above.
      showHighPriorityNotification(title.replaceAll('_', ' ').toUpperCase(), body);
    }
  });
}

/// A specific entry point required for older iOS versions.
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}

/// Configures and initializes the background service from the main UI isolate.
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      // Start as a background service; it will promote itself.
      isForegroundMode: false,
      notificationChannelId: 'lifeband_service',
      initialNotificationTitle: 'LifeBand Active',
      initialNotificationContent: 'Monitoring device status.',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
  service.startService();
}

