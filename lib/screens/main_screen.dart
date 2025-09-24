// screens/main_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/models.dart';
import 'profile_screen.dart';
import 'health_status_screen.dart';
import 'fall_alerts_screen.dart';
import 'location_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  final String deviceId;
  const MainScreen({super.key, required this.deviceId});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late List<Widget> _pages;
  late DatabaseReference _userRef;

  // Data state variables
  UserProfile? _userProfile;
  UserStatus? _userStatus;
  GpsData? _gpsData;
  final List<HealthData> _healthHistory = [];
  final List<FallEvent> _fallHistory = [];

  // Stream subscriptions
  StreamSubscription? _profileSubscription;
  StreamSubscription? _statusSubscription;
  StreamSubscription? _gpsSubscription;
  StreamSubscription? _healthSubscription;
  StreamSubscription? _fallSubscription;

  @override
  void initState() {
    super.initState();
    _userRef = FirebaseDatabase.instance.ref('users/${widget.deviceId}');
    _initializePages();
    _activateListeners();
  }

  void _clearFallHistoryUI() {
    setState(() {
      _fallHistory.clear();
      _updatePages();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fall history cleared from view. Data remains in the database.'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _initializePages() {
    _pages = <Widget>[
      ProfileScreen(userProfile: _userProfile, userRef: _userRef),
      HealthStatusScreen(healthHistory: _healthHistory),
      FallAlertsScreen(fallHistory: _fallHistory, userStatus: _userStatus, onClearHistory: _clearFallHistoryUI),
      LocationScreen(gpsData: _gpsData),
      const SettingsScreen(),
    ];
  }

  void _activateListeners() {
    _profileSubscription = _userRef.child('profile').onValue.listen((event) {
      if (mounted && event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          _userProfile = UserProfile.fromMap(data);
          _updatePages();
        });
      }
    });

    // MODIFIED: Changed listener path from 'status' to 'details/sos'
    _statusSubscription = _userRef.child('details/sos').onValue.listen((event) {
      if (mounted && event.snapshot.exists) {
        setState(() {
          _userStatus = UserStatus.fromMap(Map<String, dynamic>.from(event.snapshot.value as Map));
          _updatePages();
        });
      }
    });

    _gpsSubscription = _userRef.child('details/gps_data').onValue.listen((event) {
      if (mounted && event.snapshot.exists) {
        setState(() {
          _gpsData = GpsData.fromMap(Map<String, dynamic>.from(event.snapshot.value as Map));
          _updatePages();
        });
      }
    });

    _healthSubscription = _userRef.child('details/max30102_data').onValue.listen((event) {
      if (mounted && event.snapshot.exists) {
        final healthData = HealthData.fromMap(Map<String, dynamic>.from(event.snapshot.value as Map));
        setState(() {
          if(!_healthHistory.any((e) => e.timestamp == healthData.timestamp)) {
            _healthHistory.insert(0, healthData);
          }
          if (_healthHistory.length > 50) _healthHistory.removeLast();
          _updatePages();
        });
      }
    });

    _fallSubscription = _userRef.child('fallHistory').onChildAdded.listen((event) {
      if (mounted && event.snapshot.exists) {
        final fallEvent = FallEvent.fromMap(Map<String, dynamic>.from(event.snapshot.value as Map));
        setState(() {
          if (!_fallHistory.any((e) => e.timestamp == fallEvent.timestamp)) {
            _fallHistory.insert(0, fallEvent);
          }
          _updatePages();
        });
      }
    });
  }

  void _updatePages() {
    _pages = <Widget>[
      ProfileScreen(userProfile: _userProfile, userRef: _userRef),
      HealthStatusScreen(healthHistory: _healthHistory),
      FallAlertsScreen(fallHistory: _fallHistory, userStatus: _userStatus, onClearHistory: _clearFallHistoryUI),
      LocationScreen(gpsData: _gpsData),
      const SettingsScreen(),
    ];
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    _statusSubscription?.cancel();
    _gpsSubscription?.cancel();
    _healthSubscription?.cancel();
    _fallSubscription?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<String> appBarTitles = ['Elder Profile', 'Health Status', 'Fall Alerts & SOS', 'Elder Location', 'Settings'];

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitles[_selectedIndex])),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.monitor_heart), label: 'Health'),
          BottomNavigationBarItem(icon: Icon(Icons.warning), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Location'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: _onItemTapped,
      ),
    );
  }
}