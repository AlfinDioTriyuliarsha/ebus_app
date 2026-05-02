// lib/services/api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiService {
  // Ganti dengan domain Railway Anda
  static const String baseUrl = "https://ebusapp-production-4fdd.up.railway.app";

  /// Header default
  static Map<String, String> get _headers => {
    "Content-Type": "application/json",
  };

  /// Fungsi init sekarang hanya untuk log, karena baseUrl sudah konstan
  static Future<void> init() async {
    print("✅ Base URL Terhubung ke Cloud: $baseUrl");
  }

  // ==========================================================
  // LOGIN (SUDAH DITAMBAHKAN DEVICE)
  // ==========================================================
  static Future<Map<String, dynamic>> login(
    String email,
    String password, {
    required String device,
  }) async {
    final url = Uri.parse("$baseUrl/api/users/login");

    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          "email": email,
          "password": password,
          "device": device,
        }),
      );

      // Proteksi jika respon bukan JSON atau error server
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "success": false, 
          "message": "Server error (${response.statusCode})"
        };
      }
    } catch (e) {
      return {"success": false, "message": "Tidak bisa terhubung ke server: $e"};
    }
  }

  // REGISTER
  static Future<Map<String, dynamic>> register(
    String email,
    String password, {
    String? name,
  }) async {
    final url = Uri.parse("$baseUrl/api/users");

    final body = {
      "email": email,
      "password": password,
      if (name != null) "name": name,
      "role": "penumpang",
    };

    try {
      final res = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(body),
      );

      return jsonDecode(res.body);
    } catch (e) {
      return {
        "success": false,
        "message": "Tidak bisa terhubung ke server: $e",
      };
    }
  }

  // GET Users
  static Future<List<dynamic>> getUsers() async {
    final url = Uri.parse("$baseUrl/api/users");
    try {
      final res = await http.get(url, headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return body is List ? body : body["data"];
      } else {
        throw Exception("Gagal ambil data user: ${res.body}");
      }
    } catch (e) {
      throw Exception("Tidak bisa ambil data user: $e");
    }
  }

  // GET User by ID
  static Future<Map<String, dynamic>> getUserById(int id) async {
    final url = Uri.parse("$baseUrl/api/users/$id");

    try {
      final res = await http.get(url, headers: _headers);
      final decodedData = jsonDecode(res.body);

      if (res.statusCode == 200 && decodedData['success'] == true) {
        // Mengambil objek 'data' sesuai struktur backend yang baru
        return decodedData['data'];
      } else {
        throw Exception(decodedData['message'] ?? "Gagal ambil data user");
      }
    } catch (e) {
      print("❌ Error di getUserById: $e");
      throw Exception("Tidak bisa ambil data user: $e");
    }
  }

  // CREATE User
  static Future<bool> addUser(Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl/api/users");
    final res = await http.post(url, headers: _headers, body: jsonEncode(data));
    return res.statusCode == 200 || res.statusCode == 201;
  }

  // UPDATE User
  static Future<bool> updateUser(int id, Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl/api/users/$id");
    try {
      final res = await http.put(
        url,
        headers: _headers,
        body: jsonEncode(data),
      );

      // Web terkadang mengirim 201 atau 204, kita amankan check-nya
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      print("❌ Error di updateUser: $e");
      return false;
    }
  }

  // DELETE User
  static Future<bool> deleteUser(int id) async {
    final url = Uri.parse("$baseUrl/api/users/$id");
    final res = await http.delete(url, headers: _headers);
    return res.statusCode == 200;
  }

  // ==========================================================
  // SOCIAL LOGIN
  // ==========================================================
  static Future<Map<String, dynamic>> socialLogin({
    required String email,
    required String name,
    required String provider,
    required String socialId,
  }) async {
    final url = Uri.parse('$baseUrl/api/users/social-login');
    final String device = kIsWeb ? "web" : "mobile";

    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'name': name,
          'provider': provider,
          'social_id': socialId,
          'device': device,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      throw Exception("Tidak bisa terhubung ke server: $e");
    }
  }

  // FORGOT PASSWORD
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final url = Uri.parse("$baseUrl/api/users/forgot-password");
    try {
      final res = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({"email": email}),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"success": false, "message": "Koneksi gagal: $e"};
    }
  }

  // RESET PASSWORD
  static Future<Map<String, dynamic>> resetPassword(
    String email,
    String newPassword,
  ) async {
    final url = Uri.parse("$baseUrl/api/users/reset-password");
    try {
      final res = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({"email": email, "newPassword": newPassword}),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {"success": false, "message": "Koneksi gagal: $e"};
    }
  }

  // GET SEMUA BUS (Untuk semua Role)
  static Future<List<dynamic>> getBuses() async {
    final url = Uri.parse("$baseUrl/api/buses"); // Pastikan 'buses'
    try {
      final res = await http.get(url, headers: _headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        // Karena backend kamu mengirim { success: true, data: [...] }
        return body["data"];
      } else {
        throw Exception("Gagal ambil data bus");
      }
    } catch (e) {
      throw Exception("Koneksi error: $e");
    }
  }

  static Future<List<dynamic>> getSchedules(int companyId) async {
    final url = Uri.parse("$baseUrl/api/schedules?company_id=$companyId");

    try {
      final res = await http.get(url, headers: _headers);

      // Cek apakah status code 200 (Berhasil)
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return body["data"] ?? [];
      } else {
        // Jika status 500, jangan di-decode sebagai data normal
        print("❌ Server Error: ${res.statusCode}");
        return []; // Kembalikan list kosong agar UI tidak crash
      }
    } catch (e) {
      print("❌ Koneksi Error di getSchedules: $e");
      return [];
    }
  }
}
