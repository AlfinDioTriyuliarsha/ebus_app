import 'dart:async';
import 'dart:convert';

import 'package:ebus_app/screens/admin_perusahaan/MonitoringBusMapAdmin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:http/http.dart' as http;
import 'package:ebus_app/services/api_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverDashboard extends StatefulWidget {
  final String email;
  final int userId;
  final int busId;

  const DriverDashboard({
    super.key,
    required this.email,
    required this.userId,
    required this.busId,
  });

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  bool isRegistered = false;
  bool isLoading = true;

  bool gpsConnected = false;

  bool trackingStarted = false;

  String gpsStatus = "Mencari GPS...";

  double gpsAccuracy = 0;

  DateTime? lastGpsUpdate;

  bool websocketConnected = false;

  int? companyId;

  Timer? _gpsChecker;

  StreamSubscription<Position>? _gpsStream;

  // ================= INIT =================
  @override
  void initState() {
    super.initState();

    checkDriver();

    getCompany();
  }

  // ================= GET DRIVER =================
  Future<void> checkDriver() async {
    try {
      final res = await http.get(
        Uri.parse("${ApiService.baseUrl}/api/drivers/user/${widget.userId}"),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        isRegistered = data['data'] != null;
      }
    } catch (e) {
      print("❌ ERROR CHECK DRIVER: $e");
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  // ================= GET COMPANY =================
  Future<void> getCompany() async {
    try {
      final res = await http.get(
        Uri.parse("${ApiService.baseUrl}/api/companies/user/${widget.userId}"),
      );

      final data = jsonDecode(res.body);

      if (data['success'] == true) {
        companyId = data['data']['id'];

        print("✅ COMPANY ID: $companyId");

        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      print("❌ GET COMPANY ERROR: $e");
    }
  }

  // ================= REGISTER DRIVER =================
  Future<void> registerDriver() async {
    try {
      final companyRes = await http.get(
        Uri.parse("${ApiService.baseUrl}/api/companies/user/${widget.userId}"),
      );

      final companyData = jsonDecode(companyRes.body);

      if (companyData['success'] != true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Company tidak ditemukan")),
        );

        return;
      }

      companyId = companyData['data']['id'];

      if (mounted) {
        setState(() {});
      }

      final res = await http.post(
        Uri.parse("${ApiService.baseUrl}/api/drivers"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.userId,
          "email": widget.email,
          "kontak": "-",
          "company_id": companyId,
        }),
      );

      print("STATUS: ${res.statusCode}");
      print("BODY: ${res.body}");

      if (res.statusCode == 201) {
        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Berhasil daftar driver")));

        checkDriver();
      }
    } catch (e) {
      print("❌ ERROR REGISTER DRIVER: $e");
    }
  }

  // ================= GPS CHECKER =================
  void _startGpsChecker() {
    _gpsChecker?.cancel();

    _gpsChecker = Timer.periodic(const Duration(seconds: 5), (timer) async {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!mounted) return;

      if (!serviceEnabled) {
        setState(() {
          gpsConnected = false;
          gpsStatus = "GPS OFF";
        });

        return;
      }

      // ================= TRACKING MASIH AKTIF =================
      if (trackingStarted) {
        setState(() {
          gpsConnected = true;
        });
      }
    });
  }

  Future<void> startLiveTracking() async {
    bool serviceEnabled;

    LocationPermission permission;

    // ================= GPS ENABLE =================
    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      setState(() {
        gpsConnected = false;
        gpsStatus = "GPS OFF";
      });

      return;
    }

    // ================= PERMISSION =================
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      setState(() {
        gpsConnected = false;
        gpsStatus = "Permission Ditolak";
      });

      return;
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        gpsConnected = false;
        gpsStatus = "Permission Permanen Ditolak";
      });

      return;
    }

    // ================= CANCEL STREAM LAMA =================
    await _gpsStream?.cancel();

    // ================= START STREAM =================
    _gpsStream =
        Geolocator.getPositionStream(
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.high,

            distanceFilter: 5,

            intervalDuration: const Duration(seconds: 5),
          ),
        ).listen((Position position) async {
          print("📍 UI GPS: ${position.latitude}");

          if (!mounted) return;

          setState(() {
            gpsConnected = true;

            gpsStatus =
                "GPS Connected (${position.accuracy.toStringAsFixed(1)}m)";

            gpsAccuracy = position.accuracy;

            lastGpsUpdate = DateTime.now();
          });
        });
  }

  // ================= DISPOSE =================
  @override
  void dispose() {
    _gpsChecker?.cancel();
    _gpsStream?.cancel();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    // ================= LOADING =================
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // ================= BELUM TERDAFTAR =================
    if (!isRegistered) {
      return Scaffold(
        appBar: AppBar(title: const Text("Driver Dashboard")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Anda belum terdaftar sebagai driver"),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: registerDriver,
                child: const Text("Daftar sebagai Driver"),
              ),
            ],
          ),
        ),
      );
    }

    // ================= BELUM ADA BUS =================
    if (widget.busId == 0) {
      return Scaffold(
        appBar: AppBar(title: const Text("Driver Dashboard")),
        body: const Center(child: Text("Menunggu assign bus dari admin")),
      );
    }

    // ================= DASHBOARD =================
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Dashboard")),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Email: ${widget.email}"),

              Text("User ID: ${widget.userId}"),

              Text("Bus ID: ${widget.busId}"),

              const SizedBox(height: 20),

              // ================= GPS STATUS =================
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: gpsConnected
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: gpsConnected ? Colors.green : Colors.red,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          gpsConnected ? Icons.gps_fixed : Icons.gps_off,
                          color: gpsConnected ? Colors.green : Colors.red,
                        ),

                        const SizedBox(width: 10),

                        Text(
                          gpsStatus,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: gpsConnected ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    if (lastGpsUpdate != null)
                      Text(
                        "Update terakhir: "
                        "${lastGpsUpdate!.hour}:"
                        "${lastGpsUpdate!.minute}:"
                        "${lastGpsUpdate!.second}",
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ================= START TRACKING =================
              ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();

                  await prefs.setInt("bus_id", widget.busId);

                  final service = FlutterBackgroundService();

                  await service.startService();

                  trackingStarted = true;

                  _startGpsChecker();

                  await startLiveTracking();

                  if (!mounted) return;

                  setState(() {});

                  if (companyId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Company tidak ditemukan")),
                    );

                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MonitoringBusMapAdmin(
                        companyId: companyId!,
                        busId: widget.busId,
                        userId: widget.userId,
                      ),
                    ),
                  );
                },
                child: const Text("Mulai Tracking Bus"),
              ),

              // ================= STOP TRACKING =================
              const SizedBox(height: 15),

              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),

                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();

                  await prefs.remove("bus_id");

                  final service = FlutterBackgroundService();

                  service.invoke("stopService");

                  trackingStarted = false;

                  _gpsChecker?.cancel();

                  if (!mounted) return;

                  setState(() {
                    gpsConnected = false;
                    gpsStatus = "Tracking Dihentikan";
                  });

                  print("🛑 TRACKING STOPPED");
                },

                child: const Text("Sampai Tujuan / Stop Tracking"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
