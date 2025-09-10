// lib/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// You can get this instance from main.dart if you prefer, but a new one is fine.
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

/// Shows a high-priority notification using the 'lifeband_alerts' channel.
Future<void> showHighPriorityNotification(String title, String body) async {
  const AndroidNotificationDetails androidNotificationDetails =
  AndroidNotificationDetails(
    // IMPORTANT: This ID must match the alertChannel ID in main.dart
    'lifeband_alerts',
    'LifeBand Alerts',
    channelDescription: 'Channel for critical LifeBand alerts.',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
  );

  const NotificationDetails notificationDetails =
  NotificationDetails(android: androidNotificationDetails);

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title,
    body,
    notificationDetails,
  );
}