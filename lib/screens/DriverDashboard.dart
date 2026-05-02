import 'package:flutter/material.dart';

class DriverDashboard extends StatelessWidget {
  final String email;
  final int busId;

  const DriverDashboard({super.key, required this.email, required this.busId});

  @override
  Widget build(BuildContext context) {
    if (busId == 0) {
      return Scaffold(
        body: Center(child: Text("⚠️ Anda belum mendapat bus dari admin")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Driver Dashboard")),
      body: Center(child: Text("Bus ID: $busId")),
    );
  }
}
