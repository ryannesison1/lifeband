import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
// CORRECTED: Import the main background service package.
import 'package:flutter_background_service/flutter_background_service.dart';

import '../models/notification_message.dart';
import '../services/notification_service.dart';

// NOTE: This file is only used for testing notifications and is not part
// of the main Auth/Dashboard flow of the app.
class NotificationHomePage extends StatefulWidget {
  const NotificationHomePage({super.key});

  @override
  State<NotificationHomePage> createState() => _NotificationHomePageState();
}

class _NotificationHomePageState extends State<NotificationHomePage> {
  final List<NotificationMessage> _receivedNotifications = [];
  // You need a reference to the notification plugin to request permissions.
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _requestNotificationPermissions();

    // Listen for 'update' events sent from the background service via service.invoke('update', ...);
    FlutterBackgroundService().on('update').listen((event) {
      if (event != null) {
        final message = NotificationMessage(
          title: event['title'],
          body: event['body'],
        );
        if (mounted) {
          setState(() {
            _receivedNotifications.insert(0, message);
          });
        }
      }
    });
  }

  /// Requests notification permissions (needed for Android 13+)
  Future<void> _requestNotificationPermissions() async {
    final androidImpl =
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
  }

  /// Pushes a new test notification into Firebase Realtime Database
  Future<void> _sendTestNotification() async {
    try {
      final DatabaseReference databaseReference =
      FirebaseDatabase.instance.ref('notifications');
      await databaseReference.push().set({
        'title': 'Test From App',
        'body':
        'Test sent at ${DateFormat.yMd().add_Hms().format(DateTime.now())}',
        'timestamp': ServerValue.timestamp,
      });
      log('Test data sent successfully.');
    } catch (e) {
      log('Error sending data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending test notification: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Realtime DB Notifier'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Icon(Icons.sync, size: 60, color: Colors.teal),
            const SizedBox(height: 8),
            const Text(
              'A background service is listening for database changes.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'RECEIVED NOTIFICATIONS',
              textAlign: TextAlign.center,
              style:
              TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Card(
                elevation: 4,
                child: _receivedNotifications.isEmpty
                    ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Add data to the "alerts" node in Firebase to see notifications here.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
                    : ListView.builder(
                  itemCount: _receivedNotifications.length,
                  itemBuilder: (context, index) {
                    final notification = _receivedNotifications[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal.shade300,
                        child: const Icon(Icons.message,
                            color: Colors.white),
                      ),
                      title: Text(notification.title),
                      subtitle: Text(notification.body),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Send Test Notification'),
              style: ElevatedButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: _sendTestNotification,
            ),
          ],
        ),
      ),
    );
  }
}
