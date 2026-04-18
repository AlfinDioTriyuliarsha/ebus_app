import 'dart:convert';
import 'package:ebus_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ManajemenDriverPage extends StatefulWidget {
  final int companyId;
  const ManajemenDriverPage({super.key, required this.companyId});

  @override
  State<ManajemenDriverPage> createState() => _ManajemenDriverPageState();
}

class _ManajemenDriverPageState extends State<ManajemenDriverPage> {
  List drivers = [];
  List buses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAll();
  }

  Future<void> fetchAll() async {
    await Future.wait([fetchDrivers(), fetchBuses()]);
    setState(() => isLoading = false);
  }

  // ================= GET =================
  Future<void> fetchDrivers() async {
    final res = await http.get(
      Uri.parse(
        "${ApiService.baseUrl}/api/drivers?company_id=${widget.companyId}",
      ),
    );

    final data = jsonDecode(res.body);
    drivers = data['data'];
  }

  Future<void> fetchBuses() async {
    final res = await http.get(
      Uri.parse(
        "${ApiService.baseUrl}/api/buses?company_id=${widget.companyId}",
      ),
    );

    final data = jsonDecode(res.body);
    buses = data['data'];
  }

  // ================= CREATE / UPDATE =================
  Future<void> submitDriver({
    int? id,
    required String name,
    required String kontak,
  }) async {
    final url = id == null
        ? "${ApiService.baseUrl}/api/drivers"
        : "${ApiService.baseUrl}/api/drivers/$id";

    final body = {
      "company_id": widget.companyId,
      "driver_name": name,
      "kontak": kontak,
    };

    final res = id == null
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

    if (res.statusCode == 200 || res.statusCode == 201) {
      fetchAll();
      // ignore: use_build_context_synchronously
      Navigator.pop(context);

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(id == null ? "Driver ditambah" : "Driver diupdate"),
        ),
      );
    } else {
      debugPrint(res.body);
    }
  }

  // ================= DELETE =================
  Future<void> deleteDriver(int id) async {
    final res = await http.delete(
      Uri.parse("${ApiService.baseUrl}/api/drivers/$id"),
    );

    if (res.statusCode == 200) {
      fetchAll();
    }
  }

  // ================= ASSIGN =================
  Future<void> assignDriver(int driverId, int busId) async {
    final res = await http.put(
      Uri.parse("${ApiService.baseUrl}/api/buses/$busId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"driver_id": driverId}),
    );

    if (res.statusCode == 200) {
      fetchAll();
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Driver berhasil ditugaskan")),
      );
    } else {
      debugPrint(res.body);
    }
  }

  // ================= DIALOG FORM =================
  void showForm({Map? data}) {
    final nameCtrl = TextEditingController(text: data?['driver_name']);
    final kontakCtrl = TextEditingController(text: data?['kontak']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(data == null ? "Tambah Driver" : "Edit Driver"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Nama Driver"),
            ),
            TextField(
              controller: kontakCtrl,
              decoration: const InputDecoration(labelText: "Kontak"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isEmpty) return;

              submitDriver(
                id: data?['id'],
                name: nameCtrl.text,
                kontak: kontakCtrl.text,
              );
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manajemen Driver"),
        backgroundColor: Colors.orange,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: drivers.length,
              itemBuilder: (context, i) {
                final d = drivers[i];

                return Card(
                  child: ListTile(
                    title: Text(d['driver_name']),
                    subtitle: Text(d['kontak'] ?? '-'),

                    // 🔥 ASSIGN BUS
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButton<int>(
                          hint: const Text("Bus"),
                          items: buses.map<DropdownMenuItem<int>>((b) {
                            return DropdownMenuItem<int>(
                              value: b['id'],
                              child: Text(b['plat_nomor']),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              assignDriver(d['id'], val);
                            }
                          },
                        ),

                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => showForm(data: d),
                        ),

                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteDriver(d['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

      // 🔥 TAMBAH DRIVER
      floatingActionButton: FloatingActionButton(
        onPressed: () => showForm(),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }
}
