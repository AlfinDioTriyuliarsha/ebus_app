import 'package:flutter/material.dart';

class AdminPerusahaanDashboard extends StatelessWidget {
  final String email;
  const AdminPerusahaanDashboard({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Perusahaan Dashboard")),
      body: Center(
        child: Text(
          "Selamat datang Admin Perusahaan\n$email",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
