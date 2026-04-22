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

  // AUTO ROUTE DATA
  List provinces = [];
  List cities = [];
  List terminals = [];
  List checkpoints = [];

  int? provinceId;
  int? cityId;
  Map? startTerminal;
  Map? endCheckpoint;

  @override
  void initState() {
    super.initState();
    _fetchRoutes();
    _fetchProvinces();
  }

  // ======================
  // FETCH ROUTES
  // ======================
  Future<void> _fetchRoutes() async {
    setState(() => _isLoading = true);

    final response = await http.get(
      Uri.parse(
        "${ApiService.baseUrl}/api/routes?company_id=${widget.companyId}",
      ),
    );

    final decoded = jsonDecode(response.body);

    setState(() {
      _routes = List<Map<String, dynamic>>.from(decoded['data'] ?? []);
      _isLoading = false;
    });
  }

  // ======================
  // AUTO ROUTE FETCH
  // ======================
  Future<void> _fetchProvinces() async {
    final res = await http.get(
      Uri.parse("${ApiService.baseUrl}/api/location/provinces"),
    );

    setState(() {
      provinces = jsonDecode(res.body);
    });
  }

  Future<void> _fetchCities(int id) async {
    final res = await http.get(
      Uri.parse("${ApiService.baseUrl}/api/location/cities/$id"),
    );
    setState(() => cities = jsonDecode(res.body));
  }

  Future<void> _fetchTerminals(int id) async {
    final res = await http.get(
      Uri.parse("${ApiService.baseUrl}/api/location/terminals/$id"),
    );
    setState(() => terminals = jsonDecode(res.body));
  }

  Future<void> _fetchCheckpoints(int id) async {
    final res = await http.get(
      Uri.parse("${ApiService.baseUrl}/api/location/checkpoints/$id"),
    );
    setState(() => checkpoints = jsonDecode(res.body));
  }

  // ======================
  // STORE AUTO ROUTE
  // ======================
  Future<void> _storeAutoRoute() async {
    if (startTerminal == null || endCheckpoint == null) return;

    final path = [
      {"lat": startTerminal!['latitude'], "lng": startTerminal!['longitude']},
      {"lat": endCheckpoint!['latitude'], "lng": endCheckpoint!['longitude']},
    ];

    await http.post(
      Uri.parse("${ApiService.baseUrl}/api/routes"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "company_id": widget.companyId,
        "nama_rute": "${startTerminal!['name']} - ${endCheckpoint!['name']}",
        "path": path,
      }),
    );

    // ignore: use_build_context_synchronously
    Navigator.pop(context);
    _fetchRoutes();
  }

  // ======================
  // STORE MANUAL ROUTE
  // ======================
  Future<void> _storeManualRoute(
    String nama,
    String asal,
    String tujuan,
  ) async {
    await http.post(
      Uri.parse("${ApiService.baseUrl}/api/routes"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "company_id": widget.companyId,
        "nama_rute": nama,
        "titik_awal": asal,
        "titik_tujuan": tujuan,
      }),
    );

    // ignore: use_build_context_synchronously
    Navigator.pop(context);
    _fetchRoutes();
  }

  // ======================
  // DIALOG PILIH MODE
  // ======================
  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Pilih Mode Input"),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showManualDialog();
              },
              child: const Text("Manual"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showAutoDialog();
              },
              child: const Text("Otomatis"),
            ),
          ],
        ),
      ),
    );
  }

  // ======================
  // DIALOG MANUAL
  // ======================
  void _showManualDialog() {
    final namaCtrl = TextEditingController();
    final asalCtrl = TextEditingController();
    final tujuanCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Tambah Manual"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaCtrl,
              decoration: const InputDecoration(labelText: "Nama"),
            ),
            TextField(
              controller: asalCtrl,
              decoration: const InputDecoration(labelText: "Asal"),
            ),
            TextField(
              controller: tujuanCtrl,
              decoration: const InputDecoration(labelText: "Tujuan"),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => _storeManualRoute(
              namaCtrl.text,
              asalCtrl.text,
              tujuanCtrl.text,
            ),
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  // ======================
  // DIALOG AUTO
  // ======================
  void _showAutoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Auto Route"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // ================= PROVINSI =================
                    DropdownButtonFormField<int>(
                      value: provinceId,
                      hint: const Text("Pilih Provinsi"),
                      items: provinces.map<DropdownMenuItem<int>>((p) {
                        return DropdownMenuItem(
                          value: p['id'],
                          child: Text(p['name']),
                        );
                      }).toList(),
                      onChanged: (val) async {
                        setStateDialog(() {
                          provinceId = val;
                          cityId = null;
                          cities = [];
                        });
                        await _fetchCities(val!);
                      },
                    ),

                    const SizedBox(height: 10),

                    // ================= KOTA =================
                    DropdownButtonFormField<int>(
                      value: cityId,
                      hint: const Text("Pilih Kota"),
                      items: cities.map<DropdownMenuItem<int>>((c) {
                        return DropdownMenuItem(
                          value: c['id'],
                          child: Text(c['name']),
                        );
                      }).toList(),
                      onChanged: (val) async {
                        setStateDialog(() {
                          cityId = val;
                        });

                        await _fetchTerminals(val!);
                        await _fetchCheckpoints(val);
                      },
                    ),

                    const SizedBox(height: 10),

                    // ================= TERMINAL =================
                    DropdownButtonFormField<Map>(
                      hint: const Text("Terminal Awal"),
                      items: terminals.map<DropdownMenuItem<Map>>((t) {
                        return DropdownMenuItem(
                          value: t,
                          child: Text(t['name']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setStateDialog(() => startTerminal = val);
                      },
                    ),

                    const SizedBox(height: 10),

                    // ================= CHECKPOINT =================
                    DropdownButtonFormField<Map>(
                      hint: const Text("Checkpoint Tujuan"),
                      items: checkpoints.map<DropdownMenuItem<Map>>((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(c['name']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setStateDialog(() => endCheckpoint = val);
                      },
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () {
                        _storeAutoRoute();
                      },
                      child: const Text("Simpan Route"),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ======================
  // UI
  // ======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Manajemen Rute", style: TextStyle(fontSize: 20)),
                ElevatedButton(
                  onPressed: _showAddDialog,
                  child: const Text("Tambah Rute"),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _routes.length,
                    itemBuilder: (_, i) {
                      final r = _routes[i];
                      return ListTile(title: Text(r['nama_rute'] ?? ''));
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
