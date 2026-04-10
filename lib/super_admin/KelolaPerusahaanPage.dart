import 'dart:convert';
import 'package:ebus_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class KelolaPerusahaanPage extends StatefulWidget {
  const KelolaPerusahaanPage({super.key});

  @override
  State<KelolaPerusahaanPage> createState() => _KelolaPerusahaanPageState();
}

class _KelolaPerusahaanPageState extends State<KelolaPerusahaanPage> {
  List<Map<String, dynamic>> _companies = [];
  bool _isLoading = true;
  String? _error;

  // Endpoint yang sudah sesuai dengan standar API Railway kamu
  String get baseUrl => "${ApiService.baseUrl}/api/company";
  String get busApiUrl => "${ApiService.baseUrl}/api/buses";

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  // FIXED: Penanganan response agar tidak error saat membaca field 'data'
  Future<void> _fetchCompanies() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        // Memastikan mengambil list dari key 'data' atau fallback ke list kosong
        final List rawData = (decoded is Map && decoded.containsKey('data'))
            ? decoded['data']
            : (decoded is List ? decoded : []);

        final List<Map<String, dynamic>> companies =
            List<Map<String, dynamic>>.from(rawData);

        if (mounted) {
          setState(() {
            _companies = companies;
            _isLoading = false;
            _error = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = "Gagal mengambil data. Code: ${response.statusCode}";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Error Koneksi: $e";
          _isLoading = false;
        });
      }
    }
  }

  // FIXED: Penyesuaian key JSON agar terbaca di Database Neon
  Future<void> _addCompany({
    required String name,
    required String email,
    required String alamat,
    required String kota,
    required String pemilik,
    required String noHp,
    required String armada,
    required String izin,
    required String status,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "company_name": name.trim(),
          "email": email.trim(),
          "alamat": alamat.trim(),
          "kota": kota.trim(),
          "pemilik": pemilik.trim(),
          "no_hp": noHp.trim(),
          "jumlah_armada": int.tryParse(armada) ?? 0,
          "izin": izin,
          "status": status,
        }),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (decoded["success"] == true || response.statusCode == 201) {
          if (mounted) Navigator.pop(context);
          _fetchCompanies();
          _showAlert("Perusahaan berhasil ditambahkan");
        } else {
          _showAlert("Gagal: ${decoded['message'] ?? 'Unknown'}");
        }
      } else {
        _showAlert("Gagal: ${decoded['message'] ?? response.statusCode}");
      }
    } catch (e) {
      _showAlert("Error: $e");
    }
  }

  // FIXED: Update menggunakan ID yang tepat
  Future<void> _updateCompany({
    required int id,
    required String name,
    required String email,
    required String alamat,
    required String kota,
    required String pemilik,
    required String noHp,
    required String armada,
    required String izin,
    required String status,
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "company_name": name.trim(),
          "email": email.trim(),
          "alamat": alamat.trim(),
          "kota": kota.trim(),
          "pemilik": pemilik.trim(),
          "no_hp": noHp.trim(),
          "jumlah_armada": int.tryParse(armada) ?? 0,
          "izin": izin,
          "status": status,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) Navigator.pop(context);
        _fetchCompanies();
        _showAlert("Perusahaan berhasil diperbarui");
      } else {
        final decoded = jsonDecode(response.body);
        _showAlert(
          "Update Gagal: ${decoded['message'] ?? response.statusCode}",
        );
      }
    } catch (e) {
      _showAlert("Error: $e");
    }
  }

  // FIXED: Penanganan delete dengan konfirmasi refresh
  Future<void> _deleteCompany(int id) async {
    try {
      final response = await http.delete(Uri.parse("$baseUrl/$id"));
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _fetchCompanies();
        _showAlert("Perusahaan berhasil dihapus");
      } else {
        _showAlert("Gagal hapus: ${decoded['message'] ?? response.body}");
      }
    } catch (e) {
      _showAlert("Error: $e");
    }
  }

  void _showAlert(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Informasi"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showAddCompanyDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final alamatCtrl = TextEditingController();
    final kotaCtrl = TextEditingController();
    final pemilikCtrl = TextEditingController();
    final noHpCtrl = TextEditingController();
    final armadaCtrl = TextEditingController();
    String status = "Aktif";
    String izin = "Lengkap";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        // Menjaga state dropdown di dalam dialog
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Tambah Perusahaan"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  _buildInput(nameCtrl, "Nama Perusahaan"),
                  _buildInput(kotaCtrl, "Kota"),
                  _buildInput(pemilikCtrl, "Pemilik"),
                  _buildInput(
                    emailCtrl,
                    "Email",
                    type: TextInputType.emailAddress,
                  ),
                  _buildInput(noHpCtrl, "Nomor HP", type: TextInputType.phone),
                  _buildInput(
                    armadaCtrl,
                    "Jumlah Unit Armada",
                    type: TextInputType.number,
                  ),
                  _buildInput(alamatCtrl, "Alamat"),
                  _buildDropdown(
                    "Surat Izin",
                    izin,
                    ["Lengkap", "Tidak Lengkap"],
                    (v) {
                      setDialogState(() => izin = v!);
                    },
                  ),
                  _buildDropdown("Status", status, ["Aktif", "Nonaktif"], (v) {
                    setDialogState(() => status = v!);
                  }),
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
                  if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty) {
                    _showAlert("Nama dan Email wajib diisi");
                    return;
                  }
                  _addCompany(
                    name: nameCtrl.text,
                    email: emailCtrl.text,
                    alamat: alamatCtrl.text,
                    kota: kotaCtrl.text,
                    pemilik: pemilikCtrl.text,
                    noHp: noHpCtrl.text,
                    armada: armadaCtrl.text,
                    izin: izin,
                    status: status,
                  );
                },
                child: const Text("Simpan"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditCompanyDialog(Map<String, dynamic> company) {
    final nameCtrl = TextEditingController(text: company['company_name']);
    final emailCtrl = TextEditingController(text: company['email']);
    final alamatCtrl = TextEditingController(text: company['alamat']);
    final kotaCtrl = TextEditingController(text: company['kota']);
    final pemilikCtrl = TextEditingController(text: company['pemilik']);
    final noHpCtrl = TextEditingController(text: company['no_hp']);

    // FIXED: Pencegahan string 'null' pada jumlah armada
    final armadaValue = company['jumlah_armada'];
    final armadaCtrl = TextEditingController(
      text: (armadaValue == null || armadaValue == 'null')
          ? "0"
          : armadaValue.toString(),
    );

    String status = company['status'] ?? "Aktif";
    String izin = company['izin'] ?? "Lengkap";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Edit Perusahaan"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  _buildInput(nameCtrl, "Nama Perusahaan"),
                  _buildInput(kotaCtrl, "Kota"),
                  _buildInput(pemilikCtrl, "Pemilik"),
                  _buildInput(emailCtrl, "Email"),
                  _buildInput(noHpCtrl, "Nomor HP"),
                  _buildInput(armadaCtrl, "Jumlah Unit Armada"),
                  _buildInput(alamatCtrl, "Alamat"),
                  _buildDropdown(
                    "Surat Izin",
                    izin,
                    ["Lengkap", "Tidak Lengkap"],
                    (v) {
                      setDialogState(() => izin = v!);
                    },
                  ),
                  _buildDropdown("Status", status, ["Aktif", "Nonaktif"], (v) {
                    setDialogState(() => status = v!);
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () => _updateCompany(
                  id: company['id'],
                  name: nameCtrl.text,
                  email: emailCtrl.text,
                  alamat: alamatCtrl.text,
                  kota: kotaCtrl.text,
                  pemilik: pemilikCtrl.text,
                  noHp: noHpCtrl.text,
                  armada: armadaCtrl.text,
                  izin: izin,
                  status: status,
                ),
                child: const Text("Update"),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInput(
    TextEditingController ctrl,
    String label, {
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manajemen Perusahaan"),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            onPressed: _fetchCompanies,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _fetchCompanies,
                    child: const Text("Coba Lagi"),
                  ),
                ],
              ),
            )
          : _companies.isEmpty
          ? const Center(child: Text("Belum ada perusahaan"))
          : RefreshIndicator(
              onRefresh: _fetchCompanies,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _companies.length,
                itemBuilder: (context, index) {
                  final company = _companies[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange[100],
                        child: const Icon(Icons.business, color: Colors.orange),
                      ),
                      title: Text(
                        company['company_name'] ?? 'Tanpa Nama',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Pemilik: ${company['pemilik'] ?? '-'}"),
                          Text("Kota: ${company['kota'] ?? '-'}"),
                          Text(
                            "Armada: ${company['jumlah_armada'] ?? '0'} Unit",
                          ),
                          Text(
                            "Status: ${company['status'] ?? 'Aktif'}",
                            style: TextStyle(
                              color: company['status'] == 'Aktif'
                                  ? Colors.green
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showEditCompanyDialog(company),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("Hapus"),
                                  content: const Text(
                                    "Yakin ingin menghapus perusahaan ini?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text("Batal"),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        _deleteCompany(company['id']);
                                      },
                                      child: const Text(
                                        "Hapus",
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCompanyDialog,
        icon: const Icon(Icons.add_business),
        label: const Text("Tambah"),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
