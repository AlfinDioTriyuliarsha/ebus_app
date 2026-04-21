import 'package:flutter/material.dart';
import 'package:ebus_app/screens/driver/driver_tracking_page.dart';

class DriverDashboard extends StatelessWidget {
  final String email;
  final int busId;

  const DriverDashboard({super.key, required this.email, required this.busId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver Dashboard"),
        backgroundColor: Colors.blue,
      ),

      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              child: Text(
                "Driver\n$email",
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text("Tracking GPS"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DriverTrackingPage(busId: busId),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.map),
              title: const Text("Lihat Rute"),
              onTap: () {},
            ),

            ListTile(
              leading: const Icon(Icons.history),
              title: const Text("Riwayat Perjalanan"),
              onTap: () {},
            ),
          ],
        ),
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Selamat datang Driver\n$email",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text("Mulai Tracking"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DriverTrackingPage(busId: busId),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
