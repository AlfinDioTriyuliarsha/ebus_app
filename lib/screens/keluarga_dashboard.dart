import 'package:flutter/material.dart';

class KeluargaDashboard extends StatelessWidget {
  final String email;
  const KeluargaDashboard({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Keluarga Dashboard")),
      body: Center(
        child: Text(
          "Selamat datang Keluarga\n$email",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
