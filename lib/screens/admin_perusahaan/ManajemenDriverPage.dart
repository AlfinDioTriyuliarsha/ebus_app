import 'package:flutter/material.dart';

class ManajemenDriverPage extends StatelessWidget {
  final int companyId;
  const ManajemenDriverPage({super.key, required this.companyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manajemen Driver")),
      body: const Center(child: Text("Data Sopir Bus")),
    );
  }
}