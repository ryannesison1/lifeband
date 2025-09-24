// screens/location_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import '../models/models.dart';

class LocationScreen extends StatefulWidget {
  final GpsData? gpsData;
  const LocationScreen({super.key, this.gpsData});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final MapController _mapController = MapController();
  String _address = 'Loading address...';

  // NEW: A flag to safely track if the map controller is initialized.
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    // Get initial address if data is already available.
    if (widget.gpsData != null) {
      _getAddressFromLatLng(widget.gpsData!);
    }
  }

  @override
  void didUpdateWidget(covariant LocationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // This method is called when new GPS data is received from the parent.
    if (widget.gpsData != oldWidget.gpsData && widget.gpsData != null) {
      _getAddressFromLatLng(widget.gpsData!);

      // MODIFIED: Only try to move the map IF the controller is ready.
      // This prevents the app from crashing when this screen is not visible.
      if (_isMapReady) {
        _mapController.move(LatLng(widget.gpsData!.lat, widget.gpsData!.lng), 16.5);
      }
    }
  }

  Future<void> _getAddressFromLatLng(GpsData data) async {
    if (!mounted) return;
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(data.lat, data.lng);
      Placemark place = placemarks[0];
      if (mounted) {
        setState(() {
          _address = '${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _address = 'Could not get address';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.gpsData == null) {
      return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text("Waiting for location data..."),
            ],
          )
      );
    }

    final LatLng devicePosition = LatLng(widget.gpsData!.lat, widget.gpsData!.lng);

    return Column(
      children: [
        Expanded(
          flex: 3,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: devicePosition,
              initialZoom: 16.5,
              // NEW: Use the onMapReady callback to know when it's safe to use the controller.
              onMapReady: () {
                setState(() {
                  _isMapReady = true;
                });
                // Ensure the map moves to the most recent position as soon as it's ready.
                _mapController.move(devicePosition, 16.5);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.lifeband', // Use your app's package name
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: devicePosition,
                    width: 80,
                    height: 80,
                    child: Tooltip(
                      message: 'Last seen: ${widget.gpsData!.formattedTimestamp}',
                      child: const Icon(Icons.location_pin, color: Colors.red, size: 50),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Card(
            margin: const EdgeInsets.all(8),
            elevation: 4,
            child: ListView(
              padding: const EdgeInsets.all(12.0),
              children: [
                ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.red),
                  title: const Text('Address', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(_address),
                ),
                ListTile(
                  leading: const Icon(Icons.pin_drop, color: Colors.blue),
                  title: const Text('Coordinates', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${widget.gpsData!.lat.toStringAsFixed(6)}, ${widget.gpsData!.lng.toStringAsFixed(6)}'),
                ),
                ListTile(
                  leading: const Icon(Icons.speed, color: Colors.green),
                  title: const Text('Speed', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${widget.gpsData!.speedKph.toStringAsFixed(2)} km/h'),
                ),
                ListTile(
                  leading: const Icon(Icons.timelapse, color: Colors.purple),
                  title: const Text('Last Update', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(widget.gpsData!.formattedTimestamp),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}