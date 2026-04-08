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

  @override
  void initState() {
    super.initState();
    _fetchAgents();
  }

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

  @override
  Widget build(BuildContext context) {
    // Kita tidak pakai Scaffold di sini agar menyatu dengan Dashboard
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
              color: Colors.white, // Background putih di dalam area abu-abu
              borderRadius: BorderRadius.circular(30), // Kelengkungan sesuai UI
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      // List Agent
                      Expanded(
                        child: _agents.isEmpty
                            ? const Center(child: Text("Belum ada data agent"))
                            : ListView.builder(
                                itemCount: _agents.length,
                                itemBuilder: (context, index) =>
                                    _buildAgentCard(_agents[index]),
                              ),
                      ),
                      const SizedBox(height: 15),
                      // Tombol Tambah (+) sesuai desain
                      _buildAddButton(),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // Card untuk setiap item Agent sesuai desain Nama, No HP, Lokasi
  Widget _buildAgentCard(dynamic agent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow("Nama", agent['nama_agent'] ?? "-"),
          _buildInfoRow("Nomor HP", agent['no_hp'] ?? "-"),
          _buildInfoRow("Lokasi", agent['lokasi'] ?? "-"),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF004D74),
              ),
            ),
          ),
          const Text(" :  "),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // Tombol (+) yang ada di bawah desain kamu
  Widget _buildAddButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          // Fungsi Tambah Agent
        },
        child: Container(
          width: double.infinity,
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Icon(Icons.add, color: Color(0xFF004D74), size: 30),
        ),
      ),
    );
  }
}
