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

  // ✅ Ganti ke IP server / 127.0.0.1 kalau backend jalan di PC sama
  String get baseUrl => "${ApiService.baseUrl}/api/users";

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  Future<void> _fetchCompanies() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<Map<String, dynamic>> companies =
            List<Map<String, dynamic>>.from(decoded['data']);
        setState(() {
          _companies = companies;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Gagal mengambil data. Code: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Error: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _addCompany(
    String companyName,
    String email,
    String alamat,
    String status,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "company_name": companyName.trim(),
          "email": email.trim(),
          "alamat": alamat.trim(),
          "status": status,
        }),
      );

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (decoded["success"] == true) {
          if (mounted) Navigator.pop(context);
          _fetchCompanies();
          _showAlert("Perusahaan berhasil ditambahkan");
        } else {
          _showAlert(
            "Gagal tambah perusahaan: ${decoded['message'] ?? 'Unknown'}",
          );
        }
      } else {
        _showAlert("Gagal tambah perusahaan. Code: ${response.statusCode}");
      }
    } catch (e) {
      _showAlert("Error: $e");
    }
  }

  Future<void> _updateCompany(
    int id,
    String companyName,
    String email,
    String alamat,
    String status,
  ) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "company_name": companyName,
          "email": email,
          "alamat": alamat,
          "status": status,
        }),
      );

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (mounted) Navigator.pop(context);
        _fetchCompanies();
        _showAlert("Perusahaan berhasil diperbarui");
      } else {
        _showAlert(
          "Gagal update perusahaan: ${decoded['message'] ?? response.body}",
        );
      }
    } catch (e) {
      _showAlert("Error: $e");
    }
  }

  Future<void> _deleteCompany(int id) async {
    try {
      final response = await http.delete(Uri.parse("$baseUrl/$id"));
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded["success"] == true) {
        _fetchCompanies();
        _showAlert("Perusahaan berhasil dihapus");
      } else {
        _showAlert(
          "Gagal hapus perusahaan: ${decoded['message'] ?? response.body}",
        );
      }
    } catch (e) {
      _showAlert("Error: $e");
    }
  }

  void _showAlert(String message) {
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
    final companyNameController = TextEditingController();
    final emailController = TextEditingController();
    final alamatController = TextEditingController();
    String status = "Aktif";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tambah Perusahaan"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: companyNameController,
                decoration: const InputDecoration(labelText: "Nama Perusahaan"),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: alamatController,
                decoration: const InputDecoration(labelText: "Alamat"),
              ),
              DropdownButtonFormField<String>(
                value: status,
                items: const [
                  DropdownMenuItem(value: "Aktif", child: Text("Aktif")),
                  DropdownMenuItem(value: "Nonaktif", child: Text("Nonaktif")),
                ],
                onChanged: (val) => status = val!,
                decoration: const InputDecoration(labelText: "Status"),
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
            onPressed: () {
              if (companyNameController.text.isEmpty ||
                  emailController.text.isEmpty) {
                _showAlert("Nama dan Email wajib diisi");
                return;
              }
              _addCompany(
                companyNameController.text,
                emailController.text,
                alamatController.text,
                status,
              );
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _showEditCompanyDialog(Map<String, dynamic> company) {
    final companyNameController = TextEditingController(
      text: company['company_name'],
    );
    final emailController = TextEditingController(text: company['email']);
    final alamatController = TextEditingController(text: company['alamat']);
    String status = company['status'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Perusahaan"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: companyNameController,
                decoration: const InputDecoration(labelText: "Nama Perusahaan"),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: alamatController,
                decoration: const InputDecoration(labelText: "Alamat"),
              ),
              DropdownButtonFormField<String>(
                value: status,
                items: const [
                  DropdownMenuItem(value: "Aktif", child: Text("Aktif")),
                  DropdownMenuItem(value: "Nonaktif", child: Text("Nonaktif")),
                ],
                onChanged: (val) => status = val!,
                decoration: const InputDecoration(labelText: "Status"),
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
            onPressed: () {
              _updateCompany(
                company['id'],
                companyNameController.text,
                emailController.text,
                alamatController.text,
                status,
              );
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_companies.isEmpty) {
      return const Center(child: Text("Belum ada perusahaan"));
    }

    return Scaffold(
      body: ListView.builder(
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
                company['company_name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Email: ${company['email']}"),
                  Text("Alamat: ${company['alamat'] ?? '-'}"),
                  Text("Status: ${company['status']}"),
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
                    onPressed: () => _deleteCompany(company['id']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCompanyDialog,
        icon: const Icon(Icons.add_business),
        label: const Text("Tambah"),
      ),
    );
  }
}
