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

  String get baseUrl => "${ApiService.baseUrl}/api/company";

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  // Mengambil data perusahaan terbaru
  Future<void> _fetchCompanies() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List rawData = (decoded is Map && decoded.containsKey('data'))
            ? decoded['data']
            : (decoded is List ? decoded : []);

        if (mounted) {
          setState(() {
            _companies = List<Map<String, dynamic>>.from(rawData);
            _isLoading = false;
            _error = null;
          });
        }
      } else {
        throw "Gagal memuat data (${response.statusCode})";
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

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

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) Navigator.pop(context);
        _fetchCompanies(); // Refresh data setelah tambah
        _showAlert("Perusahaan berhasil ditambahkan");
      } else {
        final decoded = jsonDecode(response.body);
        _showAlert("Gagal: ${decoded['message'] ?? response.statusCode}");
      }
    } catch (e) {
      _showAlert("Error: $e");
    }
  }

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
        _fetchCompanies(); // Refresh data setelah update
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

  Future<void> _deleteCompany(int id) async {
    try {
      final response = await http.delete(Uri.parse("$baseUrl/$id"));
      if (response.statusCode == 200) {
        _fetchCompanies(); // Refresh data setelah hapus
        _showAlert("Perusahaan berhasil dihapus");
      } else {
        final decoded = jsonDecode(response.body);
        _showAlert("Gagal hapus: ${decoded['message'] ?? response.statusCode}");
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
        builder: (context, setDialogState) => AlertDialog(
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
                _buildDropdown("Surat Izin", izin, [
                  "Lengkap",
                  "Tidak Lengkap",
                ], (v) => setDialogState(() => izin = v!)),
                _buildDropdown("Status", status, [
                  "Aktif",
                  "Nonaktif",
                ], (v) => setDialogState(() => status = v!)),
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
                if (nameCtrl.text.isEmpty) {
                  _showAlert("Nama wajib diisi");
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
        ),
      ),
    );
  }

  void _showEditCompanyDialog(Map<String, dynamic> company) {
    final nameCtrl = TextEditingController(
      text: company['company_name']?.toString() ?? "",
    );
    final emailCtrl = TextEditingController(
      text: company['email']?.toString() ?? "",
    );
    final alamatCtrl = TextEditingController(
      text: company['alamat']?.toString() ?? "",
    );
    final kotaCtrl = TextEditingController(
      text: company['kota']?.toString() ?? "",
    );
    final pemilikCtrl = TextEditingController(
      text: company['pemilik']?.toString() ?? "",
    );
    final noHpCtrl = TextEditingController(
      text: company['no_hp']?.toString() ?? "",
    );

    // FIXED: Membersihkan data null pada jumlah armada
    final armadaValue = company['jumlah_armada'];
    final armadaCtrl = TextEditingController(
      text:
          (armadaValue == null ||
              armadaValue.toString() == 'null' ||
              armadaValue.toString() == '')
          ? "0"
          : armadaValue.toString(),
    );

    String status = (company['status'] == null || company['status'] == 'null')
        ? "Aktif"
        : company['status'];
    String izin = (company['izin'] == null || company['izin'] == 'null')
        ? "Lengkap"
        : company['izin'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                _buildDropdown("Surat Izin", izin, [
                  "Lengkap",
                  "Tidak Lengkap",
                ], (v) => setDialogState(() => izin = v!)),
                _buildDropdown("Status", status, [
                  "Aktif",
                  "Nonaktif",
                ], (v) => setDialogState(() => status = v!)),
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
        ),
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
                  ElevatedButton(
                    onPressed: _fetchCompanies,
                    child: const Text("Coba Lagi"),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchCompanies,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _companies.length,
                itemBuilder: (context, index) {
                  final company = _companies[index];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.orange,
                        child: Icon(Icons.business, color: Colors.white),
                      ),
                      title: Text(
                        company['company_name'] ?? 'Tanpa Nama',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Pemilik: ${company['pemilik'] ?? '-'}\nArmada: ${company['jumlah_armada'] ?? '0'} Unit",
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
                            onPressed: () => _deleteCompany(company['id']),
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
