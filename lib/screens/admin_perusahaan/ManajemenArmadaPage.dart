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
  List<dynamic> _routes = [];
  List<dynamic> _schedules = [];
  List<dynamic> _mesinList = [];

  bool _isLoading = true;
  // ignore: prefer_final_fields
  String _selectedFilter = "Semua";

  final TextEditingController _noBusController = TextEditingController();
  final TextEditingController _platController = TextEditingController();

  int? _selectedDriverId;
  int? _selectedRouteId;
  int? _selectedScheduleId;
  int? _selectedMesinId;
  String _selectedStatus = "Aktif";

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
        _fetchMesin(),
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
      Uri.parse(
        "${ApiService.baseUrl}/api/routes?company_id=${widget.companyId}",
      ),
    );
    if (res.statusCode == 200) {
      _routes = jsonDecode(res.body)['data'];
    }
  }

  Future<void> _fetchSchedules() async {
    final res = await http.get(
      Uri.parse(
        "${ApiService.baseUrl}/api/schedules?company_id=${widget.companyId}",
      ),
    );
    if (res.statusCode == 200) {
      _schedules = jsonDecode(res.body)['data'];
    }
  }

  Future<void> _fetchMesin() async {
    final res = await http.get(
      Uri.parse(
        "${ApiService.baseUrl}/api/mesin?company_id=${widget.companyId}",
      ),
    );
    if (res.statusCode == 200) {
      _mesinList = jsonDecode(res.body)['data'];
    }
  }

  // ================= VALIDASI =================
  bool _isPlatDuplicate(String plat, {int? currentId}) {
    return _buses.any(
      (b) =>
          b['plat_nomor'] == plat &&
          (currentId == null || b['id'] != currentId),
    );
  }

  // ================= SAVE =================
  Future<void> _saveBus({int? busId}) async {
    if (_platController.text.isEmpty || _noBusController.text.isEmpty) {
      _showDialog("Error", "Semua field wajib diisi");
      return;
    }

    if (_isPlatDuplicate(_platController.text, currentId: busId)) {
      _showDialog("Error", "Plat nomor sudah digunakan!");
      return;
    }

    final url = busId == null
        ? "${ApiService.baseUrl}/api/company/${widget.companyId}/buses"
        : "${ApiService.baseUrl}/api/company/${widget.companyId}/buses/$busId";

    final body = jsonEncode({
      "driver_id": _selectedDriverId,
      "nomor_bus": _noBusController.text,
      "plat_nomor": _platController.text,
      "mesin": _selectedMesinId,
      "route_id": _selectedRouteId,
      "schedule_id": _selectedScheduleId,
      "status": _selectedStatus,
    });

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

    // ignore: use_build_context_synchronously
    Navigator.pop(context);

    if (res.statusCode == 200 || res.statusCode == 201) {
      _fetchData();
      _showDialog("Sukses", "Data armada berhasil disimpan");
    } else {
      _showDialog("Error", "Gagal menyimpan data");
    }
  }

  Future<void> _deleteBus(int id) async {
    await http.delete(
      Uri.parse(
        "${ApiService.baseUrl}/api/company/${widget.companyId}/buses/$id",
      ),
    );
    _fetchData();
    _showDialog("Sukses", "Data berhasil dihapus");
  }

  // ================= FORM =================
  void _showForm({Map? bus}) {

  if (bus != null) {
    _noBusController.text = bus['nomor_bus'];
    _platController.text = bus['plat_nomor'];

    _selectedDriverId ??= bus['driver_id'];
    _selectedRouteId ??= int.tryParse(bus['route_id'].toString());
    _selectedScheduleId ??= bus['schedule_id'];
    _selectedMesinId ??= bus['mesin'];

    _selectedStatus = bus['status'];
  } else {
    _selectedRouteId = null;
  }
  
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(bus == null ? "Tambah Armada" : "Edit Armada"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<int?>(
                  value: _selectedDriverId,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text("Tanpa Driver"),
                    ),
                    ..._availableDrivers.map<DropdownMenuItem<int?>>((d) {
                      return DropdownMenuItem<int?>(
                        value: d['id'] as int,
                        child: Text(d['driver_name'] ?? "-"),
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

                DropdownButtonFormField<int?>(
                  value: _selectedMesinId,
                  decoration: const InputDecoration(labelText: "Mesin"),
                  items: _mesinList.map<DropdownMenuItem<int?>>((m) {
                    return DropdownMenuItem<int?>(
                      value: m['id'] as int,
                      child: Text(m['nama_mesin']),
                    );
                  }).toList(),
                  onChanged: (val) =>
                      setDialogState(() => _selectedMesinId = val),
                ),

                TextButton(
                  onPressed: _showMesinCRUDDialog,
                  child: const Text("+ Kelola Mesin"),
                ),

                DropdownButtonFormField<int?>(
                  value: _selectedRouteId,
                  items: _routes.map<DropdownMenuItem<int?>>((r) {
                    final id = int.parse(r['id'].toString());

                    return DropdownMenuItem<int?>(
                      value: id,
                      child: Text(
                        "${r['nama_rute']} (${r['titik_awal']} → ${r['titik_tujuan']})",
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    print("ROUTE DIPILIH: $val"); // 🔥 DEBUG DI SINI
                    setDialogState(() {
                      _selectedRouteId = val;
                    });
                  },
                ),

                DropdownButtonFormField<int?>(
                  value: _selectedScheduleId,
                  items: _schedules.map<DropdownMenuItem<int?>>((s) {
                    return DropdownMenuItem<int?>(
                      value: s['id'] as int,
                      child: Text(
                        "${s['route_name']} - ${s['waktu_keberangkatan']}",
                      ),
                    );
                  }).toList(),
                  onChanged: (val) =>
                      setDialogState(() => _selectedScheduleId = val),
                ),

                DropdownButtonFormField<String>(
                  value: _selectedStatus,
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
              onPressed: () => _saveBus(busId: bus?['id']),
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

  void _showDialog(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showMesinCRUDDialog() {
  showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setStateDialog) => AlertDialog(
        title: const Text("Manajemen Mesin"),
        content: SizedBox(
          width: 300,
          height: 300,
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _mesinList.length,
                  itemBuilder: (context, i) {
                    final mesin = _mesinList[i];
                    return ListTile(
                      title: Text(mesin['nama_mesin']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () =>
                                _showEditMesinDialog(mesin),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                _deleteMesin(mesin['id']),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: _showAddMesinDialog,
                child: const Text("Tambah Mesin"),
              )
            ],
          ),
        ),
      ),
    ),
  );
}

  // ================= ADD MESIN =================
  void _showAddMesinDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Tambah Mesin"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Nama Mesin"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              await http.post(
                Uri.parse("${ApiService.baseUrl}/api/mesin"),
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({
                  "company_id": widget.companyId,
                  "nama_mesin": controller.text,
                }),
              );

              // ignore: use_build_context_synchronously
              Navigator.pop(context);
              _fetchMesin();
              _showDialog("Sukses", "Mesin ditambahkan");
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _showEditMesinDialog(Map mesin) {
  final controller = TextEditingController(text: mesin['nama_mesin']);

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Edit Mesin"),
      content: TextField(controller: controller),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Batal"),
        ),
        ElevatedButton(
          onPressed: () async {
            await http.put(
              Uri.parse("${ApiService.baseUrl}/api/mesin/${mesin['id']}"),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({
                "nama_mesin": controller.text,
              }),
            );

            // ignore: use_build_context_synchronously
            Navigator.pop(context);
            _fetchMesin();
            _showDialog("Sukses", "Mesin diperbarui");
          },
          child: const Text("Update"),
        ),
      ],
    ),
  );
}

Future<void> _deleteMesin(int id) async {
  await http.delete(
    Uri.parse("${ApiService.baseUrl}/api/mesin/$id"),
  );

  _fetchMesin();
  _showDialog("Sukses", "Mesin dihapus");
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
                          "${bus['nomor_bus']} - ${bus['plat_nomor']}",
                        ),
                        subtitle: Text("Driver: ${bus['driver_name'] ?? '-'}"),
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
                              onPressed: () => _deleteBus(bus['id']),
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
        ),
      ],
    );
  }
}
