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

  // ================= READ DATA (GET) =================
  Future<void> _fetchAgents() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(
        Uri.parse(
          "${ApiService.baseUrl}/api/company/${widget.companyId}/agents",
        ),
      );

      if (res.statusCode == 200) {
        final decodedData = jsonDecode(res.body);
        setState(() {
          if (decodedData is Map && decodedData.containsKey('data')) {
            _agents = decodedData['data'];
          } else if (decodedData is List) {
            _agents = decodedData;
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showSnackBar("Gagal mengambil data: Kode ${res.statusCode}");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Terjadi kesalahan jaringan: $e");
    }
  }

  // ================= CREATE DATA (POST) =================
  Future<void> _addAgent() async {
    if (_namaController.text.isEmpty) {
      _showSnackBar("Nama Agent tidak boleh kosong");
      return;
    }

    try {
      final res = await http.post(
        Uri.parse(
          "${ApiService.baseUrl}/api/company/${widget.companyId}/agents",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "agent_name": _namaController.text, // Sesuai dengan field di Node.js
          "lokasi": _lokasiController.text,
          "kontak": _hpController.text,
        }),
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        _showSnackBar("Agent berhasil ditambahkan!");
        _fetchAgents(); // Refresh list
      } else {
        _showSnackBar("Gagal menyimpan: ${res.body}");
      }
    } catch (e) {
      _showSnackBar("Error saat menyimpan: $e");
    }
  }

  // Helper untuk menampilkan pesan
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ================= FORM DIALOG =================
  void _showForm(int? index) {
    if (index != null) {
      // Logic Edit (jika ingin dikembangkan)
      _namaController.text = _agents[index]['agent_name'] ?? "";
      _hpController.text = _agents[index]['kontak'] ?? "";
      _lokasiController.text = _agents[index]['lokasi'] ?? "";
    } else {
      _namaController.clear();
      _hpController.clear();
      _lokasiController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(index == null ? "Tambah Agent" : "Edit Agent"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: "Nama Agent"),
              ),
              TextField(
                controller: _hpController,
                decoration: const InputDecoration(
                  labelText: "Nomor HP / Kontak",
                ),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: _lokasiController,
                decoration: const InputDecoration(
                  labelText: "Lokasi (Terminal/Kota)",
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF004D74),
            ),
            onPressed: () {
              Navigator.pop(context);
              if (index == null) {
                _addAgent();
              } else {
                // Fungsi update bisa ditambahkan di sini
              }
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
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
                        child: _agents.isEmpty
                            ? const Center(child: Text("Belum ada data agent"))
                            : ListView.builder(
                                itemCount: _agents.length,
                                itemBuilder: (context, index) =>
                                    _buildAgentCard(index),
                              ),
                      ),
                      const SizedBox(height: 15),
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
                _buildInfoRow("Nama", agent['agent_name'] ?? "-"),
                _buildInfoRow("Kontak", agent['kontak'] ?? "-"),
                _buildInfoRow("Lokasi", agent['lokasi'] ?? "-"),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _showForm(index),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  // Tambahkan fungsi delete di sini jika diperlukan
                },
              ),
            ],
          ),
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
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Text(" :  "),
          Expanded(child: Text(value)),
        ],
      ),
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
