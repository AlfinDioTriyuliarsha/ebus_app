import 'package:ebus_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dashboard_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? "1020065400092-kt41fl3pb6950jfmbbf7cuvqr9hb29s6.apps.googleusercontent.com"
        : null,
  );

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      if (account != null) {
        _handleSocialLogin(
          email: account.email,
          name: account.displayName ?? "User Google",
          provider: "google",
          id: account.id,
        );
      }
    });

    if (kIsWeb) {
      _googleSignIn.signInSilently();
    }
  }

  // ================= RESPONSIVE BUILD =================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 900;

        return Scaffold(
          backgroundColor: Colors.white,
          body: isMobile
              ? SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 280,
                        width: double.infinity,
                        child: Image.network(
                          'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?q=80&w=2017&auto=format&fit=crop',
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 30,
                        ),
                        child: _buildLoginForm(),
                      ),
                    ],
                  ),
                )
              : Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(25.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.network(
                            'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?q=80&w=2017&auto=format&fit=crop',
                            fit: BoxFit.cover,
                            height: double.infinity,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 60),
                          child: _buildLoginForm(),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildLoginForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "WELCOME BACK!",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Color(0xFF004D74),
          ),
        ),
        const SizedBox(height: 40),
        _buildLabel("EMAIL"),
        _buildInputField(_emailController),
        const SizedBox(height: 20),
        _buildLabel("PASSWORD"),
        _buildInputField(_passwordController, isPassword: true),
        const SizedBox(height: 35),
        SizedBox(
          width: double.infinity,
          child: Container(
            height: 55,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: const Color(0xFF0089D7),
            ),
            child: ElevatedButton(
              onPressed: _loading ? null : _handleEmailLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "MASUK",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _socialCircle(Icons.facebook, Colors.blue, _handleFacebookLogin),
            const SizedBox(width: 20),
            _socialCircle(Icons.g_mobiledata, Colors.red, _handleGoogleLogin),
          ],
        ),
        const SizedBox(height: 35),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const RegisterScreen()),
            ),
            child: const Text(
              "BELUM PUNYA AKUN? DAFTAR DISINI",
              style: TextStyle(
                color: Color(0xFF004D74),
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _showForgotPasswordDialog,
            child: const Text(
              "LUPA PASSWORD?",
              style: TextStyle(
                color: Color(0xFF004D74),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showForgotPasswordDialog() {
    final TextEditingController resetEmailController = TextEditingController();
    final TextEditingController newPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "RESET PASSWORD",
          style: TextStyle(
            color: Color(0xFF004D74),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Silakan masukkan email Anda dan password baru."),
            const SizedBox(height: 15),
            TextField(
              controller: resetEmailController,
              decoration: const InputDecoration(
                labelText: "Email Terdaftar",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPassController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password Baru",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("BATAL", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (resetEmailController.text.isEmpty ||
                  newPassController.text.isEmpty) {
                _showStatusMessage(
                  "Email dan Password baru harus diisi",
                  isError: true,
                );
                return;
              }

              final res = await ApiService.resetPassword(
                resetEmailController.text,
                newPassController.text,
              );

              if (res['success'] == true) {
                if (!mounted) return;
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
                _showStatusMessage(
                  "BERHASIL! Password Anda telah diperbarui.",
                  isError: false,
                );
              } else {
                _showStatusMessage(
                  // ignore: prefer_interpolation_to_compose_strings
                  "GAGAL! " + (res['message'] ?? "Email tidak ditemukan"),
                  isError: true,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0089D7),
            ),
            child: const Text(
              "RESET SEKARANG",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleSocialLogin({
    required String email,
    required String name,
    required String provider,
    required String id,
  }) async {
    try {
      setState(() => _loading = true);
      final res = await ApiService.socialLogin(
        email: email,
        name: name,
        provider: provider,
        socialId: id,
      );
      if (!mounted) return;
      _processResponse(res, email);
    } catch (e) {
      _showError("$provider Login Error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    try {
      await _googleSignIn.signIn();
    } catch (e) {
      _showError("Google Sign In gagal. Pastikan popup diizinkan.");
      print("Detail Error: $e");
    }
  }

  Future<void> _handleFacebookLogin() async {
    try {
      setState(() => _loading = true);
      final LoginResult res = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
      );

      if (res.status == LoginStatus.success) {
        final userData = await FacebookAuth.instance.getUserData();
        _handleSocialLogin(
          email: userData['email'] ?? "user_fb@ebus.com",
          name: userData['name'] ?? "User Facebook",
          provider: "facebook",
          id: userData['id'].toString(),
        );
      } else if (res.status == LoginStatus.cancelled) {
        _showError("Login dibatalkan");
      } else {
        _showError("Facebook Error: ${res.message}");
      }
    } catch (e) {
      _showError("Facebook Login Error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  void _processResponse(Map<String, dynamic> data, String fallbackEmail) async {
    if (data['success'] == true) {
      final userData = data['data'];

      final int userId = int.parse(userData['id'].toString());
      final String role = userData['role'] ?? 'penumpang';
      final String email = userData['email'] ?? fallbackEmail;

      print("✅ LOGIN: $userId | $role");

      if (role == "driver") {
        try {
          final res = await http.get(
            Uri.parse("${ApiService.baseUrl}/api/buses/driver/$userId"),
          );

          final result = jsonDecode(res.body);

          // ignore: unused_local_variable
          int busId = 0;

          if (result['success'] == true) {
            busId = result['data']['bus_id'] ?? 0;
          }

          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (c) => DashboardScreen(
                role: role, // ✅ FIX
                email: email, // ✅ FIX
                userId: userId, // ✅ FIX
              ),
            ),
          );
        } catch (e) {
          _showError("Gagal ambil data bus");
        }
      } else {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                DashboardScreen(role: role, email: email, userId: userId),
          ),
        );
      }
    } else {
      _showError(data['message'] ?? "Login gagal");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _handleEmailLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError("Email dan password tidak boleh kosong");
      return;
    }

    setState(() => _loading = true);

    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text.trim();

      print("=================================");
      print("DEVICE LOGIN: ${kIsWeb ? "WEB" : "MOBILE"}");
      print("EMAIL DIKIRIM: '$email'");
      print("PASSWORD DIKIRIM: '$password'");
      print("=================================");

      final res = await ApiService.login(
        email,
        password,
        device: kIsWeb ? "web" : "mobile",
      );

      _processResponse(res, email);
    } catch (e) {
      print("ERROR LOGIN: $e");
      _showError("Gagal Login: ${e.toString()}");
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildLabel(String t) => Text(
    t,
    style: const TextStyle(
      color: Color(0xFF004D74),
      fontWeight: FontWeight.bold,
      fontSize: 15,
    ),
  );

  Widget _buildInputField(TextEditingController c, {bool isPassword = false}) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF004D74), width: 1.8),
      ),
      child: TextField(
        controller: c,
        obscureText: isPassword ? _obscurePassword : false,
        textAlign: TextAlign.center,
        autocorrect: false,
        enableSuggestions: false,
        textCapitalization: TextCapitalization.none,
        keyboardType: isPassword
            ? TextInputType.visiblePassword
            : TextInputType.emailAddress,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF004D74),
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _socialCircle(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, size: 30, color: color),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  bool _obscurePass = true;
  bool _loading = false;

  Future<void> _handleRegister() async {
    if (_emailController.text.isEmpty || _passController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Field tidak boleh kosong")));
      return;
    }
    if (_passController.text != _confirmPassController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Password tidak cocok")));
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await ApiService.register(
        _emailController.text,
        _passController.text,
      );
      if (res['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Berhasil daftar! Silakan masuk."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal daftar: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 900;

        return Scaffold(
          body: isMobile
              ? SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 280,
                        width: double.infinity,
                        child: Image.network(
                          'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?q=80&w=2017&auto=format&fit=crop',
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(25),
                        child: _buildRegisterContent(),
                      ),
                    ],
                  ),
                )
              : Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(25.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.network(
                            'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?q=80&w=2017&auto=format&fit=crop',
                            fit: BoxFit.cover,
                            height: double.infinity,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 60),
                          child: _buildRegisterContent(),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildRegisterContent() {
    return Column(
      children: [
        const Text(
          "BUAT AKUN",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Color(0xFF004D74),
          ),
        ),
        const SizedBox(height: 30),
        _dynamicField("EMAIL", _emailController),
        _dynamicField("PASSWORD", _passController, isPass: true),
        _dynamicField(
          "KONFIRMASI PASSWORD",
          _confirmPassController,
          isPass: true,
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0089D7),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    "BUAT AKUN",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 20),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text(
              "SUDAH PUNYA AKUN? MASUK",
              style: TextStyle(
                color: Color(0xFF004D74),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dynamicField(
    String label,
    TextEditingController controller, {
    bool isPass = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF004D74),
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 5, bottom: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFF004D74), width: 1.5),
          ),
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            obscureText: isPass ? _obscurePass : false,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.none,
            keyboardType: isPass
                ? TextInputType.visiblePassword
                : TextInputType.emailAddress,
            decoration: InputDecoration(
              border: InputBorder.none,
              suffixIcon: isPass
                  ? IconButton(
                      icon: Icon(
                        _obscurePass ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
