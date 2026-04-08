// ignore: file_names
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ebus_app/services/api_service.dart'; // Menambahkan import service

class KelolaPenggunaPage extends StatefulWidget {
  const KelolaPenggunaPage({super.key});

  @override
  State<KelolaPenggunaPage> createState() => _KelolaPenggunaPageState();
}

class _KelolaPenggunaPageState extends State<KelolaPenggunaPage> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _error;

  // Menggunakan baseUrl dari ApiService agar sinkron dengan config IP Anda
  String get baseUrl => "${ApiService.baseUrl}/api/users";

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<Map<String, dynamic>> users =
            List<Map<String, dynamic>>.from(decoded['data']);
        setState(() {
          _users = users;
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

  Future<void> _addUser(String email, String password, String role) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email.trim(),
          "password": password.trim(),
          "role": role,
        }),
      );

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (decoded["success"] == true) {
          if (mounted) Navigator.pop(context);
          _fetchUsers();
          _showSuccessDialog("User berhasil ditambahkan");
        } else {
          _showErrorSnack(
            "Gagal tambah user: ${decoded['message'] ?? 'Unknown'}",
          );
        }
      } else {
        _showErrorSnack("Gagal tambah user. Code: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorSnack("Error: $e");
    }
  }

  Future<void> _updateUser(
    int id,
    String email,
    String role, {
    String? password,
  }) async {
    try {
      // Siapkan Map data
      final Map<String, dynamic> bodyData = {
        "email": email.trim(),
        "role": role,
      };
      
      // Tambahkan password jika diisi
      if (password != null && password.isNotEmpty) {
        bodyData["password"] = password.trim();
      }

      final response = await http.put(
        Uri.parse("$baseUrl/$id"),
        headers: {
          "Content-Type": "application/json", // WAJIB ADA agar Express bisa baca req.body
        },
        body: jsonEncode(bodyData), // Encode ke JSON string
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded["success"] == true) {
          if (mounted) Navigator.pop(context); // Tutup dialog edit
          _fetchUsers(); // Refresh daftar user
          _showSuccessDialog("User berhasil diperbarui");
        } else {
          _showErrorSnack("Gagal: ${decoded['message']}");
        }
      } else {
        _showErrorSnack("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorSnack("Koneksi Error: $e");
    }
  }

  Future<void> _deleteUser(int id) async {
    try {
      final response = await http.delete(Uri.parse("$baseUrl/$id"));
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded["success"] == true) {
        _fetchUsers();
        _showSuccessDialog("User berhasil dihapus");
      } else {
        _showErrorSnack(
          "Gagal hapus user: ${decoded['message'] ?? response.body}",
        );
      }
    } catch (e) {
      _showErrorSnack("Error: $e");
    }
  }

  void _showSuccessDialog(String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 8),
            Text("Berhasil"),
          ],
        ),
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

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showDeleteConfirmDialog(int id, String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 32),
            SizedBox(width: 8),
            Text("Konfirmasi"),
          ],
        ),
        content: Text("Apakah Anda yakin ingin menghapus user:\n$email ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(id);
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String role = "penumpang";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tambah Pengguna"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
              ),
              DropdownButtonFormField<String>(
                value: role,
                items: const [
                  DropdownMenuItem(
                    value: "super_admin",
                    child: Text("Super Admin"),
                  ),
                  DropdownMenuItem(
                    value: "admin_perusahaan",
                    child: Text("Admin Perusahaan"),
                  ),
                  DropdownMenuItem(value: "agen", child: Text("Agen")),
                  DropdownMenuItem(
                    value: "penumpang",
                    child: Text("Penumpang"),
                  ),
                  DropdownMenuItem(value: "keluarga", child: Text("Keluarga")),
                ],
                onChanged: (val) => role = val!,
                decoration: const InputDecoration(labelText: "Role"),
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
              if (emailController.text.isEmpty ||
                  passwordController.text.isEmpty) {
                _showErrorSnack("Email & Password wajib diisi");
                return;
              }
              _addUser(emailController.text, passwordController.text, role);
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final emailController = TextEditingController(text: user['email']);
    final passwordController = TextEditingController();
    String role = user['role'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Pengguna"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: "Password (opsional)",
                ),
                obscureText: true,
              ),
              DropdownButtonFormField<String>(
                value: role,
                items: const [
                  DropdownMenuItem(
                    value: "super_admin",
                    child: Text("Super Admin"),
                  ),
                  DropdownMenuItem(
                    value: "admin_perusahaan",
                    child: Text("Admin Perusahaan"),
                  ),
                  DropdownMenuItem(value: "agen", child: Text("Agen")),
                  DropdownMenuItem(
                    value: "penumpang",
                    child: Text("Penumpang"),
                  ),
                  DropdownMenuItem(value: "keluarga", child: Text("Keluarga")),
                ],
                onChanged: (val) => role = val!,
                decoration: const InputDecoration(labelText: "Role"),
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
            onPressed: () => _updateUser(
              user['id'],
              emailController.text,
              role,
              password: passwordController.text,
            ),
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    return Scaffold(
      backgroundColor:
          Colors.transparent, // Agar menyatu dengan background dashboard
      body: Column(
        children: [
          Expanded(
            child: _users.isEmpty
                ? const Center(child: Text("Belum ada pengguna"))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildInfoRow("Email", user['email']),
                                        const SizedBox(height: 8),
                                        _buildInfoRow(
                                          "Role",
                                          user['role']
                                              .toString()
                                              .replaceAll('_', ' ')
                                              .toUpperCase(),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildInfoRow(
                                          "User ID",
                                          "#${user['id']}",
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton(
                                    icon: const Icon(Icons.more_horiz),
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Text("Edit"),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text(
                                          "Hapus",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                    onSelected: (val) {
                                      if (val == 'edit') {
                                        _showEditUserDialog(user);
                                      }
                                      if (val == 'delete') {
                                        _showDeleteConfirmDialog(
                                          user['id'],
                                          user['email'],
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Tombol Tambah yang senada dengan desain (Tombol Panjang +)
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: GestureDetector(
              onTap: _showAddUserDialog,
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Icon(Icons.add, color: Color(0xFF1A237E)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
        const Text(
          " :  ",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
