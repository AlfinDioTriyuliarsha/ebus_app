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

  List<Map<String, dynamic>> provinces = [];

  @override
  void initState() {
    super.initState();
    _fetchRoutes();
    _fetchProvinces();
  }

  // ================= FETCH ROUTES =================
  Future<void> _fetchRoutes() async {
    setState(() => _isLoading = true);

    try {
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
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // ================= FETCH PROVINCES =================
  Future<void> _fetchProvinces() async {
    final url = "${ApiService.baseUrl}/api/location/provinces";
    print("HIT PROVINCES: $url");

    final res = await http.get(Uri.parse(url));

    print("STATUS PROVINCES: ${res.statusCode}");
    print("BODY PROVINCES: ${res.body}");

    final decoded = jsonDecode(res.body);

    setState(() {
      provinces = decoded['data']; // 🔥 INI FIX NYA
    });
  }

  // ================= STORE MANUAL =================
  Future<void> _storeManualRoute(
    String nama,
    String asal,
    String tujuan,
  ) async {
    if (nama.isEmpty || asal.isEmpty || tujuan.isEmpty) return;

    final res = await http.post(
      Uri.parse("${ApiService.baseUrl}/api/routes"), // ✅ FIX
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "company_id": widget.companyId,
        "nama_rute": nama,
        "titik_awal": asal,
        "titik_tujuan": tujuan,
      }),
    );

    print("STATUS: ${res.statusCode}");
    print("BODY: ${res.body}");

    if (mounted) Navigator.pop(context);
    _fetchRoutes();
  }

  // ================= STORE AUTO =================
  Future<void> _storeAutoRoute(Map startTerminal, Map endCheckpoint) async {
    final res = await http.post(
      Uri.parse("${ApiService.baseUrl}/api/routes/auto-route"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "company_id": widget.companyId,
        "nama_rute":
            "${startTerminal['nama_terminal']} - ${endCheckpoint['nama']}",
        "start": {
          "lat": startTerminal['latitude'],
          "lng": startTerminal['longitude'],
        },
        "end": {
          "lat": endCheckpoint['latitude'],
          "lng": endCheckpoint['longitude'],
        },
      }),
    );

    print("AUTO STATUS: ${res.statusCode}");
    print("AUTO BODY: ${res.body}");

    if (mounted) Navigator.pop(context);
    _fetchRoutes();
  }

  // ================= DIALOG PILIH MODE =================
  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Pilih Mode"),
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
              child: const Text("Auto"),
            ),
          ],
        ),
      ),
    );
  }

  // ================= MANUAL =================
  void _showManualDialog() {
    final nama = TextEditingController();
    final asal = TextEditingController();
    final tujuan = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Tambah Manual"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nama,
              decoration: const InputDecoration(labelText: "Nama Rute"),
            ),
            TextField(
              controller: asal,
              decoration: const InputDecoration(labelText: "Asal"),
            ),
            TextField(
              controller: tujuan,
              decoration: const InputDecoration(labelText: "Tujuan"),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () =>
                _storeManualRoute(nama.text, asal.text, tujuan.text),
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  // ================= AUTO =================
  void _showAutoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        int? provinceId;
        int? cityId;

        Map<String, dynamic>? startTerminal;
        Map<String, dynamic>? endCheckpoint;

        List cities = [];
        List terminals = [];
        List checkpoints = [];

        List<dynamic> parseData(dynamic decoded) {
          if (decoded is Map && decoded.containsKey('data')) {
            return decoded['data'];
          }
          return decoded;
        }

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> fetchCities(int id) async {
              final res = await http.get(
                Uri.parse("${ApiService.baseUrl}/api/location/cities/$id"),
              );

              final decoded = jsonDecode(res.body);

              setStateDialog(() {
                cities = parseData(decoded);
                cityId = null;
                terminals = [];
                checkpoints = [];
              });
            }

            Future<void> fetchTerminals(int id) async {
              final res = await http.get(
                Uri.parse("${ApiService.baseUrl}/api/location/terminals/$id"),
              );

              final decoded = jsonDecode(res.body);

              setStateDialog(() {
                terminals = parseData(decoded);
                startTerminal = null;
              });
            }

            Future<void> fetchCheckpoints(int id) async {
              final res = await http.get(
                Uri.parse("${ApiService.baseUrl}/api/location/checkpoints/$id"),
              );

              final decoded = jsonDecode(res.body);

              setStateDialog(() {
                checkpoints = parseData(decoded);
                endCheckpoint = null;
              });
            }

            return AlertDialog(
              title: const Text("Auto Route"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    // ================= PROVINSI =================
                    DropdownButtonFormField<int>(
                      value: provinceId,
                      hint: const Text("Pilih Provinsi"),
                      items: provinces.map<DropdownMenuItem<int>>((p) {
                        return DropdownMenuItem(
                          value: p['id'],
                          child: Text(
                            p['nama_provinsi'] ?? '',
                          ), // 🔥 FIX DI SINI
                        );
                      }).toList(),
                      onChanged: (val) async {
                        if (val == null) return;

                        setStateDialog(() => provinceId = val);
                        await fetchCities(val);
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
                          child: Text(c['nama_kota'] ?? ''),
                        );
                      }).toList(),
                      onChanged: (val) async {
                        if (val == null) return;

                        setStateDialog(() => cityId = val);

                        await fetchTerminals(val);
                        await fetchCheckpoints(val);
                      },
                    ),

                    const SizedBox(height: 10),

                    // ================= TERMINAL =================
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: startTerminal,
                      hint: const Text("Terminal Awal"),
                      items: terminals
                          .map<DropdownMenuItem<Map<String, dynamic>>>((t) {
                            return DropdownMenuItem(
                              value: t,
                              child: Text(t['nama_terminal'] ?? ''),
                            );
                          })
                          .toList(),
                      onChanged: (val) {
                        setStateDialog(() => startTerminal = val);
                      },
                    ),

                    const SizedBox(height: 10),

                    // ================= CHECKPOINT =================
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: endCheckpoint,
                      hint: const Text("Checkpoint Tujuan"),
                      items: checkpoints
                          .map<DropdownMenuItem<Map<String, dynamic>>>((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Text(c['nama_terminal'] ?? ''),
                            );
                          })
                          .toList(),
                      onChanged: (val) {
                        setStateDialog(() => endCheckpoint = val);
                      },
                    ),

                    const SizedBox(height: 20),

                    // ================= BUTTON =================
                    ElevatedButton(
                      onPressed: () async {
                        if (startTerminal == null || endCheckpoint == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Lengkapi semua pilihan"),
                            ),
                          );
                          return;
                        }

                        await _storeAutoRoute(startTerminal!, endCheckpoint!);
                      },
                      child: const Text("Simpan Route"),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================= UI =================
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
                      return ListTile(
                        title: Text(r['nama_rute'] ?? ''),
                        subtitle: Text(
                          "${r['titik_awal'] ?? ''} → ${r['titik_tujuan'] ?? ''}",
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
