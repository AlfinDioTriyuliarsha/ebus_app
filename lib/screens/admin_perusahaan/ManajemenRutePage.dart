import 'package:flutter/material.dart';

class ManajemenRutePage extends StatelessWidget {
  final int companyId;
  const ManajemenRutePage({super.key, required this.companyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manajemen Rute")),
      body: const Center(child: Text("Rute Keberangkatan")),
    );
  }
}
