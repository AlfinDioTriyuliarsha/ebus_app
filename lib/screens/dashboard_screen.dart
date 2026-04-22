import 'dart:convert'; // ✅ untuk jsonDecode
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // ✅ FIX http
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import 'package:ebus_app/services/api_service.dart'; // ✅ FIX ApiService

import 'package:ebus_app/screens/super_admin_dashboard.dart';
import 'package:ebus_app/screens/admin_perusahaan_dashboard.dart';
import 'package:ebus_app/screens/agen_dashboard.dart';
import 'package:ebus_app/screens/penumpang_dashboard.dart';
import 'package:ebus_app/screens/driverdashboard.dart'; // ⚠️ pastikan nama file huruf kecil semua

class DashboardScreen extends StatelessWidget {
  final String role;
  final String email;
  final int userId;
  final int busId;

  const DashboardScreen({
    super.key,
    required this.role,
    required this.email,
    required this.userId,
    this.busId = 0,
  });

  // =========================
  // LOGOUT
  // =========================
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

  // =========================
  // AMBIL BUS ID DARI DRIVER
  // =========================
  Future<int> getBusId(int userId) async {
    try {
      final res = await http.get(
        Uri.parse("${ApiService.baseUrl}/api/buses/driver/$userId"),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (data['success'] == true) {
          return data['data']['bus_id'] ?? 0;
        }
      }
    } catch (e) {
      debugPrint("ERROR GET BUS ID: $e");
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    String normalizedRole = role
        .toLowerCase()
        .replaceAll("_", "")
        .replaceAll(" ", "");

    Widget dashboard;

    switch (normalizedRole) {
      case "superadmin":
        dashboard = SuperAdminDashboard(email: email, userId: userId);
        break;

      case "adminperusahaan":
        dashboard = AdminPerusahaanDashboard(
          email: email,
          companyId: userId,
          userId: userId,
        );
        break;

      case "agen":
        dashboard = AgenDashboard(email: email);
        break;

      case "penumpang":
        dashboard = PenumpangDashboard(email: email);
        break;

      case "driver":
        // 🔥 DRIVER PAKAI FUTURE (AMBIL BUS ID DARI SERVER)
        return FutureBuilder<int>(
          future: getBusId(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!snapshot.hasData || snapshot.data == 0) {
              return const Scaffold(
                body: Center(child: Text("Bus belum terdaftar")),
              );
            }

            return DriverDashboard(email: email, busId: snapshot.data!);
          },
        );

      default:
        dashboard = Scaffold(
          appBar: AppBar(title: const Text("Dashboard")),
          body: Center(child: Text("⚠️ Role tidak dikenali: $role")),
        );
    }

    return dashboard;
  }
}
