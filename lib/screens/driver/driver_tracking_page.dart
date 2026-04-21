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
  State<DriverTrackingPage> createState() => _DriverTrackingPageState();
}

class _DriverTrackingPageState extends State<DriverTrackingPage> {
  Timer? _timer;
  bool isTracking = false;
  String status = "Belum aktif";

  // =========================
  // START TRACKING
  // =========================
  Future<void> startTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => status = "GPS tidak aktif");
      return;
    }

    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied) {
      setState(() => status = "Izin ditolak");
      return;
    }

    setState(() {
      isTracking = true;
      status = "Tracking aktif...";
    });

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        await _sendToServer(pos.latitude, pos.longitude);

        setState(() {
          status =
              "Lat: ${pos.latitude.toStringAsFixed(5)}, Lng: ${pos.longitude.toStringAsFixed(5)}";
        });
      } catch (e) {
        setState(() => status = "Gagal ambil GPS");
      }
    });
  }

  // =========================
  // STOP TRACKING
  // =========================
  void stopTracking() {
    _timer?.cancel();

    setState(() {
      isTracking = false;
      status = "Tracking dihentikan";
    });
  }

  // =========================
  // KIRIM KE SERVER
  // =========================
  Future<void> _sendToServer(double lat, double lng) async {
    try {
      await http.put(
        Uri.parse(
            "${ApiService.baseUrl}/api/buses/update-location/${widget.busId}"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "latitude": lat,
          "longitude": lng,
        }),
      );
    } catch (e) {
      setState(() => status = "Gagal kirim ke server");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Tracking")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(status, style: const TextStyle(fontSize: 18)),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isTracking ? null : startTracking,
              child: const Text("START"),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: isTracking ? stopTracking : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("STOP"),
            ),
          ],
        ),
      ),
    );
  }
}