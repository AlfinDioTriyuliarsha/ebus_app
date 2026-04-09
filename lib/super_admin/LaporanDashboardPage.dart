import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Library untuk grafik
import 'package:ebus_app/services/api_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LaporanDashboardPage extends StatefulWidget {
  const LaporanDashboardPage({super.key});

  @override
  State<LaporanDashboardPage> createState() => _LaporanDashboardPageState();
}

class _LaporanDashboardPageState extends State<LaporanDashboardPage> {
  int totalUser = 0;
  int totalPerusahaan = 0;
  int totalBus = 0;
  int totalAkunAktif = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      // Mengambil data User dari ApiService yang sudah ada
      final users = await ApiService.getUsers();

      // FIX URL: Sesuaikan endpoint ke /api/company (tanpa 's') dan /api/bus sesuai rute backend
      final resComp = await http.get(
        Uri.parse("${ApiService.baseUrl}/api/company"),
      );

      final resBus = await http.get(Uri.parse("${ApiService.baseUrl}/api/bus"));

      if (mounted) {
        setState(() {
          totalUser = users.length;
          totalAkunAktif =
              users.length; // Asumsi user yang terdaftar adalah akun aktif

          // Memproses data Perusahaan
          if (resComp.statusCode == 200) {
            var dataComp = jsonDecode(resComp.body);
            // Mengambil panjang list dari dataComp['data']
            if (dataComp['data'] != null) {
              totalPerusahaan = (dataComp['data'] as List).length;
            }
          } else {
            print("Gagal ambil data Perusahaan: ${resComp.statusCode}");
          }

          // Memproses data Bus
          if (resBus.statusCode == 200) {
            var dataBus = jsonDecode(resBus.body);
            if (dataBus['data'] != null) {
              totalBus = (dataBus['data'] as List).length;
            }
          } else {
            print("Gagal ambil data Bus: ${resBus.statusCode}");
          }

          isLoading = false;
        });
      }
    } catch (e) {
      print("Error Fetch Stats: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row Kartu Statistik
          Row(
            children: [
              _buildModernCard(
                "Users",
                totalUser.toString(),
                Icons.people,
                Colors.blue,
              ),
              const SizedBox(width: 15),
              _buildModernCard(
                "Perusahaan",
                totalPerusahaan.toString(),
                Icons.business,
                Colors.orange,
              ),
              const SizedBox(width: 15),
              _buildModernCard(
                "Armada Bus",
                totalBus.toString(),
                Icons.directions_bus,
                Colors.green,
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Bagian Grafik
          Container(
            padding: const EdgeInsets.all(20),
            height: 350,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Visualisasi Data Akses",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                Expanded(child: _buildBarChart()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget Kartu Modern
  Widget _buildModernCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border(left: BorderSide(color: color, width: 5)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Grafik Batang (Bar Chart)
  Widget _buildBarChart() {
    // Mencari nilai tertinggi untuk skala bar
    double maxVal = [
      totalUser,
      totalPerusahaan,
      totalBus,
      totalAkunAktif,
    ].reduce((curr, next) => curr > next ? curr : next).toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal + 5,
        barGroups: [
          _makeGroupData(0, totalUser.toDouble(), Colors.blue),
          _makeGroupData(1, totalPerusahaan.toDouble(), Colors.orange),
          _makeGroupData(2, totalBus.toDouble(), Colors.green),
          _makeGroupData(3, totalAkunAktif.toDouble(), Colors.purple),
        ],
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 0:
                    return const Text('User', style: TextStyle(fontSize: 10));
                  case 1:
                    return const Text('PT', style: TextStyle(fontSize: 10));
                  case 2:
                    return const Text('Bus', style: TextStyle(fontSize: 10));
                  case 3:
                    return const Text('Aktif', style: TextStyle(fontSize: 10));
                  default:
                    return const Text('');
                }
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 25,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }
}
