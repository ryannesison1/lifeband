import 'package:intl/intl.dart';

class UserProfile {
  final String name;
  final int age;
  final String bloodType;
  final String fcmToken;

  UserProfile({
    required this.name,
    required this.age,
    required this.bloodType,
    required this.fcmToken,
  });

  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      name: data['name'] ?? 'N/A',
      age: data['age'] ?? 0,
      bloodType: data['bloodType'] ?? 'N/A',
      fcmToken: data['fcmToken'] ?? '',
    );
  }
}

class HealthData {
  final int heartRate;
  final int spo2;
  final DateTime timestamp;

  HealthData({
    required this.heartRate,
    required this.spo2,
    required this.timestamp,
  });

  factory HealthData.fromMap(Map<String, dynamic> data) {
    return HealthData(
      heartRate: data['heart_rate'] ?? 0,
      spo2: data['spo2'] ?? 0,
      timestamp: data['timestamp'] != null
          ? DateTime.parse(data['timestamp'])
          : DateTime.now(),
    );
  }

  String get formattedTimestamp {
    return DateFormat('MMM d, yyyy - hh:mm a').format(timestamp);
  }
}

class FallEvent {
  final String type;
  final String details;
  final DateTime timestamp;
  final double lat;
  final double lng;

  FallEvent({
    required this.type,
    required this.details,
    required this.timestamp,
    required this.lat,
    required this.lng,
  });

  factory FallEvent.fromMap(Map<String, dynamic> data) {
    return FallEvent(
      type: data['type'] ?? 'Unknown',
      details: data['details'] ?? 'No details.',
      timestamp: data['timestamp'] != null
          ? DateTime.parse(data['timestamp'])
          : DateTime.now(),
      lat: data['location']?['lat'] ?? 0.0,
      lng: data['location']?['lng'] ?? 0.0,
    );
  }

  String get formattedTimestamp {
    return DateFormat('MMM d, yyyy - hh:mm a').format(timestamp);
  }
}

class Alert {
  final String type;
  final num value;
  final String details;
  final DateTime timestamp;

  Alert({
    required this.type,
    required this.value,
    required this.details,
    required this.timestamp,
  });

  factory Alert.fromMap(Map<String, dynamic> data) {
    return Alert(
      type: data['type'] ?? 'Unknown Alert',
      value: data['value'] ?? 0,
      details: data['details'] ?? '',
      timestamp: data['timestamp'] != null
          ? DateTime.parse(data['timestamp'])
          : DateTime.now(),
    );
  }

  String get formattedTimestamp {
    return DateFormat('MMM d, yyyy - hh:mm a').format(timestamp);
  }
}

class UserStatus {
  final DateTime lastUpdate;
  final bool sosActive;

  UserStatus({required this.lastUpdate, required this.sosActive});

  factory UserStatus.fromMap(Map<String, dynamic> data) {
    return UserStatus(
      lastUpdate: data['last_update'] != null
          ? DateTime.parse(data['last_update'])
          : DateTime.now(),
      sosActive: data['sos_active'] ?? false,
    );
  }
}
