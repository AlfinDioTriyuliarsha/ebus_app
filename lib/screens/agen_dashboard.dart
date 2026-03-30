import 'package:flutter/material.dart';

class AgenDashboard extends StatelessWidget {
  final String email;
  const AgenDashboard({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Agen Dashboard")),
      body: Center(
        child: Text(
          "Selamat datang Agen\n$email",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
