import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  List<Map<String, dynamic>> getRegions() {
    return [
      {
        "name": "Jakarta",
        "latMin": -6.3,
        "latMax": -6.1,
        "lngMin": 106.7,
        "lngMax": 106.9,
      },
      {
        "name": "Jawa Barat",
        "latMin": -7.0,
        "latMax": -6.2,
        "lngMin": 106.4,
        "lngMax": 108.6,
      },
      {
        "name": "Jawa Tengah",
        "latMin": -7.8,
        "latMax": -6.5,
        "lngMin": 109.0,
        "lngMax": 111.0,
      },
      {
        "name": "Jawa Timur",
        "latMin": -8.3,
        "latMax": -7.0,
        "lngMin": 111.0,
        "lngMax": 114.0,
      },
      {
        "name": "Bali",
        "latMin": -8.8,
        "latMax": -8.1,
        "lngMin": 114.5,
        "lngMax": 115.6,
      },
      {
        "name": "Madura",
        "latMin": -7.2,
        "latMax": -6.8,
        "lngMin": 113.0,
        "lngMax": 113.6,
      },
      {
        "name": "Lombok",
        "latMin": -8.8,
        "latMax": -8.2,
        "lngMin": 116.0,
        "lngMax": 117.0,
      },
      {
        "name": "Kalimantan",
        "latMin": -2.0,
        "latMax": 1.0,
        "lngMin": 110.0,
        "lngMax": 115.0,
      },
      {
        "name": "Sumatra",
        "latMin": -6.0,
        "latMax": 5.0,
        "lngMin": 95.0,
        "lngMax": 105.0,
      },
    ];
  }

  LatLng generateRandomPoint(Map<String, dynamic> region, Random random) {
    double lat =
        region["latMin"] +
        random.nextDouble() * (region["latMax"] - region["latMin"]);
    double lng =
        region["lngMin"] +
        random.nextDouble() * (region["lngMax"] - region["lngMin"]);
    return LatLng(lat, lng);
  }

  List<Marker> generateBusMarkers() {
    final random = Random();
    final regions = getRegions();
    final markers = <Marker>[];

    int total = 100; // 🔥 total bus
    int perRegion = total ~/ regions.length;

    for (var region in regions) {
      for (int i = 0; i < perRegion; i++) {
        LatLng p = generateRandomPoint(region, random);
        markers.add(
          Marker(
            point: p,
            width: 36,
            height: 36,
            child: Icon(Icons.directions_bus, size: 28, color: Colors.red),
          ),
        );
      }
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final busMarkers = generateBusMarkers();

    return Scaffold(
      appBar: AppBar(title: const Text("Tracking Bus")),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(-6.200000, 106.816666), // Jakarta
          initialZoom: 5.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          MarkerLayer(markers: busMarkers),
        ],
      ),
    );
  }
}
