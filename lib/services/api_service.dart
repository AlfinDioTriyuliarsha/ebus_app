// lib/services/api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;

class ApiService {
  static String? baseUrl;

  /// Header default
  static Map<String, String> get _headers => {
    "Content-Type": "application/json",
  };

  /// Inisialisasi baseUrl otomatis
  static Future<void> init() async {
    if (kIsWeb) {
      final host = Uri.base.host;
      baseUrl = "http://$host:3000";
    }
    // ANDROID (HP ASLI & EMULATOR)
    else if (Platform.isAndroid) {
      baseUrl = "http://10.80.149.226:3000";
    }
    // IOS
    else if (Platform.isIOS) {
      baseUrl = "http://10.80.149.226:3000";
    }
    // DESKTOP
    else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      baseUrl = "http://localhost:3000";
    } else {
      baseUrl = "http://10.80.149.226:3000";
    }

    print("✅ Base URL terdeteksi: $baseUrl");
  }

  // ==========================================================
  // LOGIN (SUDAH DITAMBAHKAN DEVICE)
  // ==========================================================
  static Future<Map<String, dynamic>> login(
    String email,
    String password, {
    required String device, // 🔥 TAMBAHAN WAJIB
  }) async {
    if (baseUrl == null) {
      throw Exception(
        "API belum diinisialisasi. Panggil ApiService.init() dulu.",
      );
    }

    final url = Uri.parse("$baseUrl/api/users/login");

    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          "email": email,
          "password": password,
          "device": device, // 🔥 DIKIRIM KE BACKEND
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return jsonDecode(response.body);
      }
    } catch (e) {
      throw Exception("Tidak bisa terhubung ke server: $e");
    }
  }

  // REGISTER
  static Future<Map<String, dynamic>> register(
    String email,
    String password, {
    String? name,
  }) async {
    if (baseUrl == null) {
      throw Exception(
        "API belum diinisialisasi. Panggil ApiService.init() dulu.",
      );
    }

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
    final res = await http.get(url, headers: _headers);
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Gagal ambil data user: ${res.body}");
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
    final res = await http.put(url, headers: _headers, body: jsonEncode(data));
    return res.statusCode == 200;
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
    if (baseUrl == null) {
      throw Exception(
        "API belum diinisialisasi. Panggil ApiService.init() dulu.",
      );
    }

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
}
