import 'dart:convert';
import 'package:ebus_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
    _fetchSupportData();
  }

  // ================= FETCH DATA =================
  Future<void> _fetchSupportData() async {
    try {
      final resBus = await http.get(
        Uri.parse(
          "${ApiService.baseUrl}/api/buses?company_id=${widget.companyId}",
        ),
      );
      final resRoute = await http.get(
        Uri.parse(
          "${ApiService.baseUrl}/api/routes?company_id=${widget.companyId}",
        ),
      );

      if (resBus.statusCode == 200 && resRoute.statusCode == 200) {
        final buses = List<Map<String, dynamic>>.from(
          jsonDecode(resBus.body)['data'] ?? [],
        );

        // 🔥 FILTER BUS (AKTIF + ADA DRIVER)
        final filteredBus = buses
            .where((b) => b['status'] == 'Aktif' && b['driver_id'] != null)
            .toList();

        setState(() {
          _busList = filteredBus;
          _routeList = List<Map<String, dynamic>>.from(
            jsonDecode(resRoute.body)['data'] ?? [],
          );
        });
      }
    } catch (e) {
      debugPrint("Error fetch data pendukung: $e");
    }
  }

  Future<void> _fetchSchedules() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(
          "${ApiService.baseUrl}/api/schedules?company_id=${widget.companyId}",
        ),
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

  // ================= SIMPAN =================
  Future<void> _storeSchedule(
    int? busId,
    int? routeId,
    String tgl,
    String jam,
    int harga,
  ) async {
    if (busId == null ||
        routeId == null ||
        tgl.isEmpty ||
        jam.isEmpty ||
        harga <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Lengkapi semua data!")));
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
        Navigator.pop(context);
        _fetchSchedules();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Jadwal berhasil disimpan")),
        );
      }
    } catch (e) {
      debugPrint("Error simpan jadwal: $e");
    }
  }

  // ================= DATE PICKER =================
  Future<void> _pickDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  // ================= TIME PICKER =================
  Future<void> _pickTime(TextEditingController controller) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      final now = DateTime.now();
      final dt = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );
      controller.text = DateFormat('HH:mm').format(dt);
    }
  }

  // ================= FORMAT RUPIAH =================
  void _formatCurrency(TextEditingController controller) {
    String text = controller.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (text.isEmpty) return;

    final number = int.parse(text);
    controller.value = TextEditingValue(
      text: currencyFormatter.format(number),
      selection: TextSelection.collapsed(
        offset: currencyFormatter.format(number).length,
      ),
    );
  }

  int _parseCurrency(String text) {
    return int.parse(text.replaceAll(RegExp(r'[^0-9]'), ''));
  }

  // ================= DIALOG =================
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
              children: [
                DropdownButtonFormField<int>(
                  hint: const Text("Pilih Bus"),
                  items: _busList
                      .map(
                        (b) => DropdownMenuItem<int>(
                          value: b['id'],
                          child: Text("${b['plat_nomor']} (${b['nomor_bus']})"),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setDialogState(() => selectedBus = val),
                ),

                DropdownButtonFormField<int>(
                  hint: const Text("Pilih Rute"),
                  items: _routeList
                      .map(
                        (r) => DropdownMenuItem<int>(
                          value: r['id'],
                          child: Text(r['nama_rute'] ?? "-"),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setDialogState(() => selectedRoute = val),
                ),

                TextField(
                  controller: tglCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: "Tanggal"),
                  onTap: () => _pickDate(tglCtrl),
                ),

                TextField(
                  controller: jamCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: "Jam"),
                  onTap: () => _pickTime(jamCtrl),
                ),

                TextField(
                  controller: hargaCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Harga"),
                  onChanged: (_) => _formatCurrency(hargaCtrl),
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
              onPressed: () => _storeSchedule(
                selectedBus,
                selectedRoute,
                tglCtrl.text,
                jamCtrl.text,
                _parseCurrency(hargaCtrl.text),
              ),
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  // ================= UI =================
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
                    title: Text(
                      "${item['nama_rute'] ?? 'Rute'} (${item['plat_nomor'] ?? '-'})",
                    ),
                    subtitle: Text(
                      "Waktu: ${item['tanggal_berangkat']} - ${item['jam_berangkat']}\nHarga: Rp ${item['harga_tiket']}",
                    ),
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
