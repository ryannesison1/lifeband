// models.dart

import 'package:intl/intl.dart';

// Model for Emergency Contacts
class EmergencyContact {
  final String id; // The Firebase push ID
  final String name;
  final String phone;
  final String email;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
  });

  factory EmergencyContact.fromMap(String id, Map<String, dynamic> data) {
    return EmergencyContact(
      id: id,
      name: data['name'] ?? 'N/A',
      phone: data['phone']?.toString() ?? 'N/A',
      email: data['email'] ?? 'N/A',
    );
  }
}

class UserProfile {
  final String name;
  final int age;
  final String bloodType;
  final String fcmToken;
  final List<EmergencyContact> emergencyContacts;

  UserProfile({
    required this.name,
    required this.age,
    required this.bloodType,
    required this.fcmToken,
    required this.emergencyContacts,
  });

  factory UserProfile.fromMap(Map<String, dynamic> data) {
    final List<EmergencyContact> contacts = [];
    if (data['emergencyContacts'] is Map) {
      final contactsMap =
      Map<String, dynamic>.from(data['emergencyContacts']);
      contactsMap.forEach((key, value) {
        contacts.add(EmergencyContact.fromMap(key, Map<String, dynamic>.from(value)));
      });
    }

    return UserProfile(
      name: data['name'] ?? 'N/A',
      age: data['age'] ?? 0,
      bloodType: data['bloodType'] ?? 'N/A',
      fcmToken: data['fcmToken'] ?? '',
      emergencyContacts: contacts,
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

  String get formattedType {
    switch (type) {
      case 'major_fall':
        return 'Major Fall';
      case 'minor_fall':
        return 'Minor Fall';
      default:
        return type.replaceAll('_', ' ').split(' ').map((str) => '${str[0].toUpperCase()}${str.substring(1)}').join(' ');
    }
  }

  factory FallEvent.fromMap(Map<String, dynamic> data) {
    return FallEvent(
      type: data['type'] ?? 'Unknown',
      details: data['details'] ?? 'No details.',
      timestamp: data['timestamp'] != null
          ? DateTime.parse(data['timestamp'])
          : DateTime.now(),
      lat: (data['location']?['lat'] ?? 0.0).toDouble(),
      lng: (data['location']?['lng'] ?? 0.0).toDouble(),
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
    // MODIFIED: Changed field names to match 'details/sos' structure
    return UserStatus(
      lastUpdate: data['timestamp'] != null
          ? DateTime.parse(data['timestamp'])
          : DateTime.now(),
      sosActive: data['active'] ?? false,
    );
  }
}

class GpsData {
  final double lat;
  final double lng;
  final double altitude;
  final double speedKph;
  final DateTime timestamp;

  GpsData({
    required this.lat,
    required this.lng,
    required this.altitude,
    required this.speedKph,
    required this.timestamp,
  });

  factory GpsData.fromMap(Map<String, dynamic> data) {
    return GpsData(
      lat: (data['lat'] ?? 0.0).toDouble(),
      lng: (data['lng'] ?? 0.0).toDouble(),
      altitude: (data['altitude'] ?? 0.0).toDouble(),
      speedKph: (data['speed_kph'] ?? 0.0).toDouble(),
      timestamp: data['timestamp'] != null
          ? DateTime.parse(data['timestamp'])
          : DateTime.now(),
    );
  }
  String get formattedTimestamp {
    return DateFormat('MMM d, yyyy - hh:mm a').format(timestamp);
  }
}