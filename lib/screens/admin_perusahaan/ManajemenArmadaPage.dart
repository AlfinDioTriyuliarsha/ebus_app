import 'package:flutter/material.dart';

class ManajemenArmadaPage extends StatelessWidget {
  final int companyId;
  const ManajemenArmadaPage({super.key, required this.companyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manajemen Armada Bus")),
      body: const Center(child: Text("Daftar Bus Perusahaan")),
    );
  }
}