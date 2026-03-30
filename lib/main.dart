import 'package:ebus_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/forgot_password_screen.dart'; // TAMBAHAN: Import halaman lupa password
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi API Service
  await ApiService.init();

  // Inisialisasi Facebook Auth khusus Web agar tombol merespon
  if (kIsWeb) {
    await FacebookAuth.i.webAndDesktopInitialize(
      appId: "1234567890", // Ganti dengan App ID dari Meta Developer
      cookie: true,
      xfbml: true,
      version: "v15.0",
    );
  }

  runApp(const EBusApp());
}

class EBusApp extends StatelessWidget {
  const EBusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Bus App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(),
      // TAMBAHAN: Daftarkan routes agar navigasi lebih mudah
      routes: {
        '/login': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
      },
    );
  }
}
