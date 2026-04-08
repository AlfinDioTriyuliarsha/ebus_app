import 'package:ebus_app/screens/admin_perusahaan/LaporanOperasionalPage.dart';
import 'package:ebus_app/screens/admin_perusahaan/ManajemenAgentPage.dart';
import 'package:ebus_app/screens/admin_perusahaan/ManajemenArmadaPage.dart';
import 'package:ebus_app/screens/admin_perusahaan/ManajemenDriverPage.dart';
import 'package:ebus_app/screens/admin_perusahaan/ManajemenRutePage.dart';
import 'package:ebus_app/screens/admin_perusahaan/MonitoringBusMapAdmin.dart';
import 'package:ebus_app/super_admin/PengaturanAkunPage.dart';
import 'package:flutter/material.dart';

class AdminPerusahaanDashboard extends StatefulWidget {
  final String email;
  final int companyId;
  final int userId;

  const AdminPerusahaanDashboard({
    super.key,
    required this.email,
    required this.companyId,
    required this.userId,
  });

  @override
  State<AdminPerusahaanDashboard> createState() =>
      _AdminPerusahaanDashboardState();
}

class _AdminPerusahaanDashboardState extends State<AdminPerusahaanDashboard> {
  int _selectedIndex = 0;

  final List<String> _menuTitles = [
    "Manajemen Agent",
    "Manajemen Armada Bus",
    "Manajemen Rute dan Zona",
    "Manajemen Driver",
    "Monitoring Bus",
    "Laporan Operasional",
    "Pengaturan Akun",
  ];

  // Fungsi untuk mendapatkan halaman secara langsung berdasarkan index
  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return ManajemenAgentPage(companyId: widget.companyId);
      case 1:
        return ManajemenArmadaPage(companyId: widget.companyId);
      case 2:
        return ManajemenRutePage(companyId: widget.companyId);
      case 3:
        return ManajemenDriverPage(companyId: widget.companyId);
      case 4:
        return MonitoringBusMapAdmin(companyId: widget.companyId);
      case 5:
        return const LaporanOperasionalPage();
      case 6:
        return PengaturanAkunPage(userId: widget.userId);
      default:
        return ManajemenAgentPage(companyId: widget.companyId);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001F3F),
      body: Row(
        children: [
          // SIDEBAR
          Container(
            width: 250,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Text(
                    "E - BUS",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildSidebarItem(0, Icons.people, "Manajemen Agent"),
                _buildSidebarItem(1, Icons.directions_bus, "Manajemen Armada"),
                _buildSidebarItem(2, Icons.map, "Manajemen Rute"),
                _buildSidebarItem(3, Icons.person_pin, "Manajemen Driver"),
                _buildSidebarItem(4, Icons.location_on, "Monitoring Bus"),
                _buildSidebarItem(5, Icons.bar_chart, "Laporan"),
                _buildSidebarItem(6, Icons.settings, "Pengaturan Akun"),
                const Spacer(),
                _buildSidebarItem(
                  -1,
                  Icons.logout,
                  "Keluar",
                  color: Colors.redAccent,
                ),
              ],
            ),
          ),

          // MAIN CONTENT AREA
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E5EC),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Dashboard
                  Padding(
                    padding: const EdgeInsets.all(30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _menuTitles[_selectedIndex].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              "Admin Perusahaan",
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(width: 10),
                            const CircleAvatar(
                              backgroundColor: Colors.grey,
                              radius: 15,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // AREA KONTEN LANGSUNG (Tanpa Tombol)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child:
                          _getSelectedPage(), // Memanggil halaman secara dinamis
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    int index,
    IconData icon,
    String title, {
    Color color = Colors.white,
  }) {
    bool isSelected = _selectedIndex == index;
    return ListTile(
      selected: isSelected,
      selectedTileColor: Colors.blue.withOpacity(0.1),
      leading: Icon(icon, color: isSelected ? Colors.blue : color),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blue : color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        if (index == -1) {
          Navigator.pop(context);
        } else {
          _onItemTapped(index);
        }
      },
    );
  }
}
