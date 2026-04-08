import 'package:flutter/material.dart';

class PengaturanAkunPage extends StatelessWidget {
  final int userId; // Parameter yang diminta
  const PengaturanAkunPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pengaturan Akun")),
      body: Center(child: Text("Mengatur Akun User ID: $userId")),
    );
  }
}