import 'package:flutter/material.dart';
import 'package:ebus_app/services/api_service.dart'; // Pastikan path benar

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  
  bool _isEmailVerified = false; // Untuk berpindah tahap
  bool _isLoading = false;

  // Tahap 1: Verifikasi Email ke Backend
  void _verifyEmail() async {
    setState(() => _isLoading = true);
    final response = await ApiService.forgotPassword(_emailController.text);
    setState(() => _isLoading = false);

    if (response['success']) {
      setState(() => _isEmailVerified = true);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email ditemukan! Silakan masukkan password baru.")),
      );
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? "Email tidak terdaftar")),
      );
    }
  }

  // Tahap 2: Update Password Baru
  void _resetPassword() async {
    setState(() => _isLoading = true);
    final response = await ApiService.resetPassword(
      _emailController.text,
      _newPasswordController.text,
    );
    setState(() => _isLoading = false);

    if (response['success']) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password berhasil diperbarui! Silakan login.")),
      );
      // ignore: use_build_context_synchronously
      Navigator.pop(context); // Kembali ke halaman Login
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal memperbarui password")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lupa Password")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.lock_reset, size: 80, color: Theme.of(context).primaryColor),
            const SizedBox(height: 20),
            Text(
              _isEmailVerified ? "Buat Password Baru" : "Pulihkan Akun Anda",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _isEmailVerified 
                ? "Masukkan password baru untuk akun ${_emailController.text}" 
                : "Masukkan email yang terdaftar untuk mencari akun Anda.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Field Email (Read-only jika sudah terverifikasi)
            TextField(
              controller: _emailController,
              enabled: !_isEmailVerified,
              decoration: InputDecoration(
                labelText: "Email",
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 15),

            // Field Password Baru (Hanya muncul jika email sudah diverifikasi)
            if (_isEmailVerified) ...[
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password Baru",
                  prefixIcon: const Icon(Icons.vpn_key),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Tombol Aksi
            ElevatedButton(
              onPressed: _isLoading ? null : (_isEmailVerified ? _resetPassword : _verifyEmail),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white) 
                : Text(_isEmailVerified ? "Perbarui Password" : "Cek Email"),
            ),
          ],
        ),
      ),
    );
  }
}