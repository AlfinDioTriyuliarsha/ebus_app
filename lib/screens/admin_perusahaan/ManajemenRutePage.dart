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

    final res = await http.get(Uri.parse(url));

    final decoded = jsonDecode(res.body);

    setState(() {
      provinces = List<Map<String, dynamic>>.from(decoded['data'] ?? []);
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
      Uri.parse("${ApiService.baseUrl}/api/routes"),
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
  Future<void> _storeAutoRoute({
    required Map<String, dynamic> startTerminal,
    required Map<String, dynamic> checkpointA,
    required Map<String, dynamic> checkpointB,
    required Map<String, dynamic> endTerminal,
  }) async {
    final res = await http.post(
      Uri.parse("${ApiService.baseUrl}/api/routes/auto-route"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "company_id": widget.companyId,

        "nama_rute":
            "${startTerminal['nama_terminal']} - ${endTerminal['nama_terminal']}",

        "start": {"lat": startTerminal['lat'], "lng": startTerminal['lng']},

        "checkpoint_a": {"lat": checkpointA['lat'], "lng": checkpointA['lng']},

        "checkpoint_b": {"lat": checkpointB['lat'], "lng": checkpointB['lng']},

        "end": {"lat": endTerminal['lat'], "lng": endTerminal['lng']},

        "path": [
          {"lat": startTerminal['lat'], "lng": startTerminal['lng']},
          {"lat": checkpointA['lat'], "lng": checkpointA['lng']},
          {"lat": checkpointB['lat'], "lng": checkpointB['lng']},
          {"lat": endTerminal['lat'], "lng": endTerminal['lng']},
        ],
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
            onPressed: () {
              _storeManualRoute(nama.text, asal.text, tujuan.text);
            },
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
        // ================= FIELD KEBERANGKATAN =================
        int? provinceStartId;
        int? cityStartId;

        int? startTerminalId;
        int? checkpointAId;
        int? checkpointBId;
        int? endTerminalId;

        Map<String, dynamic>? startTerminal;
        Map<String, dynamic>? checkpointA;
        Map<String, dynamic>? checkpointB;
        Map<String, dynamic>? endTerminal;

        List<Map<String, dynamic>> citiesStart = [];
        List<Map<String, dynamic>> terminalsStart = [];
        List<Map<String, dynamic>> checkpoints = [];

        // ================= FIELD TUJUAN =================
        int? provinceEndId;
        int? cityEndId;

        List<Map<String, dynamic>> citiesEnd = [];
        List<Map<String, dynamic>> terminalsEnd = [];

        List<Map<String, dynamic>> parseData(dynamic decoded) {
          if (decoded is Map && decoded.containsKey('data')) {
            return List<Map<String, dynamic>>.from(decoded['data']);
          }

          return [];
        }

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // ================= FETCH CITIES =================
            Future<void> fetchCitiesStart(int id) async {
              final res = await http.get(
                Uri.parse("${ApiService.baseUrl}/api/location/cities/$id"),
              );

              final decoded = jsonDecode(res.body);

              setStateDialog(() {
                citiesStart = parseData(decoded);

                cityStartId = null;
                terminalsStart = [];
                checkpoints = [];
              });
            }

            Future<void> fetchCitiesEnd(int id) async {
              final res = await http.get(
                Uri.parse("${ApiService.baseUrl}/api/location/cities/$id"),
              );

              final decoded = jsonDecode(res.body);

              setStateDialog(() {
                citiesEnd = parseData(decoded);

                cityEndId = null;
                terminalsEnd = [];
              });
            }

            // ================= FETCH TERMINALS =================
            Future<void> fetchStartTerminals(int id) async {
              final res = await http.get(
                Uri.parse("${ApiService.baseUrl}/api/location/terminals/$id"),
              );

              final decoded = jsonDecode(res.body);

              setStateDialog(() {
                terminalsStart = parseData(decoded);
                startTerminal = null;
              });
            }

            Future<void> fetchEndTerminals(int id) async {
              final res = await http.get(
                Uri.parse("${ApiService.baseUrl}/api/location/terminals/$id"),
              );

              print("END TERMINAL STATUS: ${res.statusCode}");
              print("END TERMINAL BODY: ${res.body}");

              final decoded = jsonDecode(res.body);

              setStateDialog(() {
                terminalsEnd = parseData(decoded);

                print("TERMINALS END:");
                print(terminalsEnd);

                endTerminal = null;
                endTerminalId = null;
              });
            }

            // ================= FETCH CHECKPOINT =================
            Future<void> fetchCheckpoints(int id) async {
              final res = await http.get(
                Uri.parse("${ApiService.baseUrl}/api/location/checkpoints/$id"),
              );

              final decoded = jsonDecode(res.body);

              setStateDialog(() {
                checkpoints = parseData(decoded);

                checkpointA = null;
                checkpointB = null;
              });
            }

            return AlertDialog(
              title: const Text("Auto Route"),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ======================================================
                      // FIELD KEBERANGKATAN
                      // ======================================================
                      const Text(
                        "FIELD KEBERANGKATAN",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 15),

                      // PROVINSI START
                      DropdownButtonFormField<int>(
                        value: provinceStartId,
                        hint: const Text("Pilih Provinsi"),
                        items: provinces.map<DropdownMenuItem<int>>((p) {
                          return DropdownMenuItem(
                            value: p['id'],
                            child: Text(p['nama_provinsi'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (val) async {
                          if (val == null) return;

                          setStateDialog(() {
                            provinceStartId = val;
                          });

                          await fetchCitiesStart(val);
                        },
                      ),

                      const SizedBox(height: 10),

                      // KOTA START
                      DropdownButtonFormField<int>(
                        value: cityStartId,
                        hint: const Text("Pilih Kota"),
                        items: citiesStart.map<DropdownMenuItem<int>>((c) {
                          return DropdownMenuItem(
                            value: c['id'],
                            child: Text(c['nama_kota'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (val) async {
                          if (val == null) return;

                          setStateDialog(() {
                            cityStartId = val;
                          });

                          await fetchStartTerminals(val);
                          await fetchCheckpoints(val);
                        },
                      ),

                      const SizedBox(height: 10),

                      // TERMINAL START
                      DropdownButtonFormField<int>(
                        value: startTerminalId,
                        hint: const Text("Terminal Keberangkatan"),
                        items: terminalsStart.map<DropdownMenuItem<int>>((t) {
                          return DropdownMenuItem(
                            value: t['id'],
                            child: Text(t['nama_terminal'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setStateDialog(() {
                            startTerminalId = val;

                            startTerminal = Map<String, dynamic>.from(
                              terminalsStart.firstWhere((e) => e['id'] == val),
                            );

                            print(startTerminal);
                          });
                        },
                      ),

                      const SizedBox(height: 10),

                      // CHECKPOINT A
                      DropdownButtonFormField<int>(
                        value: checkpointAId,
                        hint: const Text("Checkpoint A"),
                        items: checkpoints.map<DropdownMenuItem<int>>((c) {
                          return DropdownMenuItem(
                            value: c['id'],
                            child: Text(c['nama'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setStateDialog(() {
                            checkpointAId = val;

                            checkpointA = Map<String, dynamic>.from(
                              checkpoints.firstWhere((e) => e['id'] == val),
                            );

                            print(checkpointA);
                          });
                        },
                      ),

                      const SizedBox(height: 10),

                      // CHECKPOINT B
                      DropdownButtonFormField<int>(
                        value: checkpointBId,
                        hint: const Text("Checkpoint B"),
                        items: checkpoints.map<DropdownMenuItem<int>>((c) {
                          return DropdownMenuItem(
                            value: c['id'],
                            child: Text(c['nama'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setStateDialog(() {
                            checkpointBId = val;

                            checkpointB = Map<String, dynamic>.from(
                              checkpoints.firstWhere((e) => e['id'] == val),
                            );

                            print(checkpointB);
                          });
                        },
                      ),

                      const SizedBox(height: 30),

                      // ======================================================
                      // FIELD TUJUAN
                      // ======================================================
                      const Text(
                        "FIELD TUJUAN",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 15),

                      // PROVINSI TUJUAN
                      DropdownButtonFormField<int>(
                        value: provinceEndId,
                        hint: const Text("Pilih Provinsi"),
                        items: provinces.map<DropdownMenuItem<int>>((p) {
                          return DropdownMenuItem(
                            value: p['id'],
                            child: Text(p['nama_provinsi'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (val) async {
                          if (val == null) return;

                          setStateDialog(() {
                            provinceEndId = val;
                          });

                          await fetchCitiesEnd(val);
                        },
                      ),

                      const SizedBox(height: 10),

                      // KOTA TUJUAN
                      DropdownButtonFormField<int>(
                        value: cityEndId,
                        hint: const Text("Pilih Kota"),
                        items: citiesEnd.map<DropdownMenuItem<int>>((c) {
                          return DropdownMenuItem(
                            value: c['id'],
                            child: Text(c['nama_kota'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (val) async {
                          if (val == null) return;

                          setStateDialog(() {
                            cityEndId = val;
                          });

                          await fetchEndTerminals(val);
                        },
                      ),

                      const SizedBox(height: 10),

                      // TERMINAL TUJUAN
                      DropdownButtonFormField<int>(
                        isExpanded: true,
                        value: endTerminalId,
                        hint: const Text("Terminal Tujuan"),
                        items: terminalsEnd.map<DropdownMenuItem<int>>((t) {
                          return DropdownMenuItem(
                            value: t['id'],
                            child: Text(t['nama_terminal'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setStateDialog(() {
                            endTerminalId = val;

                            endTerminal = Map<String, dynamic>.from(
                              terminalsEnd.firstWhere((e) => e['id'] == val),
                            );

                            print(endTerminal);
                          });
                        },
                      ),

                      const SizedBox(height: 25),

                      // ================= BUTTON =================
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (startTerminal == null ||
                                checkpointA == null ||
                                checkpointB == null ||
                                endTerminal == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Lengkapi semua pilihan"),
                                ),
                              );
                              return;
                            }

                            await _storeAutoRoute(
                              startTerminal: startTerminal!,
                              checkpointA: checkpointA!,
                              checkpointB: checkpointB!,
                              endTerminal: endTerminal!,
                            );
                          },
                          child: const Text("Simpan Route"),
                        ),
                      ),
                    ],
                  ),
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
