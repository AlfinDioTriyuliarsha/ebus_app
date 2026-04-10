import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
      // 1. Ambil data User
      final users = await ApiService.getUsers();

      // 2. Ambil data Perusahaan (FIX URL: /api/company)
      final resComp = await http.get(
        Uri.parse("${ApiService.baseUrl}/api/company"),
      );

      // 3. Ambil data Bus (FIX URL: /api/buses)
      final resBus = await http.get(
        Uri.parse("${ApiService.baseUrl}/api/buses"),
      );

      if (mounted) {
        setState(() {
          // Set User
          totalUser = users.length;
          totalAkunAktif = users.length;

          // Set Perusahaan
          if (resComp.statusCode == 200) {
            var dataComp = jsonDecode(resComp.body);
            if (dataComp['data'] != null) {
              totalPerusahaan = (dataComp['data'] as List).length;
            }
          }

          // Set Bus
          if (resBus.statusCode == 200) {
            var dataBus = jsonDecode(resBus.body);
            if (dataBus['data'] != null) {
              totalBus = (dataBus['data'] as List).length;
            }
          }

          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error Fetch Stats: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Perhitungan maxY agar grafik tidak menyentuh atap
    double maxVal = [
      totalUser,
      totalPerusahaan,
      totalBus,
      totalAkunAktif,
    ].reduce((curr, next) => curr > next ? curr : next).toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildModernCard(
                "Users",
                "$totalUser",
                Icons.people,
                Colors.blue,
              ),
              const SizedBox(width: 15),
              _buildModernCard(
                "Perusahaan",
                "$totalPerusahaan",
                Icons.business,
                Colors.orange,
              ),
              const SizedBox(width: 15),
              _buildModernCard(
                "Bus",
                "$totalBus",
                Icons.directions_bus,
                Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(20),
            height: 350,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Visualisasi Data Sistem",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                Expanded(child: _buildBarChart(maxVal)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
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
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.black54, fontSize: 11),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(double maxVal) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal + 2,
        barGroups: [
          _makeGroupData(0, totalUser.toDouble(), Colors.blue),
          _makeGroupData(1, totalPerusahaan.toDouble(), Colors.orange),
          _makeGroupData(2, totalBus.toDouble(), Colors.green),
          _makeGroupData(3, totalAkunAktif.toDouble(), Colors.purple),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                const labels = ['User', 'PT', 'Bus', 'Aktif'];
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    labels[val.toInt()],
                    style: const TextStyle(fontSize: 10),
                  ),
                );
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
          width: 20,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }
}
