import 'dart:convert';
import 'package:ebus_app/screens/driver/DriverDashboard.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import 'package:ebus_app/services/api_service.dart';

import 'package:ebus_app/screens/super_admin_dashboard.dart';
import 'package:ebus_app/screens/admin_perusahaan_dashboard.dart';
import 'package:ebus_app/screens/agen_dashboard.dart';
import 'package:ebus_app/screens/penumpang_dashboard.dart';

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
    required this.busId,
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
  // AMBIL BUS ID DRIVER
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

  // =========================
  // BUILD
  // =========================
  @override
  Widget build(BuildContext context) {
    String normalizedRole = role
        .toLowerCase()
        .replaceAll("_", "")
        .replaceAll(" ", "");

    switch (normalizedRole) {
      case "superadmin":
        return SuperAdminDashboard(email: email, userId: userId);

      case "adminperusahaan":
        return AdminPerusahaanDashboard(
          email: email,
          companyId: userId,
          userId: userId,
        );

      case "agen":
        return AgenDashboard(email: email);

      case "penumpang":
        return PenumpangDashboard(email: email);

      case "driver":
        return FutureBuilder<int>(
          future: getBusId(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final busId = snapshot.data ?? 0;

            return DriverDashboard(
              email: email,
              userId: userId,
              busId: busId,
            );
          },
        );

      default:
        return Scaffold(
          appBar: AppBar(title: const Text("Dashboard")),
          body: Center(child: Text("⚠️ Role tidak dikenali: $role")),
        );
    }
  }
}
