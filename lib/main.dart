import 'dart:async';
import 'dart:convert';

import 'package:ebus_app/services/api_service.dart';
// ignore: unused_import
import 'package:ebus_app/super_admin/PengaturanAkunPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'screens/login_screen.dart';
import 'screens/forgot_password_screen.dart';

import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

import 'package:geolocator/geolocator.dart';

import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';

// ================= GLOBAL STREAM =================
StreamSubscription<Position>? positionStream;

// ================= INITIALIZE SERVICE =================
Future<void> initializeService() async {
  // WEB TIDAK SUPPORT
  if (kIsWeb) return;

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

// ================= BACKGROUND SERVICE =================
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // ================= STOP SERVICE =================
  if (service is AndroidServiceInstance) {
    service.on("stopService").listen((event) async {
      await positionStream?.cancel();

      service.stopSelf();

      print("🛑 BACKGROUND SERVICE STOPPED");
    });
  }

  // ================= GET BUS ID =================
  final prefs = await SharedPreferences.getInstance();

  final busId = prefs.getInt("bus_id");
  final trackingActive = prefs.getBool("tracking_active") ?? false;

  if (busId == null || !trackingActive) {
    print("❌ TRACKING BELUM AKTIF");
    service.stopSelf();
    return;
  }

  // ================= CANCEL STREAM LAMA =================
  await positionStream?.cancel();

  // ================= START STREAM BARU =================
  positionStream =
      Geolocator.getPositionStream(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.bestForNavigation,

          distanceFilter: 3,

          intervalDuration: const Duration(seconds: 2),

          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: "E-Bus Tracking",
            notificationText: "Tracking bus sedang berjalan",
            enableWakeLock: true,
          ),
        ),
      ).listen((Position position) async {
        print(
          "📍 BACKGROUND GPS: "
          "${position.latitude}, "
          "${position.longitude}",
        );

        try {
          final response = await http.put(
            Uri.parse(
              "https://ebusapp-production-4fdd.up.railway.app/api/buses/update-location/$busId",
            ),

            headers: {"Content-Type": "application/json"},

            body: jsonEncode({
              "latitude": position.latitude,

              "longitude": position.longitude,
            }),
          );

          print("✅ BACKGROUND UPDATE SUCCESS: ${response.statusCode}");
        } catch (e) {
          print("❌ BACKGROUND GPS ERROR: $e");
        }
      });
}

// ================= MAIN =================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ================= BACKGROUND SERVICE =================
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await initializeService();
  }

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

// ================= APP =================
class EBusApp extends StatelessWidget {
  const EBusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Bus App',

      debugShowCheckedModeBanner: false,

      theme: ThemeData(primarySwatch: Colors.blue),

      home: const LoginScreen(),

      routes: {
        '/login': (context) => const LoginScreen(),

        '/forgot-password': (context) => const ForgotPasswordScreen(),
      },
    );
  }
}
