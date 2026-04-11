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
  List<Map<String, dynamic>> _busList = [];
  List<Map<String, dynamic>> _routeList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
    _fetchSupportData();
  }

  // 1. Ambil Data Bus dan Rute untuk Dropdown
  Future<void> _fetchSupportData() async {
    try {
      final resBus = await http.get(Uri.parse("${ApiService.baseUrl}/api/buses?company_id=${widget.companyId}"));
      final resRoute = await http.get(Uri.parse("${ApiService.baseUrl}/api/routes?company_id=${widget.companyId}"));
      
      if (resBus.statusCode == 200 && resRoute.statusCode == 200) {
        setState(() {
          _busList = List<Map<String, dynamic>>.from(jsonDecode(resBus.body)['data'] ?? []);
          _routeList = List<Map<String, dynamic>>.from(jsonDecode(resRoute.body)['data'] ?? []);
        });
      }
    } catch (e) {
      print("Error fetch data pendukung: $e");
    }
  }

  // 2. Ambil Data List Jadwal
  Future<void> _fetchSchedules() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/api/schedules?company_id=${widget.companyId}"),
      );
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

  // 3. Fungsi Simpan Jadwal ke Backend
  Future<void> _storeSchedule(int? busId, int? routeId, String tgl, String jam, String harga) async {
    if (busId == null || routeId == null || tgl.isEmpty || jam.isEmpty || harga.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lengkapi semua data!")));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/api/schedules"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "company_id": widget.companyId,
          "bus_id": busId,
          "route_id": routeId,
          "tanggal_berangkat": tgl,
          "jam_berangkat": jam,
          "harga_tiket": harga,
        }),
      );

      if (response.statusCode == 201) {
        if (!mounted) return;
        Navigator.pop(context); // Tutup dialog
        _fetchSchedules(); // Refresh list agar data baru muncul
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Jadwal berhasil disimpan")));
      }
    } catch (e) {
      print("Error simpan jadwal: $e");
    }
  }

  // 4. Dialog Input (Hanya Satu Fungsi)
  void _showAddScheduleDialog() {
    int? selectedBus;
    int? selectedRoute;
    final tglCtrl = TextEditingController();
    final jamCtrl = TextEditingController();
    final hargaCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Tambah Jadwal Baru"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  hint: const Text("Pilih Bus"),
                  items: _busList.map((b) => DropdownMenuItem<int>(
                    value: b['id'], child: Text(b['plat_nomor'] ?? "-"))).toList(),
                  onChanged: (val) => setDialogState(() => selectedBus = val),
                ),
                DropdownButtonFormField<int>(
                  hint: const Text("Pilih Rute"),
                  items: _routeList.map((r) => DropdownMenuItem<int>(
                    value: r['id'], child: Text(r['nama_rute'] ?? "-"))).toList(),
                  onChanged: (val) => setDialogState(() => selectedRoute = val),
                ),
                TextField(controller: tglCtrl, decoration: const InputDecoration(labelText: "Tanggal (YYYY-MM-DD)")),
                TextField(controller: jamCtrl, decoration: const InputDecoration(labelText: "Jam (HH:mm)")),
                TextField(controller: hargaCtrl, decoration: const InputDecoration(labelText: "Harga"), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
            ElevatedButton(
              onPressed: () => _storeSchedule(selectedBus, selectedRoute, tglCtrl.text, jamCtrl.text, hargaCtrl.text),
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text("Jadwal Keberangkatan"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _schedules.isEmpty
              ? const Center(child: Text("Belum ada jadwal keberangkatan."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _schedules.length,
                  itemBuilder: (context, index) {
                    final item = _schedules[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.event_note, color: Colors.blue),
                        title: Text("${item['nama_rute'] ?? 'Rute'} (${item['plat_nomor'] ?? '-'})"),
                        subtitle: Text(
                          "Waktu: ${item['tanggal_berangkat']} - ${item['jam_berangkat']}\nHarga: Rp ${item['harga_tiket']}",
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Navigasi detail
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddScheduleDialog,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}