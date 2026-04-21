import 'package:flutter/material.dart';
import 'package:ebus_app/screens/driver/driver_tracking_page.dart';

class DriverDashboard extends StatelessWidget {
  final String email;
  final int busId; // 🔥 penting untuk tracking

  const DriverDashboard({super.key, required this.email, required this.busId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver Dashboard"),
        backgroundColor: const Color(0xFF001F3F),
        foregroundColor: Colors.white,
      ),

      // =========================
      // SIDEBAR MENU
      // =========================
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF001F3F)),
              accountName: const Text("Driver Bus"),
              accountEmail: Text(email),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40),
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
              leading: const Icon(Icons.directions_bus),
              title: const Text("Status Bus"),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Fitur segera hadir")),
                );
              },
            ),

            const Spacer(),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout"),
              onTap: () {
                Navigator.pushReplacementNamed(context, "/login");
              },
            ),
          ],
        ),
      ),

      // =========================
      // BODY DASHBOARD
      // =========================
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 👤 CARD PROFILE
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 3,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: const Text("Driver"),
                subtitle: Text(email),
              ),
            ),

            const SizedBox(height: 20),

            // 🚍 MENU GRID
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _menuCard(
                    context,
                    icon: Icons.location_on,
                    title: "Mulai Tracking",
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DriverTrackingPage(busId: busId),
                        ),
                      );
                    },
                  ),

                  _menuCard(
                    context,
                    icon: Icons.map,
                    title: "Lihat Rute",
                    color: Colors.orange,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Fitur rute belum tersedia"),
                        ),
                      );
                    },
                  ),

                  _menuCard(
                    context,
                    icon: Icons.history,
                    title: "Riwayat",
                    color: Colors.blue,
                    onTap: () {},
                  ),

                  _menuCard(
                    context,
                    icon: Icons.settings,
                    title: "Pengaturan",
                    color: Colors.grey,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // WIDGET MENU CARD
  // =========================
  Widget _menuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
