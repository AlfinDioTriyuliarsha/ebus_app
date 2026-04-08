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
          } else {
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
          "agent_name": _namaController.text,
          "lokasi": _lokasiController.text,
          "kontak": _hpController.text,
        }),
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        _showSnackBar("Agent berhasil ditambahkan!");
        _fetchAgents();
      } else {
        _showSnackBar("Gagal menyimpan: ${res.body}");
      }
    } catch (e) {
      _showSnackBar("Error saat menyimpan: $e");
    }
  }

  // ================= UPDATE DATA (PUT) =================
  Future<void> _updateAgent(dynamic agentId) async { 
  try {
    final res = await http.put(
      Uri.parse("${ApiService.baseUrl}/api/company/${widget.companyId}/agents/$agentId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "agent_name": _namaController.text,
        "lokasi": _lokasiController.text,
        "kontak": _hpController.text,
      }),
    );

      if (res.statusCode == 200) {
        _showSnackBar("Agent berhasil diperbarui!");
        _fetchAgents();
      } else {
        _showSnackBar("Gagal memperbarui data");
      }
    } catch (e) {
      _showSnackBar("Error: $e");
    }
  }

  // ================= DELETE DATA (DELETE) =================
  Future<void> _deleteAgent(int agentId) async {
    try {
    final res = await http.delete(
      Uri.parse("${ApiService.baseUrl}/api/company/${widget.companyId}/agents/$agentId"),
    );

      if (res.statusCode == 200) {
        _showSnackBar("Agent berhasil dihapus");
        _fetchAgents();
      } else {
        _showSnackBar("Gagal menghapus data");
      }
    } catch (e) {
      _showSnackBar("Error: $e");
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ================= POPUP DIALOGS =================
  void _showKonfirmasiHapus(int agentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Agent?"),
        content: const Text("Data ini akan dihapus permanen."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deleteAgent(agentId);
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showForm(int? index) {
    int? currentAgentId;
    if (index != null) {
      currentAgentId = _agents[index]['id'];
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
                decoration: const InputDecoration(labelText: "Kontak"),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: _lokasiController,
                decoration: const InputDecoration(labelText: "Lokasi"),
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
                _showKonfirmasiSimpan(currentAgentId!);
              }
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showKonfirmasiSimpan(int agentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Simpan Perubahan?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateAgent(agentId);
            },
            child: const Text("Ya, Simpan"),
          ),
        ],
      ),
    );
  }

  // ================= UI BUILDERS =================
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
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        title: Text(
          agent['agent_name'] ?? "-",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("${agent['lokasi'] ?? "-"} (${agent['kontak'] ?? "-"})"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showForm(index),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showKonfirmasiHapus(agent['id']),
            ),
          ],
        ),
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
