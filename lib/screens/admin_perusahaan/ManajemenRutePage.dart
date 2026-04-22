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

  // ================= FETCH LOCATION =================
  Future<void> _fetchProvinces() async {
    final res = await http.get(
      Uri.parse("${ApiService.baseUrl}/api/location/provinces"),
    );

    setState(() {
      provinces = jsonDecode(res.body);
    });
  }

  // ignore: unused_element
  Future<void> _fetchCities(int id) async {
    final res = await http.get(
      Uri.parse("${ApiService.baseUrl}/api/location/cities/$id"),
    );

    cities = jsonDecode(res.body);
  }

  // ignore: unused_element
  Future<void> _fetchTerminals(int id) async {
    final res = await http.get(
      Uri.parse("${ApiService.baseUrl}/api/location/terminals/$id"),
    );

    terminals = jsonDecode(res.body);
  }

  // ignore: unused_element
  Future<void> _fetchCheckpoints(int id) async {
    final res = await http.get(
      Uri.parse("${ApiService.baseUrl}/api/location/checkpoints/$id"),
    );

    checkpoints = jsonDecode(res.body);
  }

  // ================= STORE AUTO =================
  // ignore: unused_element
  Future<void> _storeAutoRoute() async {
    if (startTerminal == null || endCheckpoint == null) return;

    try {
      final res = await http.post(
        Uri.parse("${ApiService.baseUrl}/api/routes/auto-route"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "company_id": widget.companyId,
          "nama_rute":
              "${startTerminal!['name']} - ${endCheckpoint!['name']}",
          "start": {
            "lat": startTerminal!['latitude'],
            "lng": startTerminal!['longitude']
          },
          "end": {
            "lat": endCheckpoint!['latitude'],
            "lng": endCheckpoint!['longitude']
          }
        }),
      );

      print(res.body);

      if (res.statusCode == 200) {
        // ignore: use_build_context_synchronously
        Navigator.pop(context);
        _fetchRoutes();
      }
    } catch (e) {
      print("AUTO ROUTE ERROR: $e");
    }
  }

  // ================= STORE MANUAL =================
  Future<void> _storeManualRoute(
    String nama,
    String asal,
    String tujuan,
  ) async {
    if (nama.isEmpty || asal.isEmpty || tujuan.isEmpty) return;

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

    if (mounted) Navigator.pop(context);
    _fetchRoutes();
  }

  // ================= PILIH MODE =================
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
        // ignore: no_leading_underscores_for_local_identifiers
        int? _provinceId = provinceId;
        // ignore: no_leading_underscores_for_local_identifiers
        int? _cityId = cityId;
        // ignore: no_leading_underscores_for_local_identifiers
        Map? _startTerminal;
        // ignore: no_leading_underscores_for_local_identifiers
        Map? _endCheckpoint;

        // ignore: no_leading_underscores_for_local_identifiers
        List _cities = [];
        // ignore: no_leading_underscores_for_local_identifiers
        List _terminals = [];
        // ignore: no_leading_underscores_for_local_identifiers
        List _checkpoints = [];

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> fetchCities(int id) async {
              final res = await http.get(
                Uri.parse("${ApiService.baseUrl}/api/location/cities/$id"),
              );
              setStateDialog(() {
                _cities = jsonDecode(res.body);
              });
            }

            Future<void> fetchTerminals(int id) async {
              final res = await http.get(
                Uri.parse("${ApiService.baseUrl}/api/location/terminals/$id"),
              );
              setStateDialog(() {
                _terminals = jsonDecode(res.body);
              });
            }

            Future<void> fetchCheckpoints(int id) async {
              final res = await http.get(
                Uri.parse("${ApiService.baseUrl}/api/location/checkpoints/$id"),
              );
              setStateDialog(() {
                _checkpoints = jsonDecode(res.body);
              });
            }

            return AlertDialog(
              title: const Text("Auto Route"),
              content: SingleChildScrollView(
                child: Column(
                  children: [

                    // ================= PROVINSI =================
                    DropdownButtonFormField<int>(
                      value: _provinceId,
                      hint: const Text("Pilih Provinsi"),
                      items: provinces.map<DropdownMenuItem<int>>((p) {
                        return DropdownMenuItem(
                          value: p['id'],
                          child: Text(p['name']),
                        );
                      }).toList(),
                      onChanged: (val) async {
                        setStateDialog(() {
                          _provinceId = val;
                          _cityId = null;
                          _cities = [];
                        });
                        await fetchCities(val!);
                      },
                    ),

                    const SizedBox(height: 10),

                    // ================= KOTA =================
                    DropdownButtonFormField<int>(
                      value: _cityId,
                      hint: const Text("Pilih Kota"),
                      items: _cities.map<DropdownMenuItem<int>>((c) {
                        return DropdownMenuItem(
                          value: c['id'],
                          child: Text(c['name']),
                        );
                      }).toList(),
                      onChanged: (val) async {
                        setStateDialog(() {
                          _cityId = val;
                        });

                        await fetchTerminals(val!);
                        await fetchCheckpoints(val);
                      },
                    ),

                    const SizedBox(height: 10),

                    // ================= TERMINAL =================
                    DropdownButtonFormField<Map>(
                      hint: const Text("Terminal Awal"),
                      items: _terminals.map<DropdownMenuItem<Map>>((t) {
                        return DropdownMenuItem(
                          value: t,
                          child: Text(t['name']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setStateDialog(() => _startTerminal = val);
                      },
                    ),

                    const SizedBox(height: 10),

                    // ================= CHECKPOINT =================
                    DropdownButtonFormField<Map>(
                      hint: const Text("Checkpoint Tujuan"),
                      items: _checkpoints.map<DropdownMenuItem<Map>>((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(c['name']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setStateDialog(() => _endCheckpoint = val);
                      },
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () async {
                        if (_startTerminal == null || _endCheckpoint == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Lengkapi semua pilihan")),
                          );
                          return;
                        }

                        final path = [
                          {
                            "lat": _startTerminal!['latitude'],
                            "lng": _startTerminal!['longitude']
                          },
                          {
                            "lat": _endCheckpoint!['latitude'],
                            "lng": _endCheckpoint!['longitude']
                          },
                        ];

                        await http.post(
                          Uri.parse("${ApiService.baseUrl}/api/routes"),
                          headers: {"Content-Type": "application/json"},
                          body: jsonEncode({
                            "company_id": widget.companyId,
                            "nama_rute":
                                "${_startTerminal!['name']} - ${_endCheckpoint!['name']}",
                            "path": path,
                          }),
                        );

                        // ignore: use_build_context_synchronously
                        Navigator.pop(context);
                        _fetchRoutes();
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
