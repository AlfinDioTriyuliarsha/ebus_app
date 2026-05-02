import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ebus_app/services/api_service.dart';

class DriverDashboard extends StatelessWidget {
  final String email;
  final int driverId;
  final int companyId;

  const DriverDashboard({
    super.key,
    required this.email,
    required this.driverId,
    required this.companyId,
  });

  Future<void> sendRequest(BuildContext context) async {
    final res = await http.post(
      Uri.parse("${ApiService.baseUrl}/api/driver-request"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"driver_id": driverId, "company_id": companyId}),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(const SnackBar(content: Text("Request dikirim ke admin")));
    } else {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal: ${res.body}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver Dashboard"),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Selamat datang Driver\n$email", textAlign: TextAlign.center),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                await http.post(
                  Uri.parse("${ApiService.baseUrl}/api/driver-request"),
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode({
                    "driver_id": driverId,
                    "company_id": companyId,
                  }),
                );
              },
              child: Text("Daftar Sebagai Driver"),
            ),
          ],
        ),
      ),
    );
  }
}
