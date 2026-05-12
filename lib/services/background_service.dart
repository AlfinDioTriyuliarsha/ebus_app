import 'dart:async';
import 'dart:convert';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'api_service.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      notificationChannelId: 'ebus_tracking',
      initialNotificationTitle: 'E-Bus Tracking',
      initialNotificationContent: 'Tracking bus berjalan',
      foregroundServiceNotificationId: 888,
    ),

    iosConfiguration: IosConfiguration(),
  );

  service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  Timer.periodic(const Duration(seconds: 5), (timer) async {

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    try {
      await http.post(
        Uri.parse("${ApiService.baseUrl}/api/location/update"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "bus_id": 3,
          "latitude": position.latitude,
          "longitude": position.longitude,
        }),
      );

      print("BACKGROUND LOCATION SENT");

    } catch (e) {
      print(e);
    }
  });
}