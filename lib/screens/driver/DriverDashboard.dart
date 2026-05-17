import 'dart:async';
import 'dart:convert';

import 'package:ebus_app/screens/admin_perusahaan/MonitoringBusMapAdmin.dart';
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

class _DriverDashboardState extends State<DriverDashboard>
    with TickerProviderStateMixin {
  bool isRegistered = false;
  bool isLoading = true;

  bool gpsConnected = false;
  bool trackingStarted = false;
  bool restoredTracking = false;

  String gpsStatus = "Mencari GPS...";
  double gpsAccuracy = 0;

  DateTime? lastGpsUpdate;

  int? companyId;
  int? driverId;

  Timer? _gpsChecker;
  StreamSubscription<Position>? _gpsStream;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // ================= INIT =================
  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    initializeData();
  }

  // ================= RESTORE =================
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

  // ================= CHECK DRIVER =================
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

  // ================= GET BUS COMPANY =================
  Future<void> getBusCompany() async {
    try {
      if (driverId == null) {
        print("❌ DRIVER ID NULL");
        return;
      }

      final res = await http.get(Uri.parse("${ApiService.baseUrl}/api/buses"));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        final buses = List<Map<String, dynamic>>.from(data['data']);

        // ================= CARI BUS BERDASARKAN DRIVER_ID =================
        final bus = buses.firstWhere(
          (b) => b['driver_id'] != null && b['driver_id'] == driverId,
          orElse: () => <String, dynamic>{},
        );

        if (bus.isNotEmpty) {
          companyId = bus['company_id'];

          print("✅ COMPANY ID FROM BUS: $companyId");

          if (mounted) {
            setState(() {});
          }
        } else {
          print("❌ BUS DRIVER TIDAK DITEMUKAN");
        }
      }
    } catch (e) {
      print("❌ GET BUS COMPANY ERROR: $e");
    }
  }

  // ================= GET DRIVER =================
  Future<void> getDriverId() async {
    try {
      final res = await http.get(
        Uri.parse("${ApiService.baseUrl}/api/drivers/user/${widget.userId}"),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (data['data'] != null) {
          driverId = data['data']['id'];

          print("✅ DRIVER ID: $driverId");
        }
      }
    } catch (e) {
      print("❌ GET DRIVER ID ERROR: $e");
    }
  }

  // ================= INITIALIZE DATA =================
  Future<void> initializeData() async {
    await checkDriver();

    await getDriverId();

    if (driverId != null) {
      await getBusCompany();
    }

    await restoreTracking();
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

      if (res.statusCode == 201) {
        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Berhasil daftar driver")));

        checkDriver();
      }
    } catch (e) {
      print("❌ REGISTER ERROR: $e");
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

      if (trackingStarted) {
        setState(() {
          gpsConnected = true;
        });
      }
    });
  }

  // ================= START TRACKING =================
  Future<void> startForegroundTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (!mounted) return;

      setState(() {
        gpsConnected = false;
        gpsStatus = "GPS OFF";
      });

      return;
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return;

      setState(() {
        gpsConnected = false;
        gpsStatus = "Permission Ditolak";
      });

      return;
    }

    await _gpsStream?.cancel();

    _gpsStream =
        Geolocator.getPositionStream(
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 3,
            intervalDuration: const Duration(seconds: 2),
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: "E-Bus Tracking Aktif",
              notificationText: "Lokasi bus sedang berjalan di background",
              enableWakeLock: true,
            ),
          ),
        ).listen((Position position) async {
          print("========== GPS DRIVER ==========");
          print(position.latitude);
          print(position.longitude);
          print(position.accuracy);
          try {
            final res = await http.put(
              Uri.parse(
                "${ApiService.baseUrl}/api/buses/update-location/${widget.busId}",
              ),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({
                "latitude": position.latitude,
                "longitude": position.longitude,
              }),
            );

            print("GPS RESPONSE: ${res.statusCode} - ${res.body}");
          } catch (e) {
            print("❌ SEND GPS ERROR: $e");
          }

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
    try {
      final prefs = await SharedPreferences.getInstance();

      // ================= HAPUS SEMUA SESSION =================
      await prefs.clear();

      // ================= STOP TRACKING =================
      final service = FlutterBackgroundService();

      service.invoke("stopService");

      await _gpsStream?.cancel();

      _gpsChecker?.cancel();

      trackingStarted = false;

      if (!mounted) return;

      // ================= PINDAH KE LOGIN =================
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      print("❌ LOGOUT ERROR: $e");
    }
  }

  // ================= DISPOSE =================
  @override
  void dispose() {
    _gpsChecker?.cancel();
    _gpsStream?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!isRegistered) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: registerDriver,
            child: const Text("Daftar Driver"),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: const Text(
          "Driver Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == "logout") {
                await logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: "logout",
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 10),
                    Text("Logout"),
                  ],
                ),
              ),
            ],
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
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.directions_bus,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      ),

                      const Spacer(),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: gpsConnected ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          gpsConnected ? "ONLINE" : "OFFLINE",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  Text(
                    widget.email,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Bus ID : ${widget.busId}",
                    style: const TextStyle(color: Colors.white70),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "User ID : ${widget.userId}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ================= GPS CARD =================
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 15,
                  ),
                ],
              ),

              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: gpsConnected
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        child: Icon(
                          gpsConnected ? Icons.gps_fixed : Icons.gps_off,
                          color: gpsConnected ? Colors.green : Colors.red,
                        ),
                      ),

                      const SizedBox(width: 18),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              gpsStatus,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: gpsConnected ? Colors.green : Colors.red,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              "Akurasi GPS : ${gpsAccuracy.toStringAsFixed(1)} m",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  if (lastGpsUpdate != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 18,
                          color: Colors.grey,
                        ),

                        const SizedBox(width: 8),

                        Text(
                          "Terakhir update : "
                          "${lastGpsUpdate!.hour}:"
                          "${lastGpsUpdate!.minute}:"
                          "${lastGpsUpdate!.second}",
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ================= BUTTON START =================
            GestureDetector(
              onTap: () async {
                try {
                  // ================= CEK COMPANY =================
                  if (companyId == null) {
                    await getBusCompany();
                  }

                  if (companyId == null) {
                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Company belum ditemukan")),
                    );

                    return;
                  }

                  // ================= CEK GPS =================
                  bool serviceEnabled =
                      await Geolocator.isLocationServiceEnabled();

                  if (!serviceEnabled) {
                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("GPS belum aktif")),
                    );

                    return;
                  }

                  // ================= PERMISSION =================
                  LocationPermission permission =
                      await Geolocator.checkPermission();

                  if (permission == LocationPermission.denied) {
                    permission = await Geolocator.requestPermission();
                  }

                  if (permission == LocationPermission.denied ||
                      permission == LocationPermission.deniedForever) {
                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Permission lokasi ditolak"),
                      ),
                    );

                    return;
                  }

                  // ================= SAVE PREF =================
                  final prefs = await SharedPreferences.getInstance();

                  await prefs.setInt("bus_id", widget.busId);

                  // ================= START SERVICE =================
                  final service = FlutterBackgroundService();

                  await service.startService();

                  final startRes = await http.put(
                    Uri.parse(
                      "${ApiService.baseUrl}/api/buses/start-tracking/${widget.busId}",
                    ),
                  );

                  if (startRes.statusCode != 200) {
                    throw Exception("API START TRACKING GAGAL");
                  }

                  print("START TRACKING: ${startRes.statusCode}");
                  print(startRes.body);

                  // ================= START TRACKING =================
                  await startForegroundTracking();

                  setState(() {
                    trackingStarted = true;
                  });

                  _startGpsChecker();

                  if (!mounted) return;

                  setState(() {
                    gpsConnected = true;
                    gpsStatus = "Tracking aktif";
                  });

                  print("✅ TRACKING STARTED");

                  if (companyId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Company ID tidak ditemukan"),
                      ),
                    );

                    return;
                  }
                } catch (e) {
                  print("❌ START TRACKING ERROR: $e");

                  if (!mounted) return;

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("ERROR: $e")));
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),

                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 32,
                    ),

                    SizedBox(width: 10),

                    Text(
                      "MULAI TRACKING",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ================= STOP BUTTON =================
            GestureDetector(
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();

                await prefs.remove("bus_id");

                final service = FlutterBackgroundService();

                await http.put(
                  Uri.parse(
                    "${ApiService.baseUrl}/api/buses/stop-tracking/${widget.busId}",
                  ),
                );

                service.invoke("stopService");

                await _gpsStream?.cancel();

                trackingStarted = false;

                _gpsChecker?.cancel();

                if (!mounted) return;

                setState(() {
                  gpsConnected = false;
                  gpsStatus = "Tracking Dihentikan";
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Tracking dihentikan")),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.red,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),

                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.stop_circle_outlined,
                      color: Colors.white,
                      size: 30,
                    ),

                    SizedBox(width: 10),

                    Text(
                      "STOP TRACKING",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            // ================= MONITORING BUTTON =================
            const SizedBox(height: 18),

            GestureDetector(
              onTap: () {
                if (companyId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Company belum ditemukan")),
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

              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 22),

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),

                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),

                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, color: Colors.white, size: 30),

                    SizedBox(width: 10),

                    Text(
                      "LIHAT MONITORING",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ================= INFO PANEL =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Informasi Tracking",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),

                  const SizedBox(height: 15),

                  _buildInfoTile(Icons.location_on, "Status GPS", gpsStatus),

                  _buildInfoTile(
                    Icons.speed,
                    "Akurasi",
                    "${gpsAccuracy.toStringAsFixed(1)} meter",
                  ),

                  _buildInfoTile(
                    Icons.directions_bus,
                    "Bus Aktif",
                    "${widget.busId}",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= WIDGET =================
  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: Icon(icon, color: Colors.blue),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
