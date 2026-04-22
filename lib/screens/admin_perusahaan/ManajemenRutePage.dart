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

  List provinces = [];

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
    final res = await http.get(
      Uri.parse("${ApiService.baseUrl}/api/location/provinces"),
    );

    setState(() {
      provinces = jsonDecode(res.body);
    });
  }

  // ================= STORE MANUAL =================
  Future<void> _storeManualRoute(
      String nama, String asal, String tujuan) async {
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
  Future<void> _storeAutoRoute(
      Map startTerminal, Map endCheckpoint) async {
    final res = await http.post(
      Uri.parse("${ApiService.baseUrl}/api/routes/auto-route"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "company_id": widget.companyId,
        "nama_rute":
            "${startTerminal['name']} - ${endCheckpoint['name']}",
        "start": {
          "lat": startTerminal['latitude'],
          "lng": startTerminal['longitude']
        },
        "end": {
          "lat": endCheckpoint['latitude'],
          "lng": endCheckpoint['longitude']
        }
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
        // ignore: unused_local_variable, no_leading_underscores_for_local_identifiers
        int? _provinceId;
        // ignore: unused_local_variable, no_leading_underscores_for_local_identifiers
        int? _cityId;
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
                    DropdownButtonFormField<int>(
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
                          _cities = [];
                        });
                        await fetchCities(val!);
                      },
                    ),

                    const SizedBox(height: 10),

                    DropdownButtonFormField<int>(
                      hint: const Text("Pilih Kota"),
                      items: _cities.map<DropdownMenuItem<int>>((c) {
                        return DropdownMenuItem(
                          value: c['id'],
                          child: Text(c['name']),
                        );
                      }).toList(),
                      onChanged: (val) async {
                        setStateDialog(() => _cityId = val);
                        await fetchTerminals(val!);
                        await fetchCheckpoints(val);
                      },
                    ),

                    const SizedBox(height: 10),

                    DropdownButtonFormField<Map>(
                      hint: const Text("Terminal Awal"),
                      items: _terminals.map<DropdownMenuItem<Map>>((t) {
                        return DropdownMenuItem(
                          value: t,
                          child: Text(t['name']),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setStateDialog(() => _startTerminal = val),
                    ),

                    const SizedBox(height: 10),

                    DropdownButtonFormField<Map>(
                      hint: const Text("Checkpoint Tujuan"),
                      items: _checkpoints.map<DropdownMenuItem<Map>>((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(c['name']),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setStateDialog(() => _endCheckpoint = val),
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

                        await _storeAutoRoute(
                            _startTerminal!, _endCheckpoint!);
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
                const Text("Manajemen Rute",
                    style: TextStyle(fontSize: 20)),
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