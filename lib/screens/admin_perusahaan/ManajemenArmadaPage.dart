import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ebus_app/services/api_service.dart';

class ManajemenArmadaPage extends StatefulWidget {
  final int companyId;
  const ManajemenArmadaPage({super.key, required this.companyId});

  @override
  State<ManajemenArmadaPage> createState() => _ManajemenArmadaPageState();
}

class _ManajemenArmadaPageState extends State<ManajemenArmadaPage> {
  List<dynamic> _buses = [];
  List<dynamic> _availableDrivers = [];
  bool _isLoading = true;
  String _selectedFilter = "Semua";

  // Controller untuk Form
  final TextEditingController _noBusController = TextEditingController();
  final TextEditingController _platController = TextEditingController();
  final TextEditingController _mesinController = TextEditingController();
  final TextEditingController _ruteBerangkatController =
      TextEditingController();
  final TextEditingController _ruteTujuanController = TextEditingController();

  int? _selectedDriverId;
  String _selectedStatus = "Aktif";

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // Ambil Data Bus & Driver Tersedia
  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([_fetchBuses(), _fetchAvailableDrivers()]);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchBuses() async {
    final res = await http.get(
      Uri.parse("${ApiService.baseUrl}/api/company/${widget.companyId}/buses"),
    );
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      _buses = decoded['data'];
    }
  }

  Future<void> _fetchAvailableDrivers() async {
    final res = await http.get(
      Uri.parse(
        "${ApiService.baseUrl}/api/company/${widget.companyId}/available-drivers",
      ),
    );
    if (res.statusCode == 200) {
      _availableDrivers = jsonDecode(res.body)['data'];
    }
  }

  // ================= CRUD OPERATIONS =================

  Future<void> _saveBus({int? busId}) async {
    final url = busId == null
        ? "${ApiService.baseUrl}/api/company/${widget.companyId}/buses"
        : "${ApiService.baseUrl}/api/company/${widget.companyId}/buses/$busId";

    // Memastikan data yang dikirim sesuai dengan database
    final body = jsonEncode({
      "driver_id": _selectedDriverId, 
      "nomor_bus": _noBusController.text,
      "plat_nomor": _platController.text,
      "mesin": _mesinController.text,
      "rute_berangkat": _ruteBerangkatController.text,
      "rute_tujuan": _ruteTujuanController.text,
      "status": _selectedStatus,
    });

    try {
      final res = busId == null
          ? await http.post(
              Uri.parse(url),
              headers: {"Content-Type": "application/json"},
              body: body,
            )
          : await http.put(
              Uri.parse(url),
              headers: {"Content-Type": "application/json"},
              body: body,
            );

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) {
          _showSnackBar("✅ Data Armada Berhasil Disimpan");
          _fetchData(); // Refresh daftar bus
        }
      } else {
        // Menangkap pesan error dari server
        final errorData = jsonDecode(res.body);
        _showSnackBar("❌ Gagal: ${errorData['error'] ?? 'Terjadi kesalahan server'}");
      }
    } catch (e) {
      _showSnackBar("❌ Kesalahan Koneksi: $e");
    }
  }

  Future<void> _deleteBus(int id) async {
    final res = await http.delete(
      Uri.parse(
        "${ApiService.baseUrl}/api/company/${widget.companyId}/buses/$id",
      ),
    );
    if (res.statusCode == 200) {
      _showSnackBar("Armada Berhasil Dihapus");
      _fetchData();
    }
  }

  // ================= UI HELPERS =================

  void _showForm({Map? bus}) {
    if (bus != null) {
      _noBusController.text = bus['nomor_bus'];
      _platController.text = bus['plat_nomor'];
      _mesinController.text = bus['mesin'] ?? "";
      _ruteBerangkatController.text = bus['rute_berangkat'] ?? "";
      _ruteTujuanController.text = bus['rute_tujuan'] ?? "";
      _selectedDriverId = bus['driver_id'];
      _selectedStatus = bus['status'];
    } else {
      _noBusController.clear();
      _platController.clear();
      _mesinController.clear();
      _ruteBerangkatController.clear();
      _ruteTujuanController.clear();
      _selectedDriverId = null;
      _selectedStatus = "Aktif";
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(bus == null ? "Tambah Armada" : "Edit Armada"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: _availableDrivers.any((d) => d['id'] == _selectedDriverId) 
                        ? _selectedDriverId 
                        : null, // Jika ID lama tidak ada di list baru, set null
                  decoration: const InputDecoration(labelText: "Pilih Driver (Batangan)"),
                  items: [
                    const DropdownMenuItem<int>(value: null, child: Text("Tanpa Driver")), // Tambahkan opsi null
                    ..._availableDrivers.map((d) {
                      return DropdownMenuItem<int>(
                        value: d['id'],
                        child: Text(d['driver_name'] ?? "Tanpa Nama"),
                      );
                    }),
                  ],
                  onChanged: (val) => setDialogState(() => _selectedDriverId = val),
                ),
                TextField(
                  controller: _noBusController,
                  decoration: const InputDecoration(labelText: "Nomor Bus"),
                ),
                TextField(
                  controller: _platController,
                  decoration: const InputDecoration(labelText: "Plat Nomor"),
                ),
                TextField(
                  controller: _mesinController,
                  decoration: const InputDecoration(labelText: "Mesin"),
                ),
                TextField(
                  controller: _ruteBerangkatController,
                  decoration: const InputDecoration(
                    labelText: "Rute Berangkat",
                  ),
                ),
                TextField(
                  controller: _ruteTujuanController,
                  decoration: const InputDecoration(labelText: "Rute Tujuan"),
                ),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(labelText: "Status"),
                  items:
                      ["Aktif", "Non Aktif", "Tidak Ada Driver", "Maintenance"]
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                  onChanged: (val) =>
                      setDialogState(() => _selectedStatus = val!),
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
                // Validasi input sederhana di sisi Flutter
                if (_noBusController.text.isEmpty || _platController.text.isEmpty) {
                  _showSnackBar("Nomor Bus dan Plat Nomor wajib diisi!");
                  return; 
                }
                
                Navigator.pop(context); // Tutup dialog
                _saveBus(busId: bus?['id']); // Jalankan fungsi simpan
              },
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    // Logika Filter
    List<dynamic> filteredBuses = _selectedFilter == "Semua"
        ? _buses
        : _buses.where((b) => b['status'] == _selectedFilter).toList();

    return Column(
      children: [
        // Header dengan Filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "MANAJEMEN ARMADA",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF004D74),
                ),
              ),
              DropdownButton<String>(
                value: _selectedFilter,
                underline: Container(),
                icon: const Icon(Icons.filter_list, color: Color(0xFF004D74)),
                items:
                    [
                          "Semua",
                          "Aktif",
                          "Non Aktif",
                          "Tidak Ada Driver",
                          "Maintenance",
                        ]
                        .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                onChanged: (val) => setState(() => _selectedFilter = val!),
              ),
            ],
          ),
        ),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredBuses.isEmpty
              ? const Center(child: Text("Tidak ada data armada"))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: filteredBuses.length,
                  itemBuilder: (context, index) {
                    final bus = filteredBuses[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.directions_bus,
                          color: Color(0xFF004D74),
                          size: 40,
                        ),
                        title: Text(
                          "${bus['nomor_bus']} - ${bus['plat_nomor']}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Driver: ${bus['driver_name'] ?? 'Belum ada'}\nRute: ${bus['rute_berangkat']} -> ${bus['rute_tujuan']}",
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showForm(bus: bus),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteBus(bus['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Floating Add Button Style
        Padding(
          padding: const EdgeInsets.all(15),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF004D74),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () => _showForm(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Tambah Armada Baru",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
