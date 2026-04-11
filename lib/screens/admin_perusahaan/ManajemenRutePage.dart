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
  String? _error;

  String get baseUrl => "${ApiService.baseUrl}/api/routes";

  @override
  void initState() {
    super.initState();
    _fetchRoutes();
  }

  Future<void> _fetchRoutes() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Mengambil rute berdasarkan company_id agar tidak bercampur dengan perusahaan lain
      final response = await http.get(
        Uri.parse("$baseUrl?company_id=${widget.companyId}"),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List rawData = (decoded is Map && decoded.containsKey('data'))
            ? decoded['data']
            : (decoded is List ? decoded : []);

        if (mounted) {
          setState(() {
            _routes = List<Map<String, dynamic>>.from(rawData);
            _isLoading = false;
            _error = null;
          });
        }
      } else {
        throw "Gagal memuat rute (${response.statusCode})";
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _processRoute({
    int? id,
    required String namaRute,
    required String asal,
    required String tujuan,
    required String jarak,
  }) async {
    try {
      final data = {
        "company_id": widget.companyId,
        "nama_rute": namaRute.trim(),
        "titik_awal": asal.trim(),
        "titik_tujuan": tujuan.trim(),
        "jarak_estimasi": jarak.trim(),
      };

      final response = id == null
          ? await http.post(
              Uri.parse(baseUrl),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode(data),
            )
          : await http.put(
              Uri.parse("$baseUrl/$id"),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode(data),
            );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) Navigator.pop(context);
        _fetchRoutes();
      } else {
        _showAlert("Gagal memproses rute");
      }
    } catch (e) {
      _showAlert("Error: $e");
    }
  }

  Future<void> _deleteRoute(int id) async {
    try {
      final response = await http.delete(Uri.parse("$baseUrl/$id"));
      if (response.statusCode == 200) {
        _fetchRoutes();
      } else {
        _showAlert("Gagal menghapus rute");
      }
    } catch (e) {
      _showAlert("Error: $e");
    }
  }

  void _showAlert(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showRouteDialog({Map<String, dynamic>? route}) {
    final namaCtrl = TextEditingController(text: route?['nama_rute'] ?? "");
    final asalCtrl = TextEditingController(text: route?['titik_awal'] ?? "");
    final tujuanCtrl = TextEditingController(
      text: route?['titik_tujuan'] ?? "",
    );
    final jarakCtrl = TextEditingController(
      text: route?['jarak_estimasi'] ?? "",
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(route == null ? "Tambah Rute Baru" : "Edit Rute"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInput(namaCtrl, "Nama Rute (Contoh: Surabaya - Malang)"),
              _buildInput(asalCtrl, "Titik Keberangkatan"),
              _buildInput(tujuanCtrl, "Titik Tujuan"),
              _buildInput(jarakCtrl, "Estimasi Jarak/Waktu (KM/Jam)"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => _processRoute(
              id: route?['id'],
              namaRute: namaCtrl.text,
              asal: asalCtrl.text,
              tujuan: tujuanCtrl.text,
              jarak: jarakCtrl.text,
            ),
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Manajemen Rute & Zona",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showRouteDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text("Tambah Rute"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : _routes.isEmpty
                ? const Center(child: Text("Belum ada rute yang terdaftar."))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _routes.length,
                    itemBuilder: (context, index) {
                      final rute = _routes[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(15),
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFE0F2FE),
                            child: Icon(Icons.map, color: Colors.blue),
                          ),
                          title: Text(
                            rute['nama_rute'] ?? "Rute Tanpa Nama",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 5),
                              Text("Asal: ${rute['titik_awal'] ?? '-'}"),
                              Text("Tujuan: ${rute['titik_tujuan'] ?? '-'}"),
                              Text(
                                "Estimasi: ${rute['jarak_estimasi'] ?? '-'}",
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _showRouteDialog(route: rute),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteRoute(rute['id']),
                              ),
                            ],
                          ),
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
