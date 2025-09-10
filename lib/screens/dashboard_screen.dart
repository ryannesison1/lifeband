// lib/screens/dashboard_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';

class DashboardScreen extends StatefulWidget {
  final String deviceId;
  const DashboardScreen({super.key, required this.deviceId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DatabaseReference _userRef;
  UserProfile? _userProfile;
  UserStatus? _userStatus;
  final List<HealthData> _healthHistory = [];
  final List<FallEvent> _fallHistory = [];
  final List<Alert> _alerts = [];
  bool _sosActive = false;

  // Use separate subscriptions for more granular and efficient updates
  StreamSubscription? _profileStatusSubscription;
  StreamSubscription? _healthSubscription;
  StreamSubscription? _fallSubscription;
  StreamSubscription? _alertSubscription;

  @override
  void initState() {
    super.initState();
    _userRef = FirebaseDatabase.instance.ref('users/${widget.deviceId}');
    _activateListeners();
  }

  void _activateListeners() {
    // Listener 1: For profile and status, which are single objects and update together.
    _profileStatusSubscription = _userRef.onValue.listen((event) {
      if (!mounted || !event.snapshot.exists) return;
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);

      setState(() {
        if (data['profile'] != null) {
          _userProfile =
              UserProfile.fromMap(Map<String, dynamic>.from(data['profile']));
        }
        if (data['status'] != null) {
          _userStatus =
              UserStatus.fromMap(Map<String, dynamic>.from(data['status']));
          _sosActive = _userStatus?.sosActive ?? false;
        }
      });
    });

    // Listener 2: For Health Data (a single object that gets updated frequently).
    _healthSubscription =
        _userRef.child('details/max30102_data').onValue.listen((event) {
          if (!mounted || !event.snapshot.exists) return;
          final healthData =
          HealthData.fromMap(Map<String, dynamic>.from(event.snapshot.value as Map));

          setState(() {
            // More efficient: insert at the beginning, no need to re-sort the whole list.
            _healthHistory.insert(0, healthData);
            // Optional: Keep the list from growing indefinitely to save memory.
            if (_healthHistory.length > 50) {
              _healthHistory.removeLast();
            }
          });
        });

    // Listener 3: For new Fall Events.
    // Using onChildAdded is the most efficient way to handle lists in Firebase.
    _fallSubscription = _userRef.child('fallHistory').onChildAdded.listen((event) {
      if (!mounted || !event.snapshot.exists) return;
      final fallEvent =
      FallEvent.fromMap(Map<String, dynamic>.from(event.snapshot.value as Map));
      setState(() {
        _fallHistory.insert(0, fallEvent);
      });
    });

    // Listener 4: For Alerts (a single object that gets updated).
    _alertSubscription = _userRef.child('alerts').onValue.listen((event) {
      if (!mounted || !event.snapshot.exists) return;
      final alert =
      Alert.fromMap(Map<String, dynamic>.from(event.snapshot.value as Map));
      setState(() {
        // Avoid adding the same alert multiple times if the node just updates.
        if (_alerts.where((a) => a.timestamp == alert.timestamp).isEmpty) {
          _alerts.insert(0, alert);
        }
      });
    });
  }

  void _clearAlert(int index) {
    // This is a UI-only clear. To clear it from the database, you would use:
    // _userRef.child('alerts').remove();
    // For now, a local clear is fine.
    setState(() {
      _alerts.removeAt(index);
    });
  }

  @override
  void dispose() {
    // Cancel all subscriptions to prevent memory leaks when the widget is removed.
    _profileStatusSubscription?.cancel();
    _healthSubscription?.cancel();
    _fallSubscription?.cancel();
    _alertSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LifeBand Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: _userProfile == null
          ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text("Loading device data..."),
            ],
          ))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StatusCard(
              sosActive: _sosActive,
              lastUpdate: _userStatus?.lastUpdate,
            ),
            const SizedBox(height: 16),
            ProfileCard(userProfile: _userProfile!),
            const SizedBox(height: 16),
            AlertsCard(alerts: _alerts, onClear: _clearAlert),
            const SizedBox(height: 16),
            HealthHistoryCard(healthHistory: _healthHistory),
            const SizedBox(height: 16),
            FallHistoryCard(fallHistory: _fallHistory),
          ],
        ),
      ),
    );
  }
}