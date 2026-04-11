import 'dart:convert';
import 'package:ebus_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ManajemenJadwalPage extends StatefulWidget {
  final int companyId;
  const ManajemenJadwalPage({super.key, required this.companyId});

  @override
  State<ManajemenJadwalPage> createState() => _ManajemenJadwalPageState();
}

class _ManajemenJadwalPageState extends State<ManajemenJadwalPage> {
  List<Map<String, dynamic>> _schedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
  }

  Future<void> _fetchSchedules() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse("${ApiService.baseUrl}/api/schedules?company_id=${widget.companyId}"));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          _schedules = List<Map<String, dynamic>>.from(decoded['data'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Fungsi Tambah Jadwal (Singkat)
  void _showAddScheduleDialog() {
    // Di sini kamu butuh Dropdown untuk memilih Bus dan Rute yang sudah ada di database
    // Dan Input untuk Tanggal, Jam, dan Harga.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tambah Jadwal Keberangkatan"),
        content: const Text("Form input Bus, Rute, Jam, dan Harga di sini..."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(onPressed: () {}, child: const Text("Simpan Jadwal")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(title: const Text("Jadwal Keberangkatan"), backgroundColor: Colors.orange),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _schedules.length,
            itemBuilder: (context, index) {
              final item = _schedules[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.event_note, color: Colors.blue),
                  title: Text("${item['nama_rute']} (${item['plat_nomor']})"),
                  subtitle: Text("Waktu: ${item['tanggal_berangkat']} - ${item['jam_berangkat']}\nHarga: Rp ${item['harga_tiket']}"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigasi ke halaman detail kursi untuk jadwal ini
                  },
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddScheduleDialog,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }
}