import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:ebus_app/services/api_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PengaturanAkunPage extends StatefulWidget {
  const PengaturanAkunPage({super.key});

  @override
  State<PengaturanAkunPage> createState() => _PengaturanAkunPageState();
}

class _PengaturanAkunPageState extends State<PengaturanAkunPage> {
  // Controller sekarang tidak diisi teks manual agar tidak menimpa data asli
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  File? _image;
  Uint8List? _webImage;
  XFile? _pickedFile;
  String? _serverPhotoUrl; // Untuk menyimpan nama file foto dari database

  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Ambil data dari server saat halaman pertama kali dibuka
  }

  // --- FUNGSI BARU: MENGAMBIL DATA DARI DATABASE ---
  Future<void> _fetchUserData() async {
    // Cek apakah widget masih ada di layar
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      // Pastikan ID yang dikirim valid (bukan 0 atau null)
      final response = await ApiService.getUserById(1);

      // Cek lagi sebelum setState
      if (!mounted) return;

      if (response != null) {
        setState(() {
          _emailController.text = response['email'] ?? "";
          _serverPhotoUrl = response['profile_image'];
        });
      }
    } catch (e) {
      if (mounted) {
        debugPrint("Gagal mengambil data user: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImage = bytes;
          _pickedFile = pickedFile;
        });
      } else {
        setState(() {
          _image = File(pickedFile.path);
          _pickedFile = pickedFile;
        });
      }
    }
  }

  Future<void> _handleSave() async {
    // Cek apakah widget masih ada di layar
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      // Pastikan ID yang dikirim valid (bukan 0 atau null)
      final response = await ApiService.getUserById(1);

      // Cek lagi sebelum setState
      if (!mounted) return;

      if (response != null) {
        setState(() {
          _emailController.text = response['email'] ?? "";
          _serverPhotoUrl = response['profile_image'];
        });
      }
    } catch (e) {
      if (mounted) {
        debugPrint("Gagal mengambil data user: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 25),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _cardWrapper(
                      title: "Informasi Profil",
                      icon: Icons.person_outline,
                      child: Column(
                        children: [
                          _profileWidget(),
                          const SizedBox(height: 30),
                          _fieldInput(
                            "Email",
                            _emailController,
                            Icons.email,
                            enabled: false,
                          ),
                          const SizedBox(height: 15),
                          _fieldInput(
                            "Ganti Password",
                            _passController,
                            Icons.lock,
                            isPass: true,
                          ),
                          const SizedBox(height: 25),
                          _btnSimpan(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 25),
                  Expanded(
                    flex: 1,
                    child: _cardWrapper(
                      title: "About",
                      icon: Icons.info_outline,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Icon(
                              Icons.code,
                              size: 50,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _aboutInfo("Developer", "Alfin Dio Triyuliarsha"),
                          _aboutInfo(
                            "Institusi",
                            "Universitas Bhinneka Nusantara",
                          ),
                          _aboutInfo("Unit", "Lab Data Science"),
                          _aboutInfo("Versi", "V.0.0.1"),
                          const Divider(),
                          const Text(
                            "Aplikasi manajemen transportasi bus pintar.",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_isLoading) _loadingOverlay(),
      ],
    );
  }

  Widget _profileWidget() {
    // Tentukan provider gambar berdasarkan urutan prioritas:
    // 1. Gambar yang baru dipilih (_pickedFile)
    // 2. Gambar yang sudah ada di server (_serverPhotoUrl)
    // 3. Icon default (null)
    ImageProvider? imageProvider;
    if (_pickedFile != null) {
      imageProvider = kIsWeb
          ? MemoryImage(_webImage!)
          : FileImage(File(_pickedFile!.path)) as ImageProvider;
    } else if (_serverPhotoUrl != null && _serverPhotoUrl!.isNotEmpty) {
      // Pastikan IP Address sesuai dengan server Node.js Anda
      imageProvider = NetworkImage(
        "http://localhost:5000/uploads/profiles/$_serverPhotoUrl",
      );
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey[300],
          backgroundImage: imageProvider,
          child: imageProvider == null
              ? const Icon(Icons.person, size: 70, color: Colors.white)
              : null,
        ),
        GestureDetector(
          onTap: _pickImage,
          child: const CircleAvatar(
            backgroundColor: Color(0xFF007BFF),
            radius: 18,
            child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _fieldInput(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    bool isPass = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          obscureText: isPass,
          enabled: enabled,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _btnSimpan() {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A237E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: _handleSave,
        child: const Text(
          "SIMPAN PERUBAHAN",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _cardWrapper({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF1A237E)),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Divider(height: 30),
          child,
        ],
      ),
    );
  }

  Widget _aboutInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _loadingOverlay() => Container(
    color: Colors.black26,
    child: const Center(child: CircularProgressIndicator()),
  );
}
