import 'package:ebus_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/forgot_password_screen.dart'; // TAMBAHAN: Import halaman lupa password
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
// ignore: unused_import
import 'package:ebus_app/super_admin/PengaturanAkunPage.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ================= STREAM =================
StreamSubscription<Position>? positionStream;

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      foregroundServiceNotificationId: 888,
      initialNotificationTitle: 'E-Bus Tracking',
      initialNotificationContent: 'Tracking bus berjalan',
    ),

    iosConfiguration: IosConfiguration(),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.on("stopService").listen((event) {
      service.stopSelf();
    });
  }

  final prefs = await SharedPreferences.getInstance();

  final busId = prefs.getInt("bus_id");

  if (busId == null) {
    print("BUS ID TIDAK DITEMUKAN");
    return;
  }

  // ================= CANCEL STREAM LAMA =================
  await positionStream?.cancel();

  // ================= START STREAM BARU =================
  positionStream =
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((Position position) async {
        print("BACKGROUND GPS: ${position.latitude}");

        try {
          await http.put(
            Uri.parse(
              "https://ebusapp-production-4fdd.up.railway.app/api/buses/update-location/$busId",
            ),

            headers: {"Content-Type": "application/json"},

            body: jsonEncode({
              "latitude": position.latitude,
              "longitude": position.longitude,
            }),
          );
        } catch (e) {
          print("BACKGROUND GPS ERROR: $e");
        }
      });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ================= BACKGROUND SERVICE =================
  await initializeService();

  // ================= API SERVICE =================
  await ApiService.init();

  // ================= FACEBOOK LOGIN =================
  if (kIsWeb) {
    await FacebookAuth.i.webAndDesktopInitialize(
      appId: "1234567890",
      cookie: true,
      xfbml: true,
      version: "v15.0",
    );
  }

  runApp(const EBusApp());
}

class EBusApp extends StatelessWidget {
  const EBusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Bus App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(),
      // TAMBAHAN: Daftarkan routes agar navigasi lebih mudah
      routes: {
        '/login': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
      },
    );
  }
}
