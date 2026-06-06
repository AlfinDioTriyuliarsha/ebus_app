import 'package:ebus_app/screens/admin_perusahaan/LaporanOperasionalPage.dart';
import 'package:ebus_app/screens/admin_perusahaan/ManajemenAgentPage.dart';
import 'package:ebus_app/screens/admin_perusahaan/ManajemenArmadaPage.dart';
import 'package:ebus_app/screens/admin_perusahaan/ManajemenDriverPage.dart';
import 'package:ebus_app/screens/admin_perusahaan/ManajemenRutePage.dart';
import 'package:ebus_app/screens/admin_perusahaan/MonitoringBusMapAdmin.dart';
import 'package:ebus_app/super_admin/PengaturanAkunPage.dart';
import 'package:ebus_app/screens/admin_perusahaan/ManajemenJadwalPage.dart';
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
    "Agent Management",
    "Fleet Management",
    "Route Management",
    "Schedules",
    "Drivers",
    "Bus Monitoring",
    "Reports",
    "Account Settings",
  ];

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return ManajemenAgentPage(companyId: widget.companyId);
      case 1:
        return ManajemenArmadaPage(companyId: widget.companyId);
      case 2:
        return ManajemenRutePage(companyId: widget.companyId);
      case 3:
        return ManajemenJadwalPage(companyId: widget.companyId);
      case 4:
        return ManajemenDriverPage(companyId: widget.companyId);
      case 5:
        return MonitoringBusMapAdmin(
          companyId: widget.companyId,
          busId: 0,
          userId: widget.userId,
        );
      case 6:
        return const LaporanOperasionalPage();
      case 7:
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
      backgroundColor: const Color(
        0xFFF4F6F9,
      ), // Latar belakang canvas abu-abu terang bawaan web
      body: Row(
        children: [
          // ==================== SIDEBAR UTAMA ====================
          Container(
            width: 260,
            color: const Color(
              0xFF3F4D67,
            ), // Warna Sidebar sesuai Gambar (Slate Blue-Grey)
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo & Sub-header Aplikasi
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.directions_bus,
                        color: Colors.blueAccent,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "E-Bus",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            "MISSION CONTROL",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Daftar Menu Navigasi Sidebar
                _buildSidebarItem(
                  0,
                  Icons.supervised_user_circle_outlined,
                  "Agent Management",
                ),
                _buildSidebarItem(
                  1,
                  Icons.directions_bus_outlined,
                  "Fleet Management",
                ),
                _buildSidebarItem(
                  2,
                  Icons.alt_route_outlined,
                  "Route Management",
                ),
                _buildSidebarItem(
                  3,
                  Icons.calendar_today_outlined,
                  "Schedules",
                ),
                _buildSidebarItem(4, Icons.badge_outlined, "Drivers"),
                _buildSidebarItem(
                  5,
                  Icons.analytics_outlined,
                  "Bus Monitoring",
                ),
                _buildSidebarItem(6, Icons.assessment_outlined, "Reports"),

                const Spacer(),

                // Menu Pengaturan di Bagian Bawah
                _buildSidebarItem(
                  7,
                  Icons.settings_outlined,
                  "Account Settings",
                ),
                _buildSidebarItem(
                  -1,
                  Icons.logout_rounded,
                  "Keluar",
                  color: Colors.redAccent.withOpacity(0.9),
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),

          // ==================== MAIN CONTENT AREA ====================
          Expanded(
            child: Container(
              color:
                  Colors.white, // Background konten utama berwarna putih bersih
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. TOP BAR / HEADER (Pencarian & Profil)
                  Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Search Bar (Kolom Pencarian)
                        Container(
                          width: 350,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F6F8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "Search agents or locations...",
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.grey.shade400,
                                size: 20,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),

                        // Sisi Kanan: Notifikasi, Bantuan, & Informasi Akun
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.notifications_none_outlined,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.help_outline_rounded,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: () {},
                            ),
                            const SizedBox(width: 15),
                            // Info Ringkas Akun
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  "Dispatcher HQ",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  "Operation Lead",
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            // Avatar Lingkaran Profil
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.grey.shade300,
                              backgroundImage: const NetworkImage(
                                'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=100', // Placeholder foto profil
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 2. KANVAS ISI HALAMAN UTAMA (Dinamis sesuai Menu)
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      color: const Color(
                        0xFFF8FAFC,
                      ), // Warna abu-abu pudar di belakang kartu stats/tabel
                      child:
                          _getSelectedPage(), // Inject halaman asli Anda di sini secara aman
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

  // Widget Builder Item Navigasi dengan Efek Desain Custom
  Widget _buildSidebarItem(
    int index,
    IconData icon,
    String title, {
    Color color = const Color(
      0xFF9AAEC4,
    ), // Warna default font pasif (tidak aktif)
  }) {
    bool isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          // Efek border putus-putus halus/aktif saat item dipilih layaknya gambar
          border: isSelected
              ? Border.all(
                  color: Colors.blueAccent.withOpacity(0.5),
                  style: BorderStyle.solid,
                  width: 1.5,
                )
              : null,
          color: isSelected
              ? Colors.white.withOpacity(0.06)
              : Colors.transparent,
        ),
        child: ListTile(
          dense: true,
          horizontalTitleGap: 10,
          leading: Icon(
            icon,
            color: isSelected
                ? const Color(0xFF3B82F6)
                : (index == -1 ? color : const Color(0xFF9AAEC4)),
            size: 20,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (index == -1 ? color : const Color(0xFFBACBDC)),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 13,
            ),
          ),
          onTap: () {
            if (index == -1) {
              Navigator.pop(context);
            } else {
              _onItemTapped(index);
            }
          },
        ),
      ),
    );
  }
}
