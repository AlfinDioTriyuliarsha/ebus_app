import 'package:flutter/material.dart';

class PenumpangDashboard extends StatelessWidget {
  final String email;
  const PenumpangDashboard({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Penumpang Dashboard")),
      body: Center(
        child: Text(
          "Selamat datang Penumpang\n$email",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
