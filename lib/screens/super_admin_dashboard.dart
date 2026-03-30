import 'package:ebus_app/super_admin/KelolaPerusahaanPage.dart';
import 'package:ebus_app/super_admin/KelolaPenggunaPage.dart';
import 'package:ebus_app/super_admin/LaporanDashboardPage.dart'; // Penambahan Import
import 'package:ebus_app/super_admin/MonitoringBusMapPage.dart';
import 'package:ebus_app/super_admin/PengaturanAkunPage.dart';
import 'package:flutter/material.dart';

class SuperAdminDashboard extends StatefulWidget {
  final String email;
  const SuperAdminDashboard({super.key, required this.email});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 768;
        bool isTablet =
            constraints.maxWidth >= 768 && constraints.maxWidth < 1100;

        return Scaffold(
          backgroundColor: const Color(0xFF001F3F),

          // ================= MOBILE DRAWER =================
          drawer: isMobile ? Drawer(child: _buildSidebar()) : null,

          body: Row(
            children: [
              // ================= SIDEBAR (Tablet & Desktop Only) =================
              if (!isMobile)
                SizedBox(width: isTablet ? 220 : 260, child: _buildSidebar()),

              // ================= AREA KONTEN =================
              Expanded(
                child: Container(
                  margin: EdgeInsets.all(isMobile ? 10 : 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7E9),
                    borderRadius: BorderRadius.circular(isMobile ? 20 : 30),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(isMobile ? 20 : 30),
                    child: Column(
                      children: [
                        _buildHeader(isMobile),
                        Expanded(child: _buildPage(_selectedIndex)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Bagian Sidebar Navy
  Widget _buildSidebar() {
    return Container(
      color: const Color(0xFF001F3F),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "E - BUS",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          _sidebarItem(0, "Kontrol Hak Akses", Icons.people),
          _sidebarItem(1, "Manajemen Perusahaan", Icons.business),
          _sidebarItem(2, "Monitoring Bus", Icons.directions_bus),
          _sidebarItem(3, "Laporan", Icons.bar_chart),
          _sidebarItem(4, "Pengaturan Akun", Icons.settings),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white70),
            title: const Text(
              "Keluar",
              style: TextStyle(color: Colors.white70),
            ),
            onTap: () => Navigator.pushReplacementNamed(context, "/login"),
          ),
        ],
      ),
    );
  }

  // Item Menu Sidebar
  Widget _sidebarItem(int index, String title, IconData icon) {
    bool isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });

        // Tutup drawer jika mobile
        if (Scaffold.of(context).isDrawerOpen) {
          Navigator.pop(context);
        }
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF007BFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Header Dashboard (Judul & Info User)
  Widget _buildHeader(bool isMobile) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 15 : 30,
        isMobile ? 20 : 30,
        isMobile ? 15 : 30,
        10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (isMobile)
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                ),
              Text(
                _getHeaderTitle(),
                style: TextStyle(
                  fontSize: isMobile ? 14 : 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A237E),
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (!isMobile)
                Text(
                  widget.email.split('@')[0],
                  style: const TextStyle(color: Colors.black54, fontSize: 16),
                ),
              const SizedBox(width: 10),
              CircleAvatar(
                backgroundColor: Colors.grey[400],
                radius: isMobile ? 16 : 20,
                child: const Icon(Icons.person, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getHeaderTitle() {
    switch (_selectedIndex) {
      case 0:
        return "KONTROL HAK AKSES PENGGUNA";
      case 1:
        return "MANAJEMEN PERUSAHAAN";
      case 2:
        return "MONITORING ARMADA";
      case 3:
        return "LAPORAN & STATISTIK";
      case 4:
        return "PENGATURAN AKUN";
      default:
        return "DASHBOARD";
    }
  }

  // --- LOGIKA HALAMAN ---

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return _buildKelolaPengguna();
      case 1:
        return _buildKelolaPerusahaan();
      case 2:
        return _buildMonitoringBus();
      case 3:
        return _buildLaporan();
      case 4:
        return _buildPengaturanAkun();
      default:
        return const Center(child: Text("Halaman tidak ditemukan"));
    }
  }

  Widget _buildKelolaPengguna() {
    return const KelolaPenggunaPage();
  }

  Widget _buildKelolaPerusahaan() {
    return const KelolaPerusahaanPage();
  }

  Widget _buildMonitoringBus() {
    return const MonitoringBusMapPage();
  }

  // Fungsi Laporan yang telah dihubungkan ke LaporanDashboardPage
  Widget _buildLaporan() {
    return const LaporanDashboardPage();
  }

  Widget _buildPengaturanAkun() {
    return const PengaturanAkunPage();
  }
}
