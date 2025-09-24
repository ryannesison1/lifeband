// screens/fall_alerts_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import '../models/models.dart';

class FallAlertsScreen extends StatelessWidget {
  final List<FallEvent> fallHistory;
  final UserStatus? userStatus;
  final VoidCallback onClearHistory; // UPDATED: Callback for clearing

  const FallAlertsScreen({
    super.key,
    required this.fallHistory,
    required this.onClearHistory, // UPDATED
    this.userStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SOSStatusCard(userStatus: userStatus),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Fall History', style: Theme.of(context).textTheme.titleLarge),
              TextButton.icon(
                icon: const Icon(Icons.clear_all, size: 20),
                label: const Text('Clear'),
                onPressed: onClearHistory, // UPDATED
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
        ),
        const Divider(indent: 16, endIndent: 16, height: 1),
        Expanded(
          child: fallHistory.isEmpty
              ? const Center(child: Text("No fall events recorded."))
              : ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: fallHistory.length,
            itemBuilder: (context, index) {
              return FallEventCard(event: fallHistory[index]);
            },
          ),
        ),
      ],
    );
  }
}

// NEW: Extracted fall event card into its own stateful widget for address lookup
class FallEventCard extends StatefulWidget {
  final FallEvent event;
  const FallEventCard({super.key, required this.event});

  @override
  State<FallEventCard> createState() => _FallEventCardState();
}

class _FallEventCardState extends State<FallEventCard> {
  String _address = 'Loading address...';

  @override
  void initState() {
    super.initState();
    _getAddressFromLatLng();
  }

  Future<void> _getAddressFromLatLng() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(widget.event.lat, widget.event.lng);
      Placemark place = placemarks[0];
      setState(() {
        _address = '${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}';
      });
    } catch (e) {
      setState(() {
        _address = 'Could not get address';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      child: ListTile(
        leading: Icon(Icons.personal_injury_outlined, color: Colors.orange[800], size: 40),
        title: Text(widget.event.formattedType, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.event.details),
            const SizedBox(height: 4),
            Text('Coordinates: (${widget.event.lat.toStringAsFixed(4)}, ${widget.event.lng.toStringAsFixed(4)})'),
            Text('Address: $_address'),
            const SizedBox(height: 4),
            Text(widget.event.formattedTimestamp, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}


class SOSStatusCard extends StatelessWidget {
  const SOSStatusCard({super.key, this.userStatus});
  final UserStatus? userStatus;

  @override
  Widget build(BuildContext context) {
    final bool isSosActive = userStatus?.sosActive ?? false;
    final DateTime? lastUpdate = userStatus?.lastUpdate;
    final Color cardColor = isSosActive ? Colors.red[700]! : Colors.green;
    final IconData icon = isSosActive ? Icons.warning_amber_rounded : Icons.check_circle_outline;
    final String title = isSosActive ? 'SOS ACTIVE' : 'Status: Normal';

    return Card(
      color: cardColor,
      margin: const EdgeInsets.all(16.0),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  if (lastUpdate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Last Update: ${DateFormat('MMM d, hh:mm:ss a').format(lastUpdate)}',
                        style: TextStyle(color: Colors.white.withOpacity(0.9)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}