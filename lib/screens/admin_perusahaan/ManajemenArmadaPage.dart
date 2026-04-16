import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ebus_app/services/api_service.dart';

class ManajemenArmadaPage extends StatefulWidget {
  final int companyId;
  const ManajemenArmadaPage({super.key, required this.companyId});

  @override
  State<ManajemenArmadaPage> createState() =>
      _ManajemenArmadaPageState();
}

class _ManajemenArmadaPageState extends State<ManajemenArmadaPage> {
  List<dynamic> _buses = [];
  List<dynamic> _availableDrivers = [];
  List<dynamic> _routes = [];
  List<dynamic> _schedules = [];

  bool _isLoading = true;
  // ignore: prefer_final_fields
  String _selectedFilter = "Semua";

  final TextEditingController _noBusController = TextEditingController();
  final TextEditingController _platController = TextEditingController();

  int? _selectedDriverId;
  int? _selectedRouteId;
  int? _selectedScheduleId;
  String _selectedMesin = "Hino";
  String _selectedStatus = "Aktif";

  final List<String> _mesinList = ["Hino", "Mercedes", "Scania", "Volvo"];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchBuses(),
        _fetchAvailableDrivers(),
        _fetchRoutes(),
        _fetchSchedules(),
      ]);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchBuses() async {
    final res = await http.get(
      Uri.parse("${ApiService.baseUrl}/api/company/${widget.companyId}/buses"),
    );
    if (res.statusCode == 200) {
      _buses = jsonDecode(res.body)['data'];
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

  Future<void> _fetchRoutes() async {
    final res = await http.get(
      Uri.parse("${ApiService.baseUrl}/api/routes?company_id=${widget.companyId}"),
    );
    if (res.statusCode == 200) {
      _routes = jsonDecode(res.body)['data'];
    }
  }

  Future<void> _fetchSchedules() async {
    final res = await http.get(
      Uri.parse("${ApiService.baseUrl}/api/schedules?company_id=${widget.companyId}"),
    );
    if (res.statusCode == 200) {
      _schedules = jsonDecode(res.body)['data'];
    }
  }

  // ================= SAVE =================
  Future<void> _saveBus({int? busId}) async {
    final url = busId == null
        ? "${ApiService.baseUrl}/api/company/${widget.companyId}/buses"
        : "${ApiService.baseUrl}/api/company/${widget.companyId}/buses/$busId";

    final body = jsonEncode({
      "driver_id": _selectedDriverId,
      "nomor_bus": _noBusController.text,
      "plat_nomor": _platController.text,
      "mesin": _selectedMesin,
      "route_id": _selectedRouteId,
      "schedule_id": _selectedScheduleId,
      "status": _selectedStatus,
    });

    final res = busId == null
        ? await http.post(Uri.parse(url),
            headers: {"Content-Type": "application/json"}, body: body)
        : await http.put(Uri.parse(url),
            headers: {"Content-Type": "application/json"}, body: body);

    if (res.statusCode == 200 || res.statusCode == 201) {
      _showSnackBar("✅ Berhasil disimpan");
      _fetchData();
    } else {
      _showSnackBar("❌ Gagal");
    }
  }

  Future<void> _deleteBus(int id) async {
    await http.delete(
      Uri.parse("${ApiService.baseUrl}/api/company/${widget.companyId}/buses/$id"),
    );
    _fetchData();
  }

  // ================= FORM =================
  void _showForm({Map? bus}) {
    if (bus != null) {
      _noBusController.text = bus['nomor_bus'];
      _platController.text = bus['plat_nomor'];
      _selectedDriverId = bus['driver_id'];
      _selectedStatus = bus['status'];
      _selectedMesin = bus['mesin'] ?? "Hino";
      _selectedRouteId = bus['route_id'];
      _selectedScheduleId = bus['schedule_id'];
    } else {
      _noBusController.clear();
      _platController.clear();
      _selectedDriverId = null;
      _selectedStatus = "Aktif";
      _selectedRouteId = null;
      _selectedScheduleId = null;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(bus == null ? "Tambah Armada" : "Edit Armada"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                // DRIVER
                DropdownButtonFormField<int?>(
                  value: _selectedDriverId,
                  decoration: const InputDecoration(labelText: "Driver"),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text("Tanpa Driver")),
                    ..._availableDrivers.map<DropdownMenuItem<int?>>((d) {
                      return DropdownMenuItem<int?>(
                        value: d['id'] as int?,
                        child: Text(d['driver_name']),
                      );
                    }),
                  ],
                  onChanged: (val) =>
                      setDialogState(() => _selectedDriverId = val),
                ),

                TextField(
                  controller: _noBusController,
                  decoration: const InputDecoration(labelText: "Nomor Bus"),
                ),

                TextField(
                  controller: _platController,
                  decoration: const InputDecoration(labelText: "Plat Nomor"),
                ),

                // MESIN
                DropdownButtonFormField<String>(
                  value: _selectedMesin,
                  decoration: const InputDecoration(labelText: "Mesin"),
                  items: _mesinList
                      .map((m) =>
                          DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (val) =>
                      setDialogState(() => _selectedMesin = val!),
                ),

                // ROUTE
                DropdownButtonFormField<int?>(
                  value: _selectedRouteId,
                  decoration: const InputDecoration(labelText: "Rute"),
                  items: _routes.map<DropdownMenuItem<int?>>((r) {
                    return DropdownMenuItem<int?>(
                      value: r['id'] as int?,
                      child: Text(
                        "${r['nama_rute']} (${r['titik_awal']} → ${r['titik_tujuan']})"),
                    );
                  }).toList(),
                  onChanged: (val) =>
                      setDialogState(() => _selectedRouteId = val),
                ),

                // SCHEDULE
                DropdownButtonFormField<int?>(
                  value: _selectedScheduleId,
                  decoration: const InputDecoration(labelText: "Jadwal"),
                  items: _schedules.map<DropdownMenuItem<int?>>((s) {
                    return DropdownMenuItem<int?>(
                      value: s['id'] as int?,
                      child: Text(
                        "${s['route_name']} - ${s['waktu_keberangkatan']}"),
                    );
                  }).toList(),
                  onChanged: (val) =>
                      setDialogState(() => _selectedScheduleId = val),
                ),

                // STATUS
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(labelText: "Status"),
                  items: ["Aktif", "Non Aktif", "Tidak Ada Driver", "Maintenance"]
                      .map((s) =>
                          DropdownMenuItem(value: s, child: Text(s)))
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
                child: const Text("Batal")),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _saveBus(busId: bus?['id']);
              },
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  // ================= STATUS COLOR =================
  Color _getStatusColor(String status) {
    switch (status) {
      case "Aktif":
        return Colors.green;
      case "Maintenance":
        return Colors.orange;
      case "Non Aktif":
        return Colors.grey;
      case "Tidak Ada Driver":
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedFilter == "Semua"
        ? _buses
        : _buses.where((b) => b['status'] == _selectedFilter).toList();

    return Column(
      children: [
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final bus = filtered[i];
                    return Card(
                      child: ListTile(
                        title: Text(
                            "${bus['nomor_bus']} - ${bus['plat_nomor']}"),
                        subtitle: Text(
                            "Driver: ${bus['driver_name'] ?? '-'}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(bus['status']),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                bus['status'],
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showForm(bus: bus),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () =>
                                  _deleteBus(bus['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        ElevatedButton(
          onPressed: () => _showForm(),
          child: const Text("Tambah Armada"),
        )
      ],
    );
  }
}