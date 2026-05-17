import 'dart:async';
import 'dart:convert';

import 'package:ebus_app/screens/admin_perusahaan/MonitoringBusMapAdmin.dart';
import 'package:ebus_app/screens/login_screen.dart';
import 'package:ebus_app/services/api_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'package:geolocator/geolocator.dart';

import 'package:http/http.dart' as http;

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
  bool restoredTracking = false;

  String gpsStatus = "Mencari GPS...";
  double gpsAccuracy = 0;

  DateTime? lastGpsUpdate;

  int? companyId;

  Timer? _gpsChecker;

  StreamSubscription<Position>? _gpsStream;

  // ================= INIT =================
  @override
  void initState() {
    super.initState();

    checkDriver();
    getCompany();
    restoreTracking();
  }

  // ================= RESTORE TRACKING =================
  Future<void> restoreTracking() async {
    final prefs = await SharedPreferences.getInstance();

    final busId = prefs.getInt("bus_id");

    if (busId != null) {
      trackingStarted = true;
      restoredTracking = true;

      _startGpsChecker();

      await startForegroundTracking();

      if (!mounted) return;

      setState(() {
        gpsConnected = true;
        gpsStatus = "Tracking aktif";
      });

      print("✅ TRACKING RESTORED");
    }
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
          const SnackBar(
            content: Text("Company tidak ditemukan"),
          ),
        );

        return;
      }

      companyId = companyData['data']['id'];

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

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Berhasil daftar driver"),
          ),
        );

        checkDriver();
      }
    } catch (e) {
      print("❌ ERROR REGISTER DRIVER: $e");
    }
  }

  // ================= GPS CHECKER =================
  void _startGpsChecker() {
    _gpsChecker?.cancel();

    _gpsChecker = Timer.periodic(
      const Duration(seconds: 5),
      (timer) async {
        bool serviceEnabled =
            await Geolocator.isLocationServiceEnabled();

        if (!mounted) return;

        if (!serviceEnabled) {
          setState(() {
            gpsConnected = false;
            gpsStatus = "GPS OFF";
          });

          return;
        }

        if (trackingStarted) {
          setState(() {
            gpsConnected = true;
          });
        }
      },
    );
  }

  // ================= FOREGROUND TRACKING =================
  Future<void> startForegroundTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    // ================= GPS ENABLE =================
    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (!mounted) return;

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
      if (!mounted) return;

      setState(() {
        gpsConnected = false;
        gpsStatus = "Permission Ditolak";
      });

      return;
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;

      setState(() {
        gpsConnected = false;
        gpsStatus = "Permission Permanen Ditolak";
      });

      return;
    }

    // ================= CANCEL STREAM LAMA =================
    await _gpsStream?.cancel();

    // ================= START STREAM =================
    _gpsStream = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3,
        intervalDuration: const Duration(seconds: 2),
        foregroundNotificationConfig:
            const ForegroundNotificationConfig(
          notificationTitle: "E-Bus Tracking Aktif",
          notificationText:
              "Lokasi bus sedang berjalan di background",
          enableWakeLock: true,
        ),
      ),
    ).listen((Position position) async {
      print(
        "📍 FOREGROUND GPS: "
        "${position.latitude}, "
        "${position.longitude}",
      );

      // ================= KIRIM KE SERVER =================
      try {
        await http.put(
          Uri.parse(
            "${ApiService.baseUrl}/api/buses/update-location/${widget.busId}",
          ),
          headers: {
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "latitude": position.latitude,
            "longitude": position.longitude,
          }),
        );

        print("✅ GPS SENT");
      } catch (e) {
        print("❌ SEND GPS ERROR: $e");
      }

      // ================= UPDATE UI =================
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

  // ================= LOGOUT =================
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();

    final service = FlutterBackgroundService();

    service.invoke("stopService");

    await _gpsStream?.cancel();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
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
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // ================= BELUM TERDAFTAR =================
    if (!isRegistered) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F7FE),
        appBar: AppBar(
          backgroundColor: const Color(0xFF001F3F),
          title: const Text(
            "Driver Dashboard",
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person_off,
                  size: 90,
                  color: Colors.orange,
                ),

                const SizedBox(height: 20),

                const Text(
                  "Anda belum terdaftar sebagai driver",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 25),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF001F3F),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: registerDriver,
                  icon: const Icon(Icons.app_registration),
                  label: const Text("Daftar sebagai Driver"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ================= BELUM ADA BUS =================
    if (widget.busId == 0) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F7FE),
        appBar: AppBar(
          backgroundColor: const Color(0xFF001F3F),
          title: const Text(
            "Driver Dashboard",
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: const Center(
          child: Text(
            "Menunggu assign bus dari admin",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // ================= DASHBOARD =================
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),

      appBar: AppBar(
        backgroundColor: const Color(0xFF001F3F),
        elevation: 0,

        title: const Text(
          "Driver Dashboard",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            onPressed: () async {
              final confirm = await showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: const Text("Logout"),
                    content: const Text(
                      "Apakah anda yakin ingin logout?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        child: const Text("Batal"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        child: const Text("Logout"),
                      ),
                    ],
                  );
                },
              );

              if (confirm == true) {
                logout();
              }
            },
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ================= HEADER CARD =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF001F3F),
                    Color(0xFF003366),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 42,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Color(0xFF001F3F),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    widget.email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      "Bus ID : ${widget.busId}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ================= STATUS GPS =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: gpsConnected
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        child: Icon(
                          gpsConnected
                              ? Icons.gps_fixed
                              : Icons.gps_off,
                          color: gpsConnected
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),

                      const SizedBox(width: 15),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              gpsStatus,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: gpsConnected
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              "Akurasi GPS : ${gpsAccuracy.toStringAsFixed(1)} m",
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  if (lastGpsUpdate != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.grey,
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              "Update terakhir : "
                              "${lastGpsUpdate!.hour.toString().padLeft(2, '0')}:"
                              "${lastGpsUpdate!.minute.toString().padLeft(2, '0')}:"
                              "${lastGpsUpdate!.second.toString().padLeft(2, '0')}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ================= START BUTTON =================
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shadowColor: Colors.green.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),

                onPressed: () async {
                  if (trackingStarted &&
                      restoredTracking == false) {
                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Tracking sudah aktif",
                        ),
                      ),
                    );

                    return;
                  }

                  bool serviceEnabled =
                      await Geolocator
                          .isLocationServiceEnabled();

                  if (!serviceEnabled) {
                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "GPS belum aktif",
                        ),
                      ),
                    );

                    return;
                  }

                  LocationPermission permission =
                      await Geolocator.checkPermission();

                  if (permission ==
                      LocationPermission.denied) {
                    permission =
                        await Geolocator.requestPermission();
                  }

                  if (permission ==
                          LocationPermission.denied ||
                      permission ==
                          LocationPermission
                              .deniedForever) {
                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Permission GPS ditolak",
                        ),
                      ),
                    );

                    return;
                  }

                  // ================= START TRACKING API =================
                  await http.put(
                    Uri.parse(
                      "${ApiService.baseUrl}/api/buses/start-tracking/${widget.busId}",
                    ),
                  );

                  final prefs =
                      await SharedPreferences.getInstance();

                  await prefs.setInt(
                    "bus_id",
                    widget.busId,
                  );

                  final service =
                      FlutterBackgroundService();

                  await service.startService();

                  await startForegroundTracking();

                  trackingStarted = true;

                  restoredTracking = false;

                  _startGpsChecker();

                  if (!mounted) return;

                  setState(() {
                    gpsConnected = true;
                    gpsStatus = "Tracking aktif";
                  });

                  print("✅ TRACKING STARTED");

                  if (companyId == null) {
                    if (!mounted) return;

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Company tidak ditemukan",
                        ),
                      ),
                    );

                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MonitoringBusMapAdmin(
                        companyId: companyId!,
                        busId: widget.busId,
                        userId: widget.userId,
                      ),
                    ),
                  );
                },

                icon: const Icon(Icons.play_arrow_rounded),

                label: const Text(
                  "Mulai Tracking Bus",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ================= STOP BUTTON =================
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shadowColor: Colors.red.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),

                onPressed: () async {
                  await http.put(
                    Uri.parse(
                      "${ApiService.baseUrl}/api/buses/stop-tracking/${widget.busId}",
                    ),
                  );

                  final prefs =
                      await SharedPreferences.getInstance();

                  await prefs.remove("bus_id");

                  final service =
                      FlutterBackgroundService();

                  service.invoke("stopService");

                  await _gpsStream?.cancel();

                  _gpsStream = null;

                  trackingStarted = false;

                  restoredTracking = false;

                  _gpsChecker?.cancel();

                  if (!mounted) return;

                  setState(() {
                    gpsConnected = false;
                    gpsStatus = "Tracking Dihentikan";
                  });

                  print("🛑 TRACKING STOPPED");
                },

                icon: const Icon(Icons.stop_circle_outlined),

                label: const Text(
                  "Sampai Tujuan / Stop Tracking",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}