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
      // Background utama menggunakan warna abu-abu pastel yang sangat lembut & teduh
      backgroundColor: const Color(0xFFF3F5F9),
      body: Row(
        children: [
          // ==================== FLOATING SIDEBAR (KEKINIAN) ====================
          Container(
            width: 270,
            margin: const EdgeInsets.all(
              20,
            ), // Membuat sidebar melayang terpisah dari tepi layar
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E293B), // Dark Slate Modern
                  Color(0xFF0F172A),
                ],
              ),
              borderRadius: BorderRadius.circular(
                24,
              ), // Sudut melengkung halus khas UI modern
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand Header Section
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      // Ikon Logo Gradasi Bulat
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.directions_bus_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "E-Bus",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            "MISSION CONTROL",
                            style: TextStyle(
                              color: Colors.blueAccent.shade100,
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

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    "MAIN MENU",
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),

                // List Menu Navigasi
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildModernSidebarItem(
                        0,
                        Icons.grid_view_rounded,
                        "Agent Management",
                      ),
                      _buildModernSidebarItem(
                        1,
                        Icons.local_shipping_rounded,
                        "Fleet Management",
                      ),
                      _buildModernSidebarItem(
                        2,
                        Icons.alt_route_rounded,
                        "Route Management",
                      ),
                      _buildModernSidebarItem(
                        3,
                        Icons.edit_calendar_rounded,
                        "Schedules",
                      ),
                      _buildModernSidebarItem(
                        4,
                        Icons.assignment_ind_rounded,
                        "Drivers",
                      ),
                      _buildModernSidebarItem(
                        5,
                        Icons.map_rounded,
                        "Bus Monitoring",
                      ),
                      _buildModernSidebarItem(
                        6,
                        Icons.analytics_rounded,
                        "Reports",
                      ),
                    ],
                  ),
                ),

                // Bagian Bawah Sidebar (Settings & Logout)
                const Divider(
                  color: Color(0xFF334155),
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      _buildModernSidebarItem(
                        7,
                        Icons.settings_suggest_rounded,
                        "Account Settings",
                      ),
                      _buildModernSidebarItem(
                        -1,
                        Icons.power_settings_new_rounded,
                        "Keluar",
                        isLogout: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ==================== MAIN CONTENT AREA ====================
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. TOP BAR / HEADER (Clean & Minimalis)
                  Container(
                    height: 75,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Glassmorphic Search Bar
                        Container(
                          width: 380,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF0F172A,
                                ).withOpacity(0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "Quick search everything...",
                              hintStyle: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: Color(0xFF94A3B8),
                                size: 20,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 13,
                              ),
                            ),
                          ),
                        ),

                        // Sisi Kanan: Action Buttons & Profil
                        Row(
                          children: [
                            // Tombol Notifikasi Bergaya Bubble
                            _buildHeaderIconButton(
                              Icons.notifications_none_rounded,
                              hasBadge: true,
                            ),
                            const SizedBox(width: 12),
                            _buildHeaderIconButton(Icons.help_outline_rounded),
                            const SizedBox(width: 20),

                            // Pembatas Vertikal Halus
                            Container(
                              width: 1,
                              height: 30,
                              color: const Color(0xFFCBD5E1),
                            ),
                            const SizedBox(width: 20),

                            // Profil Pengguna Kompak
                            Row(
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      "Dispatcher HQ",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    Text(
                                      "Operation Lead",
                                      style: TextStyle(
                                        color: const Color(0xFF64748B),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 14),
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const CircleAvatar(
                                    radius: 20,
                                    backgroundImage: NetworkImage(
                                      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=100',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 2. MAIN CONTAINER AREA FOR PAGES
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors
                            .transparent, // Dibiarkan transparan agar halaman anak bisa berkreasi penuh
                      ),
                      child: _getSelectedPage(), // Isi konten asli Anda
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

  // Helper Builder untuk Ikon Topbar yang Estetik
  Widget _buildHeaderIconButton(IconData icon, {bool hasBadge = false}) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, color: const Color(0xFF64748B), size: 22),
            onPressed: () {},
          ),
        ),
        if (hasBadge)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  // Helper Builder Menu Sidebar yang Interaktif & Modern
  Widget _buildModernSidebarItem(
    int index,
    IconData icon,
    String title, {
    bool isLogout = false,
  }) {
    bool isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {
          if (index == -1) {
            Navigator.pop(context);
          } else {
            _onItemTapped(index);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            // Jika aktif, berikan gradasi biru mewah, jika tidak, biarkan transparan
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  )
                : null,
            color: !isSelected && isLogout
                ? Colors.redAccent.withOpacity(0.06)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : (isLogout
                          ? Colors.redAccent.shade200
                          : const Color(0xFF94A3B8)),
                size: 20,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isLogout
                              ? Colors.redAccent.shade200
                              : const Color(0xFFCBD5E1)),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13.5,
                  ),
                ),
              ),
              // Indikator Kapsul Aktif di sebelah kanan menu
              if (isSelected)
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
}
