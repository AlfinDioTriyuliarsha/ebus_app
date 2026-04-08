import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ebus_app/services/api_service.dart';

class ManajemenAgentPage extends StatefulWidget {
  final int companyId;
  const ManajemenAgentPage({super.key, required this.companyId});

  @override
  State<ManajemenAgentPage> createState() => _ManajemenAgentPageState();
}

class _ManajemenAgentPageState extends State<ManajemenAgentPage> {
  List<dynamic> _agents = [];
  bool _isLoading = true;

  // Controller untuk Form
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _hpController = TextEditingController();
  final TextEditingController _lokasiController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAgents();
  }

  // ================= READ =================
  Future<void> _fetchAgents() async {
    try {
      final res = await http.get(
        Uri.parse(
          "${ApiService.baseUrl}/api/company/${widget.companyId}/agents",
        ),
      );
      if (res.statusCode == 200) {
        setState(() {
          _agents = jsonDecode(res.body)['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // ================= CREATE / UPDATE DIALOG =================
  void _showForm(int? index) {
    if (index != null) {
      _namaController.text = _agents[index]['nama_agent'];
      _hpController.text = _agents[index]['no_hp'];
      _lokasiController.text = _agents[index]['lokasi'];
    } else {
      _namaController.clear();
      _hpController.clear();
      _lokasiController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(index == null ? "Tambah Agent" : "Edit Agent"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _namaController,
              decoration: const InputDecoration(labelText: "Nama Agent"),
            ),
            TextField(
              controller: _hpController,
              decoration: const InputDecoration(labelText: "Nomor HP"),
            ),
            TextField(
              controller: _lokasiController,
              decoration: const InputDecoration(
                labelText: "Lokasi (Terminal, Kota, Prov)",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              // Di sini nanti panggil fungsi pendaftaran ke API
              Navigator.pop(context);
              _fetchAgents(); // Refresh data
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 10, bottom: 20),
          child: Text(
            "MANAJEMEN AGENT",
            style: TextStyle(
              color: Color(0xFF004D74),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: _agents.length,
                          itemBuilder: (context, index) =>
                              _buildAgentCard(index),
                        ),
                      ),
                      const SizedBox(height: 15),
                      // TOMBOL TAMBAH (+)
                      _buildAddButton(),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgentCard(int index) {
    var agent = _agents[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                _buildInfoRow("Nama", agent['nama_agent'] ?? "-"),
                _buildInfoRow("Nomor HP", agent['no_hp'] ?? "-"),
                _buildInfoRow("Lokasi", agent['lokasi'] ?? "-"),
              ],
            ),
          ),
          // BUTTON ACTION (EDIT & DELETE)
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _showForm(index),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const Text(" :  "),
        Expanded(child: Text(value)),
      ],
    );
  }

  Widget _buildAddButton() {
    return InkWell(
      onTap: () => _showForm(null),
      child: Container(
        width: double.infinity,
        height: 45,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Icon(Icons.add, color: Color(0xFF004D74), size: 30),
      ),
    );
  }
}
