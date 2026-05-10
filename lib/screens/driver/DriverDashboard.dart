import 'dart:convert';
import 'package:ebus_app/screens/admin_perusahaan/MonitoringBusMapAdmin.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ebus_app/services/api_service.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

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

  int? companyId;

  StreamSubscription<Position>? _gpsStream;

  @override
  void initState() {
    super.initState();
    _gpsStream?.cancel();
    checkDriver();
  }

  // ================= CEK DRIVER =================
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
      print("ERROR CHECK DRIVER: $e");
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  // ================= REGISTER DRIVER =================
  Future<void> registerDriver() async {
    try {
      // ✅ STEP 1: ambil company dari backend
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
      setState(() {});

      // ✅ STEP 2: insert driver
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
      print("USER ID: ${widget.userId}");
      print("COMPANY ID: $companyId");

      if (res.statusCode == 201) {
        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Berhasil daftar driver")));

        checkDriver(); // refresh status
      }
    } catch (e) {
      print("ERROR REGISTER DRIVER: $e");
    }
  }

  // ================= START GPS TRACKING =================
  Future<void> startLiveTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    // ================= GPS AKTIF =================
    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      print("GPS OFF");
      return;
    }

    // ================= CHECK PERMISSION =================
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        print("PERMISSION DENIED");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("PERMISSION DENIED FOREVER");
      return;
    }

    // ================= START REALTIME GPS =================
    _gpsStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen((Position position) async {
          print("GPS: ${position.latitude}, ${position.longitude}");

          try {
            final response = await http.put(
              Uri.parse(
                "${ApiService.baseUrl}/api/buses/update-location/${widget.busId}",
              ),

              headers: {"Content-Type": "application/json"},

              body: jsonEncode({
                "latitude": position.latitude,
                "longitude": position.longitude,
              }),
            );

            print("UPDATE GPS: ${response.body}");
          } catch (e) {
            print("GPS ERROR: $e");
          }
        });
  }

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

    // ================= BELUM DAPAT BUS =================
    if (widget.busId == 0) {
      return Scaffold(
        appBar: AppBar(title: const Text("Driver Dashboard")),
        body: const Center(child: Text("Menunggu assign bus dari admin")),
      );
    }

    // ================= SUDAH SIAP =================
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Dashboard")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Email: ${widget.email}"),
            Text("User ID: ${widget.userId}"),
            Text("Bus ID: ${widget.busId}"),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {

              await startLiveTracking();

              if (companyId == null) return;


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
          ],
        ),
      ),
    );
  }
}
