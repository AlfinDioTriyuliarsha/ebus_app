import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import 'package:ebus_app/screens/super_admin_dashboard.dart';
import 'package:ebus_app/screens/admin_perusahaan_dashboard.dart';
import 'package:ebus_app/screens/agen_dashboard.dart';
import 'package:ebus_app/screens/penumpang_dashboard.dart';
import 'package:ebus_app/screens/keluarga_dashboard.dart';

class DashboardScreen extends StatelessWidget {
  final String role;
  final String email;
  final int userId;

  const DashboardScreen({
    super.key,
    required this.role,
    required this.email,
    required this.userId,
  });

  static Future<void> handleLogout(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
        await googleSignIn.disconnect();
      }
      await FacebookAuth.instance.logOut();

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
    String normalizedRole = role
        .toLowerCase()
        .replaceAll("_", "")
        .replaceAll(" ", "");

    Widget dashboard;

    // FIX: Tambahkan userId: userId di setiap pemanggilan dashboard
    switch (normalizedRole) {
      case "superadmin":
        dashboard = SuperAdminDashboard(
          email: email,
          userId: userId, // Perbaikan di sini (Baris 65)
        );
        break;
      case "adminperusahaan":
        dashboard = AdminPerusahaanDashboard(
          email: email,
          companyId: userId,
          userId: userId, 
        );
        break;
      case "agen":
        dashboard = AgenDashboard(
          email: email,
          // userId: userId,
        );
        break;
      case "penumpang":
        dashboard = PenumpangDashboard(
          email: email,
          // userId: userId,
        );
        break;
      case "keluarga":
        dashboard = KeluargaDashboard(
          email: email,
          // userId: userId,
        );
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
