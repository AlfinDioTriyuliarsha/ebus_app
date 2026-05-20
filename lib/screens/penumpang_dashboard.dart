import 'dart:async';
import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:ebus_app/services/api_service.dart';
import 'package:ebus_app/screens/penumpang/TrackingBusPenumpang.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PenumpangDashboard extends StatefulWidget {
  final String email;

  const PenumpangDashboard({super.key, required this.email});

  @override
  State<PenumpangDashboard> createState() => _PenumpangDashboardState();
}

class _PenumpangDashboardState extends State<PenumpangDashboard> {
  // ================= BUS =================
  List<dynamic> buses = [];

  bool isLoadingBus = true;

  // ================= PERJALANAN =================
  List<Map<String, dynamic>> perjalananData = [];

  // ================= SAVE PERJALANAN =================
  Future<void> savePerjalanan() async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(perjalananData);

    await prefs.setString('perjalanan_data', encoded);
  }

  // ================= LOAD PERJALANAN =================
  Future<void> loadPerjalanan() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getString('perjalanan_data');

    if (data != null) {
      final decoded = jsonDecode(data);

      setState(() {
        perjalananData = List<Map<String, dynamic>>.from(decoded);
      });
    }
  }

  // ================= UI =================
  int currentIndex = 0;

  final PageController _pageController = PageController();

  int currentBanner = 0;

  Timer? bannerTimer;

  final List<String> banners = [
    "assets/banner1.jpg",
    "assets/banner2.jpg",
    "assets/banner3.jpg",
  ];

  @override
  void initState() {
    super.initState();

    startBannerAutoSlide();

    fetchBuses();

    loadPerjalanan();
  }

  // ================= AUTO SLIDE =================
  void startBannerAutoSlide() {
    bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_pageController.hasClients) return;

      currentBanner++;

      if (currentBanner >= banners.length) {
        currentBanner = 0;
      }

      _pageController.animateToPage(
        currentBanner,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  // ================= FETCH BUS =================
  Future<void> fetchBuses() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/api/buses"),
      );

      final data = jsonDecode(response.body);

      if (data['success']) {
        setState(() {
          buses = data['data'];

          isLoadingBus = false;
        });
      }
    } catch (e) {
      print("ERROR FETCH BUS: $e");

      setState(() {
        isLoadingBus = false;
      });
    }
  }

  @override
  void dispose() {
    bannerTimer?.cancel();

    _pageController.dispose();

    super.dispose();
  }

  // ================= HOME PAGE =================
  Widget homePage() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // ================= HEADER =================
          Container(
            width: double.infinity,

            padding: const EdgeInsets.only(
              top: 50,
              left: 20,
              right: 20,
              bottom: 25,
            ),

            decoration: const BoxDecoration(
              color: Color(0xFF001F3F),

              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  "Selamat Datang 👋",
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),

                const SizedBox(height: 5),

                Text(
                  widget.email,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // ================= SALDO =================
                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.all(18),

                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF005BEA), Color(0xFF00C6FB)],
                    ),

                    borderRadius: BorderRadius.circular(20),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text(
                        "Saldo",
                        style: TextStyle(color: Colors.white70),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        "Rp 150.000",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ================= BANNER =================
          SizedBox(
            height: 170,

            child: PageView.builder(
              controller: _pageController,

              itemCount: banners.length,

              onPageChanged: (index) {
                setState(() {
                  currentBanner = index;
                });
              },

              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15),

                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),

                    image: DecorationImage(
                      image: AssetImage(banners[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // ================= INDICATOR =================
          Row(
            mainAxisAlignment: MainAxisAlignment.center,

            children: List.generate(
              banners.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),

                width: currentBanner == index ? 20 : 8,

                height: 8,

                decoration: BoxDecoration(
                  color: currentBanner == index
                      ? Colors.blue
                      : Colors.grey.shade400,

                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ================= ARMADA =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  "Armada Tersedia",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 15),

                if (isLoadingBus)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (buses.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text("Belum ada armada tersedia"),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,

                    physics: const NeverScrollableScrollPhysics(),

                    itemCount: buses.length,

                    itemBuilder: (context, index) {
                      final bus = buses[index];

                      return tiketBusCard(bus);
                    },
                  ),
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ================= PERJALANAN =================
  Widget perjalananPage() {
    if (perjalananData.isEmpty) {
      return const Center(
        child: Text(
          "Belum ada perjalanan",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),

      itemCount: perjalananData.length,

      itemBuilder: (context, index) {
        final item = perjalananData[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 15),

          padding: const EdgeInsets.all(18),

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.circular(20),

            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 6),
            ],
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),

                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),

                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: const Icon(
                      Icons.directions_bus,
                      color: Color(0xFF001F3F),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          item['nomor_bus'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          "Bus ${item['plat_nomor']}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),

                      borderRadius: BorderRadius.circular(10),
                    ),

                    child: Text(
                      item['status'],
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: const [
                      Text(
                        "Keberangkatan",
                        style: TextStyle(color: Colors.grey),
                      ),

                      SizedBox(height: 5),

                      Text(
                        "07:00 WIB",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,

                    children: const [
                      Text(
                        "Estimasi Tiba",
                        style: TextStyle(color: Colors.grey),
                      ),

                      SizedBox(height: 5),

                      Text(
                        "10:30 WIB",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,

                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TrackingBusPenumpang(busId: item['bus_id']),
                      ),
                    );
                  },

                  icon: const Icon(Icons.location_on, color: Colors.white),

                  label: const Text(
                    "Tracking Bus",
                    style: TextStyle(color: Colors.white),
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF001F3F),

                    padding: const EdgeInsets.symmetric(vertical: 14),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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

  // ================= HISTORY =================
  Widget historyPage() {
    return const Center(
      child: Text(
        "History Tiket",
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ================= PENGATURAN =================
  Widget pengaturanPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            const SizedBox(height: 40),

            CircleAvatar(
              radius: 45,
              backgroundColor: Colors.blue.shade100,

              child: const Icon(
                Icons.person,
                size: 50,
                color: Color(0xFF001F3F),
              ),
            ),

            const SizedBox(height: 15),

            Text(
              widget.email,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            pengaturanItem(Icons.person, "Profil Pengguna"),

            pengaturanItem(Icons.logout, "Logout"),
          ],
        ),
      ),
    );
  }

  // ================= ITEM PENGATURAN =================
  Widget pengaturanItem(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5),
        ],
      ),

      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF001F3F)),

          const SizedBox(width: 15),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }

  // ================= CARD ARMADA =================
  Widget tiketBusCard(Map<String, dynamic> bus) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),

      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5),
        ],
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  bus['nomor_bus'] ?? '-',

                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  "Plat Nomor : ${bus['plat_nomor']}",
                  style: TextStyle(color: Colors.grey.shade700),
                ),

                const SizedBox(height: 5),

                Text(
                  "Status : ${bus['status']}",
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          ElevatedButton(
            onPressed: () {
              final alreadyExist = perjalananData.any(
                (e) => e['bus_id'] == bus['id'],
              );

              if (alreadyExist) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Tiket sudah ada diperjalanan")),
                );

                return;
              }

              setState(() {
                perjalananData.add({
                  "bus_id": bus['id'],
                  "nomor_bus": bus['nomor_bus'],
                  "plat_nomor": bus['plat_nomor'],
                  "status": "Sedang Berjalan",
                });
              });

              savePerjalanan();

              AwesomeDialog(
                context: context,
                dialogType: DialogType.success,
                animType: AnimType.scale,
                title: "Berhasil",
                desc: "Tiket berhasil dipesan",
                btnOkText: "OK",
                btnOkColor: const Color(0xFF001F3F),
                btnOkOnPress: () {},
              ).show();
            },

            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF001F3F),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),

            child: const Text("Pesan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      homePage(),
      perjalananPage(),
      historyPage(),
      pengaturanPage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      body: pages[currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,

        selectedItemColor: const Color(0xFF001F3F),

        unselectedItemColor: Colors.grey,

        type: BottomNavigationBarType.fixed,

        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),

          BottomNavigationBarItem(icon: Icon(Icons.route), label: "Perjalanan"),

          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),

          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Pengaturan",
          ),
        ],
      ),
    );
  }
}
