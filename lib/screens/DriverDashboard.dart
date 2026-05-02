import 'package:flutter/material.dart';

class DriverDashboard extends StatelessWidget {
  final String email;
  final int busId;

  const DriverDashboard({
    super.key,
    required this.email,
    required this.busId,
  });

  @override
  Widget build(BuildContext context) {
    // 🚨 kalau belum dapat bus
    if (busId == 0) {
      return Scaffold(
        appBar: AppBar(title: const Text("Driver Dashboard")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning, size: 80, color: Colors.orange),
              const SizedBox(height: 20),
              const Text(
                "Anda belum mendapat bus dari admin",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // 🔥 tombol refresh
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/dashboard');
                },
                icon: const Icon(Icons.refresh),
                label: const Text("Refresh"),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ kalau sudah ada bus
    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver Dashboard"),
        backgroundColor: Colors.blue,
      ),

      // 🔥 DRAWER MENU
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

      // 🔥 BODY DASHBOARD
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // INFO DRIVER
            Card(
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.directions_bus, size: 40),
                title: Text("Bus ID: $busId"),
                subtitle: Text("Driver: $email"),
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 BUTTON ACTION
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _menuButton(
                    icon: Icons.location_on,
                    title: "Tracking GPS",
                    color: Colors.blue,
                    onTap: () {
                    },
                  ),
                  _menuButton(
                    icon: Icons.play_arrow,
                    title: "Mulai Perjalanan",
                    color: Colors.green,
                    onTap: () {},
                  ),
                  _menuButton(
                    icon: Icons.stop,
                    title: "Selesai",
                    color: Colors.red,
                    onTap: () {},
                  ),
                  _menuButton(
                    icon: Icons.refresh,
                    title: "Refresh",
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 WIDGET BUTTON GRID
  Widget _menuButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}