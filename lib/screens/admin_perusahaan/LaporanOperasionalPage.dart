import 'package:flutter/material.dart';

class LaporanOperasionalPage extends StatelessWidget {
  const LaporanOperasionalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Laporan Operasional")),
      body: const Center(child: Icon(Icons.bar_chart, size: 100, color: Colors.blue)),
    );
  }
}