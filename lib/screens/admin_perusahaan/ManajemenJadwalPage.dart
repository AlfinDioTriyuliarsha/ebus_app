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

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
    _fetchBus();
  }

  // ================= BUS =================
  Future<void> _fetchBus() async {
    try {
      final res = await http.get(
        Uri.parse(
          "${ApiService.baseUrl}/api/buses?company_id=${widget.companyId}",
        ),
      );

      if (res.statusCode == 200) {
        final data = List<Map<String, dynamic>>.from(
          jsonDecode(res.body)['data'] ?? [],
        );

        // 🔥 FILTER: hanya bus aktif & ada driver
        _busList = data.where((b) {
          return b['status'] == "Aktif" && b['driver_id'] != null;
        }).toList();

        setState(() {});
      }
    } catch (e) {
      debugPrint("Error fetch bus: $e");
    }
  }

  // ================= SCHEDULE =================
  Future<void> _fetchSchedules() async {
    setState(() => _isLoading = true);

    try {
      final res = await http.get(
        Uri.parse(
          "${ApiService.baseUrl}/api/schedules?company_id=${widget.companyId}",
        ),
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        _schedules = List<Map<String, dynamic>>.from(decoded['data'] ?? []);
      }
    } catch (e) {
      debugPrint("Error fetch schedule: $e");
    }

    setState(() => _isLoading = false);
  }

  // ================= FORMAT RUPIAH =================
  String formatRupiah(String number) {
    if (number.isEmpty) return "";
    final n = int.tryParse(number.replaceAll(".", "")) ?? 0;
    return n.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ".",
    );
  }

  // ================= STORE =================
  Future<void> _storeSchedule(
    int? busId,
    String tgl,
    String jam,
    String harga,
  ) async {
    if (busId == null || tgl.isEmpty || jam.isEmpty || harga.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Lengkapi semua data!")));
      return;
    }

    try {
      final res = await http.post(
        Uri.parse("${ApiService.baseUrl}/api/schedules"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "company_id": widget.companyId,
          "bus_id": busId,
          "tanggal_berangkat": tgl,
          "jam_berangkat": jam,
          "harga_tiket": harga.replaceAll(".", ""),
        }),
      );

      if (res.statusCode == 201) {
        if (!mounted) return;

        Navigator.pop(context);
        _fetchSchedules();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Jadwal berhasil disimpan")),
        );
      }
    } catch (e) {
      debugPrint("Error store schedule: $e");
    }
  }

  // ================= DIALOG =================
  void _showAddScheduleDialog() {
    int? selectedBus;

    final tglCtrl = TextEditingController();
    final jamCtrl = TextEditingController();
    final hargaCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Tambah Jadwal"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                // BUS
                DropdownButtonFormField<int>(
                  hint: const Text("Pilih Bus"),
                  items: _busList.map((b) {
                    return DropdownMenuItem<int>(
                      value: b['id'],
                      child: Text("${b['nomor_bus']} - ${b['plat_nomor']}"),
                    );
                  }).toList(),
                  onChanged: (val) => setDialogState(() => selectedBus = val),
                ),

                // TANGGAL
                TextField(
                  controller: tglCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: "Tanggal"),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );

                    if (date != null) {
                      tglCtrl.text = "${date.year}-${date.month}-${date.day}";
                    }
                  },
                ),

                // JAM
                TextField(
                  controller: jamCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: "Jam"),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );

                    if (time != null) {
                      jamCtrl.text =
                          "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
                    }
                  },
                ),

                // HARGA
                TextField(
                  controller: hargaCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Harga"),
                  onChanged: (val) {
                    final formatted = formatRupiah(val);
                    hargaCtrl.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(
                        offset: formatted.length,
                      ),
                    );
                  },
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
                tglCtrl.text,
                jamCtrl.text,
                hargaCtrl.text,
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
      appBar: AppBar(
        title: const Text("Manajemen Jadwal"),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _schedules.isEmpty
          ? const Center(child: Text("Belum ada jadwal"))
          : ListView.builder(
              itemCount: _schedules.length,
              itemBuilder: (context, i) {
                final s = _schedules[i];
                return Card(
                  child: ListTile(
                    title: Text("${s['plat_nomor'] ?? '-'}"),
                    subtitle: Text(
                      "${s['tanggal_berangkat']} ${s['jam_berangkat']}\nRp ${formatRupiah(s['harga_tiket'].toString())}",
                    ),
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
