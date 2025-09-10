import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

class ProfileCard extends StatelessWidget {
  final UserProfile userProfile;
  const ProfileCard({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User Profile',
                style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.red),
              title: Text(userProfile.name),
              subtitle: const Text('Name'),
            ),
            ListTile(
              leading: const Icon(Icons.cake, color: Colors.red),
              title: Text('${userProfile.age} years old'),
              subtitle: const Text('Age'),
            ),
            ListTile(
              leading: const Icon(Icons.bloodtype, color: Colors.red),
              title: Text(userProfile.bloodType),
              subtitle: const Text('Blood Type'),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusCard extends StatelessWidget {
  final bool sosActive;
  final DateTime? lastUpdate;

  const StatusCard({super.key, required this.sosActive, this.lastUpdate});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: sosActive ? Colors.red[800] : Colors.green[700],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  sosActive ? Icons.warning : Icons.check_circle,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  sosActive ? 'SOS ACTIVE' : 'SYSTEM NORMAL',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (lastUpdate != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last update: ${DateFormat.yMd().add_Hms().format(lastUpdate!)}',
                style: const TextStyle(color: Colors.white70),
              )
            ]
          ],
        ),
      ),
    );
  }
}

class AlertsCard extends StatelessWidget {
  final List<Alert> alerts;
  final Function(int) onClear;
  const AlertsCard({super.key, required this.alerts, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Active Alerts',
                style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            if (alerts.isEmpty)
              const Center(child: Text('No active alerts.'))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: alerts.length,
                itemBuilder: (ctx, index) {
                  final alert = alerts[index];
                  return ListTile(
                    leading: const Icon(Icons.error, color: Colors.amber),
                    title: Text('${alert.type.replaceAll('_', ' ').toUpperCase()}: ${alert.value}'),
                    subtitle: Text(
                        '${alert.details} at ${alert.formattedTimestamp}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.clear, color: Colors.red),
                      onPressed: () => onClear(index),
                    ),
                  );
                },
              )
          ],
        ),
      ),
    );
  }
}

class HealthHistoryCard extends StatelessWidget {
  final List<HealthData> healthHistory;
  const HealthHistoryCard({super.key, required this.healthHistory});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Health History',
                style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            if (healthHistory.isEmpty)
              const Center(child: Text('No health history available.'))
            else
              SizedBox(
                height: 200, // Constrain height for scrollable list
                child: ListView.builder(
                  itemCount: healthHistory.length,
                  itemBuilder: (ctx, index) {
                    final data = healthHistory[index];
                    return ListTile(
                      leading:
                      const Icon(Icons.monitor_heart, color: Colors.red),
                      title: Text(
                          'HR: ${data.heartRate} bpm, SpO2: ${data.spo2}%'),
                      subtitle: Text(data.formattedTimestamp),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class FallHistoryCard extends StatelessWidget {
  final List<FallEvent> fallHistory;
  const FallHistoryCard({super.key, required this.fallHistory});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fall History',
                style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            if (fallHistory.isEmpty)
              const Center(child: Text('No fall history available.'))
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: fallHistory.length,
                  itemBuilder: (ctx, index) {
                    final event = fallHistory[index];
                    return ListTile(
                      leading: const Icon(Icons.personal_injury, color: Colors.red),
                      title: Text(event.type.replaceAll('_', ' ').toUpperCase()),
                      subtitle: Text(
                          '${event.details}\n${event.formattedTimestamp}'),
                      isThreeLine: true,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
