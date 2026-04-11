import 'dart:convert';
import 'package:ebus_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ManajemenRutePage extends StatefulWidget {
  final int companyId;
  const ManajemenRutePage({super.key, required this.companyId});

  @override
  State<ManajemenRutePage> createState() => _ManajemenRutePageState();
}

class _ManajemenRutePageState extends State<ManajemenRutePage> {
  List<Map<String, dynamic>> _routes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRoutes();
  }

  // Fungsi ambil data
  Future<void> _fetchRoutes() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/api/routes?company_id=${widget.companyId}"),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          _routes = List<Map<String, dynamic>>.from(decoded['data'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Fungsi simpan data ke Node.js
  Future<void> _storeRoute(String nama, String asal, String tujuan, String jarak) async {
    // Validasi input di Flutter
    if (nama.isEmpty || asal.isEmpty || tujuan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Semua field harus diisi!")),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/api/routes"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "company_id": widget.companyId,
          "nama_rute": nama,
          "titik_awal": asal,
          "titik_tujuan": tujuan,
          "jarak_estimasi": jarak,
        }),
      );

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 201) {
        if (!mounted) return;
        Navigator.pop(context); // Tutup dialog
        _fetchRoutes(); // Refresh list agar data baru muncul
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Rute berhasil ditambahkan")),
        );
      } else {
        // Jika gagal, munculkan pesan error dari server
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal: ${errorData['message'] ?? 'Terjadi kesalahan'}")),
        );
      }
    } catch (e) {
      print("Error simpan: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void _showAddDialog() {
    final namaCtrl = TextEditingController();
    final asalCtrl = TextEditingController();
    final tujuanCtrl = TextEditingController();
    final jarakCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tambah Rute Baru"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: namaCtrl, decoration: const InputDecoration(labelText: "Nama Rute")),
            TextField(controller: asalCtrl, decoration: const InputDecoration(labelText: "Titik Awal")),
            TextField(controller: tujuanCtrl, decoration: const InputDecoration(labelText: "Titik Tujuan")),
            TextField(controller: jarakCtrl, decoration: const InputDecoration(labelText: "Estimasi Jarak")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () => _storeRoute(namaCtrl.text, asalCtrl.text, tujuanCtrl.text, jarakCtrl.text),
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Manajemen Rute", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: _showAddDialog,
                  icon: const Icon(Icons.add),
                  label: const Text("Tambah Rute"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _routes.isEmpty
                    ? const Center(child: Text("Data Rute masih kosong."))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _routes.length,
                        itemBuilder: (context, index) {
                          final r = _routes[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.map, color: Colors.blue),
                              title: Text(r['nama_rute']),
                              subtitle: Text("${r['titik_awal']} -> ${r['titik_tujuan']}"),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}