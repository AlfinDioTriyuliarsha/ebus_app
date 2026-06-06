import 'package:ebus_app/super_admin/KelolaPerusahaanPage.dart';
import 'package:ebus_app/super_admin/KelolaPenggunaPage.dart';
import 'package:ebus_app/super_admin/LaporanDashboardPage.dart';
import 'package:ebus_app/super_admin/MonitoringBusMapPage.dart';
import 'package:ebus_app/super_admin/PengaturanAkunPage.dart';
import 'package:flutter/material.dart';

class SuperAdminDashboard extends StatefulWidget {
  final String email;
  final int userId;

  const SuperAdminDashboard({
    super.key,
    required this.email,
    required this.userId,
  });

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
          // Menggunakan background soft pastel ultra-modern
          backgroundColor: const Color(0xFFF3F5F9),

          // Drawer untuk Mobile otomatis menyesuaikan tema baru
          drawer: isMobile
              ? Drawer(child: _buildSidebar(isMobile: true))
              : null,

          body: Row(
            children: [
              // Tampilkan sidebar melayang hanya jika bukan di HP
              if (!isMobile)
                SizedBox(
                  width: isTablet ? 230 : 270,
                  child: _buildSidebar(isMobile: false),
                ),

              // AREA KONTEN UTAMA
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 10 : 0,
                    isMobile ? 10 : 20,
                    isMobile ? 10 : 20,
                    isMobile ? 10 : 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isMobile),
                      const SizedBox(height: 10),

                      // Tempat Halaman Utama Dirender
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          color: Colors
                              .transparent, // Menghapus kotak abu-abu tebal Bootstrap lama
                          child: _buildPage(_selectedIndex),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // SIDEBAR MODERN DENGAN GRADASI DAN FLOATING STYLE
  Widget _buildSidebar({required bool isMobile}) {
    return Container(
      margin: isMobile ? EdgeInsets.zero : const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E293B), // Dark Slate Modern
            Color(0xFF0F172A),
          ],
        ),
        borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(24),
        boxShadow: isMobile
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF0F172A).withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Brand di Sidebar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFEF4444),
                        Color(0xFFB91C1C),
                      ], // Warna Merah Khusus Super Admin
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "E-Bus",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      "SUPER ADMIN",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              "SYSTEM CONTROL",
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),

          // Menu Items
          _sidebarItem(0, "Kontrol Hak Akses", Icons.people_alt_rounded),
          _sidebarItem(
            1,
            "Manajemen Perusahaan",
            Icons.business_center_rounded,
          ),
          _sidebarItem(2, "Monitoring Bus", Icons.bento_rounded),
          _sidebarItem(3, "Laporan & Statistik", Icons.analytics_rounded),
          _sidebarItem(4, "Pengaturan Akun", Icons.settings_suggest_rounded),

          const Spacer(),

          const Divider(color: Color(0xFF334155), height: 1),
          const SizedBox(height: 10),

          // Tombol Keluar Bergaya Modern
          InkWell(
            onTap: () => Navigator.pushReplacementNamed(context, "/login"),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.redAccent.withOpacity(0.06),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.power_settings_new_rounded,
                    color: Colors.redAccent.shade200,
                    size: 20,
                  ),
                  const SizedBox(width: 14),
                  Text(
                    "Keluar",
                    style: TextStyle(
                      color: Colors.redAccent.shade200,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // LIST NAVIGASI SIDEBAR BERGAYA ANIMATED GRADIENT
  Widget _sidebarItem(int index, String title, IconData icon) {
    bool isActive = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
          if (Scaffold.of(context).isDrawerOpen) {
            Navigator.pop(context);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isActive
                ? const LinearGradient(
                    colors: [
                      Color(0xFF3B82F6),
                      Color(0xFF2563EB),
                    ], // Efek Gradasi Aktif Biru
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : const Color(0xFF94A3B8),
                size: 20,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isActive ? Colors.white : const Color(0xFFCBD5E1),
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13.5,
                  ),
                ),
              ),
              if (isActive)
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // TOP BAR/HEADER MODERN (MENDUKUNG RESPONSIVE MOBILE)
  Widget _buildHeader(bool isMobile) {
    return Container(
      height: 75,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (isMobile)
                Builder(
                  builder: (context) => Container(
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.menu_rounded,
                        color: Color(0xFF1E293B),
                      ),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                ),
              Text(
                _getHeaderTitle(),
                style: TextStyle(
                  fontSize: isMobile ? 14 : 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          // Bagian Profil Pengguna
          Row(
            children: [
              if (!isMobile)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.email.split('@')[0].toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const Text(
                      "Root Super Admin",
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              const SizedBox(width: 14),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: const Color(0xFF64748B),
                  radius: isMobile ? 16 : 20,
                  child: const Icon(
                    Icons.gavel_rounded,
                    color: Colors.white,
                    size: 18,
                  ), // Ikon Gavel untuk Super Admin
                ),
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

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const KelolaPenggunaPage();
      case 1:
        return const KelolaPerusahaanPage();
      case 2:
        return const MonitoringBusMapPage(companyId: 0);
      case 3:
        return const LaporanDashboardPage();
      case 4:
        return _buildPengaturanAkun();
      default:
        return const Center(child: Text("Halaman tidak ditemukan"));
    }
  }

  Widget _buildPengaturanAkun() {
    return PengaturanAkunPage(userId: widget.userId);
  }
}
