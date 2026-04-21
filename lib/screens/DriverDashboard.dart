import 'package:flutter/material.dart';

class DriverDashboard extends StatelessWidget {
  final String email;
  const DriverDashboard({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Dashboard")),
      body: Center(
        child: Text(
          "Selamat datang Driver\n$email",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
