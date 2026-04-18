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

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initLoad();
  }

  Future<void> _initLoad() async {
    await Future.wait([_fetchSchedules(), _fetchBus()]);
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
        final data = jsonDecode(res.body);

        setState(() {
          _busList = List<Map<String, dynamic>>.from(data['data'] ?? []);
        });

        debugPrint("BUS DATA: $_busList");
      }
    } catch (e) {
      debugPrint("Error bus: $e");
    }
  }

  // ================= GET =================
  Future<void> _fetchSchedules() async {
    setState(() => _isLoading = true);

    try {
      final res = await http.get(
        Uri.parse(
          "${ApiService.baseUrl}/api/schedules?company_id=${widget.companyId}",
        ),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        setState(() {
          _schedules = List<Map<String, dynamic>>.from(data['data'] ?? []);
        });
      }
    } catch (e) {
      debugPrint("Error jadwal: $e");
    }

    setState(() => _isLoading = false);
  }

  // ================= CREATE / UPDATE =================
  Future<void> _submitSchedule({
    int? id,
    required int busId,
    required int routeId,
    required String tanggal,
    required String jam,
    required String harga,
  }) async {
    try {
      final url = id == null
          ? "${ApiService.baseUrl}/api/schedules"
          : "${ApiService.baseUrl}/api/schedules/$id";

      final body = {
        "company_id": widget.companyId,
        "bus_id": busId,
        "route_id": routeId,
        "tanggal_berangkat": tanggal,
        "jam_berangkat": jam,
        "harga_tiket": int.parse(harga.replaceAll(".", "")),
      };

      debugPrint("KIRIM: $body");

      final response = id == null
          ? await http.post(
              Uri.parse(url),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode(body),
            )
          : await http.put(
              Uri.parse(url),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode(body),
            );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context);
        await _fetchSchedules();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(id == null ? "Berhasil tambah" : "Berhasil update"),
          ),
        );
      } else {
        debugPrint("ERROR: ${response.body}");

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal: ${response.body}")));
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // ================= DELETE =================
  Future<void> _deleteSchedule(int id) async {
    try {
      final res = await http.delete(
        Uri.parse("${ApiService.baseUrl}/api/schedules/$id"),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        await _fetchSchedules();

        ScaffoldMessenger.of(
          // ignore: use_build_context_synchronously
          context,
        ).showSnackBar(const SnackBar(content: Text("Berhasil hapus")));
      }
    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

  // ================= DIALOG =================
  void _showDialog({Map<String, dynamic>? data}) {
    int? selectedBus;
    int? selectedRoute;

    if (data != null) {
      selectedBus = int.tryParse(data['bus_id'].toString());
      selectedRoute = int.tryParse(data['route_id'].toString());
    }

    final tglCtrl = TextEditingController(text: data?['tanggal_berangkat']);
    final jamCtrl = TextEditingController(text: data?['jam_berangkat']);
    final hargaCtrl = TextEditingController(
      text: data?['harga_tiket']?.toString(),
    );

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (_, setStateDialog) => AlertDialog(
          title: Text(data == null ? "Tambah Jadwal" : "Edit Jadwal"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  value: selectedBus,
                  hint: const Text("Pilih Bus"),
                  isExpanded: true,
                  items: _busList.map<DropdownMenuItem<int>>((b) {
                    return DropdownMenuItem<int>(
                      value: int.parse(b['id'].toString()),
                      child: Text("${b['plat_nomor']}"),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setStateDialog(() {
                      selectedBus = val;

                      final bus = _busList.firstWhere(
                        (e) => int.parse(e['id'].toString()) == val,
                      );

                      selectedRoute = bus['route_id'];

                      debugPrint("BUS DIPILIH: $selectedBus");
                      debugPrint("ROUTE AUTO: $selectedRoute");
                    });
                  },
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: tglCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: "Tanggal"),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                      initialDate: DateTime.now(),
                    );
                    if (picked != null) {
                      tglCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                    }
                  },
                ),

                TextField(
                  controller: jamCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: "Jam"),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null && mounted) {
                      jamCtrl.text = picked.format(context);
                    }
                  },
                ),

                TextField(
                  controller: hargaCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Harga"),
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
              onPressed: () {
                if (selectedBus == null || selectedRoute == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Bus / Route belum valid")),
                  );
                  return;
                }

                _submitSchedule(
                  id: data?['id'],
                  busId: selectedBus!,
                  routeId: selectedRoute!,
                  tanggal: tglCtrl.text,
                  jam: jamCtrl.text,
                  harga: hargaCtrl.text,
                );
              },
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
          : ListView.builder(
              itemCount: _schedules.length,
              itemBuilder: (_, i) {
                final s = _schedules[i];

                return Card(
                  child: ListTile(
                    title: Text(s['plat_nomor'] ?? "-"),
                    subtitle: Text(
                      "${s['tanggal_berangkat']} | ${s['jam_berangkat']}\nRp ${s['harga_tiket']}",
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showDialog(data: s),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteSchedule(s['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }
}
