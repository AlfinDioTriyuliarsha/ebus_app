import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:ebus_app/services/api_service.dart';

class DriverTrackingPage extends StatefulWidget {
  final int busId;

  const DriverTrackingPage({super.key, required this.busId});

  @override
  State<DriverTrackingPage> createState() => _DriverTrackingScreenState();
}

class _DriverTrackingScreenState extends State<DriverTrackingPage> {
  Timer? _timer;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // =========================
  // START TRACKING
  // =========================
  void _startTracking() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _sendLocation();
    });
  }

  // =========================
  // GET GPS
  // =========================
  Future<Position> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("GPS tidak aktif");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // =========================
  // SEND TO BACKEND
  // =========================
  Future<void> _sendLocation() async {
    try {
      final pos = await _getLocation();

      setState(() {
        _currentPosition = pos;
      });

      final response = await http.put(
        Uri.parse(
          "${ApiService.baseUrl}/api/buses/update-location/${widget.busId}",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "latitude": pos.latitude,
          "longitude": pos.longitude,
        }),
      );

      print("📡 SEND GPS: ${pos.latitude}, ${pos.longitude}");
      print("STATUS: ${response.statusCode}");
    } catch (e) {
      print("❌ ERROR GPS: $e");
    }
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver Tracking"),
        backgroundColor: const Color(0xFF001F3F),
      ),
      body: Center(
        child: _currentPosition == null
            ? const Text("Mengambil lokasi...")
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, size: 50, color: Colors.red),
                  Text(
                    "Lat: ${_currentPosition!.latitude}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    "Lng: ${_currentPosition!.longitude}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  const Text("📡 Mengirim ke server..."),
                ],
              ),
      ),
    );
  }
}
