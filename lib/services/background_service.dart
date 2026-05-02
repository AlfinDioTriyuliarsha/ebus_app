import 'dart:async';
import 'dart:convert';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

int globalBusId = 0;

Future<void> initializeService(int busId) async {
  globalBusId = busId;

  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
    ),
    iosConfiguration: IosConfiguration(),
  );

  service.startService();
}

// 🔥 INI YANG JALAN DI BACKGROUND
@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  Timer.periodic(const Duration(seconds: 5), (timer) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print("📍 BG GPS: ${position.latitude}, ${position.longitude}");

      // 🔥 KIRIM KE SERVER
      await http.put(
        Uri.parse(
          "https://ebusapp-production-4fdd.up.railway.app/api/buses/update-location/$globalBusId",
        ),

        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "latitude": position.latitude,
          "longitude": position.longitude,
        }),
      );
    } catch (e) {
      print("❌ BG ERROR: $e");
    }
  });
}
