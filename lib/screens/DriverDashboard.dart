import 'package:flutter/material.dart';

class DriverDashboard extends StatelessWidget {
  final String email;
  final int busId;

  const DriverDashboard({
    super.key,
    required this.email,
    required this.busId,
  });

  @override
  Widget build(BuildContext context) {
    // 🚨 kalau belum dapat bus
    if (busId == 0) {
      return Scaffold(
        appBar: AppBar(title: const Text("Driver Dashboard")),
        body: const Center(
          child: Text(
            "⚠️ Anda belum mendapat bus dari admin",
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    // ✅ kalau sudah ada bus
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Dashboard")),
      body: Center(
        child: Text(
          "✅ Bus ID: $busId",
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}