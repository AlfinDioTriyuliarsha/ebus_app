import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Tambahkan ini
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart'; // Tambahkan ini

// Gunakan package import sesuai struktur project kamu
import 'package:ebus_app/screens/super_admin_dashboard.dart';
import 'package:ebus_app/screens/admin_perusahaan_dashboard.dart';
import 'package:ebus_app/screens/agen_dashboard.dart';
import 'package:ebus_app/screens/penumpang_dashboard.dart';
import 'package:ebus_app/screens/keluarga_dashboard.dart';

class DashboardScreen extends StatelessWidget {
  final String role;
  final String email;

  const DashboardScreen({super.key, required this.role, required this.email});

  // -------------------------------------------------------------------
  // TAMBAHAN: Fungsi Logout Global
  // -------------------------------------------------------------------
  static Future<void> handleLogout(BuildContext context) async {
    try {
      // 1. Logout dari Google
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
        await googleSignIn.disconnect();
      }

      // 2. Logout dari Facebook
      await FacebookAuth.instance.logOut();

      // 3. Arahkan kembali ke Login dan hapus semua history navigasi
      if (!context.mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Berhasil keluar dari akun")),
      );
    } catch (e) {
      debugPrint("Error Logout: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔑 Normalisasi role biar aman
    String normalizedRole = role
        .toLowerCase()
        .replaceAll("_", "")
        .replaceAll(" ", "");

    Widget dashboard;

    switch (normalizedRole) {
      case "superadmin":
        dashboard = SuperAdminDashboard(email: email);
        break;
      case "adminperusahaan":
        dashboard = AdminPerusahaanDashboard(email: email);
        break;
      case "agen":
        dashboard = AgenDashboard(email: email);
        break;
      case "penumpang":
        dashboard = PenumpangDashboard(email: email);
        break;
      case "keluarga":
        dashboard = KeluargaDashboard(email: email);
        break;
      default:
        dashboard = Scaffold(
          appBar: AppBar(title: const Text("Dashboard")),
          body: Center(child: Text("⚠️ Role tidak dikenali: $role")),
        );
    }

    return dashboard;
  }
}
