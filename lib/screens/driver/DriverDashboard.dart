import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ebus_app/services/api_service.dart';

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

  @override
  void initState() {
    super.initState();
    checkDriver();
  }

  // ✅ CEK APAKAH SUDAH JADI DRIVER
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

    setState(() => isLoading = false);
  }

  // ✅ DAFTAR DRIVER
  Future<void> registerDriver() async {
    try {
      final res = await http.post(
        Uri.parse("${ApiService.baseUrl}/api/drivers"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.userId,
          "driver_name": widget.email,
          "kontak": "-",
          "company_id": 1, // ⚠️ sementara (nanti bisa dipilih)
        }),
      );

      if (res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berhasil daftar driver")),
        );

        checkDriver(); // refresh
      }
    } catch (e) {
      print("ERROR REGISTER DRIVER: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ❌ BELUM TERDAFTAR
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

    // ❌ BELUM DAPAT BUS
    if (widget.busId == 0) {
      return Scaffold(
        appBar: AppBar(title: const Text("Driver Dashboard")),
        body: const Center(
          child: Text("Menunggu assign bus dari admin"),
        ),
      );
    }

    // ✅ SUDAH SIAP
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Dashboard")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Bus ID: ${widget.busId}"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: const Text("Mulai Jalan"),
            ),
          ],
        ),
      ),
    );
  }
}