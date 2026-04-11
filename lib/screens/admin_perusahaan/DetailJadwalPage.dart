import 'dart:convert';
import 'package:ebus_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DetailJadwalPage extends StatefulWidget {
  final int scheduleId;
  final String platNomor;

  const DetailJadwalPage({
    super.key,
    required this.scheduleId,
    required this.platNomor,
  });

  @override
  State<DetailJadwalPage> createState() => _DetailJadwalPageState();
}

class _DetailJadwalPageState extends State<DetailJadwalPage> {
  List<Map<String, dynamic>> _seats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSeats();
  }

  Future<void> _fetchSeats() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/api/bus-seats?schedule_id=${widget.scheduleId}"),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          _seats = List<Map<String, dynamic>>.from(decoded['data'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text("Denah Kursi ${widget.platNomor}"),
        backgroundColor: Colors.orange,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeaderInfo(),
                const SizedBox(height: 10),
                _buildLegend(),
                const SizedBox(height: 10),
                // Area Sopir
                _buildFrontArea(),
                // Grid Kursi
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                    ),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4, // 1A, 1B, 1C, 1D
                        mainAxisSpacing: 15,
                        crossAxisSpacing: 15,
                      ),
                      itemCount: _seats.length,
                      itemBuilder: (context, index) {
                        final seat = _seats[index];
                        bool isAvailable = seat['is_available'] == true || seat['is_available'] == 1;
                        String seatCode = seat['nomor_kursi'] ?? "";

                        return InkWell(
                          onTap: isAvailable ? () => _processBooking(seat) : () => _showPassengerInfo(seat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              color: isAvailable ? Colors.green[50] : Colors.red[50],
                              border: Border.all(
                                color: isAvailable ? Colors.green : Colors.red,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chair,
                                  color: isAvailable ? Colors.green : Colors.red,
                                  size: 24,
                                ),
                                Text(
                                  seatCode,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: isAvailable ? Colors.green[800] : Colors.red[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      padding: const EdgeInsets.all(15),
      color: Colors.white,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.grey),
          SizedBox(width: 8),
          Text("Klik kursi hijau untuk memesan, merah untuk detail."),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(Colors.green, "Kosong"),
        const SizedBox(width: 30),
        _legendItem(Colors.red, "Terisi"),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildFrontArea() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.settings, color: Colors.grey), // Setir
          Text("DEPAN / SOPIR", style: TextStyle(letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold)),
          SizedBox(width: 24),
        ],
      ),
    );
  }

  void _showPassengerInfo(Map<String, dynamic> seat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Detail Kursi ${seat['nomor_kursi']}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Status: TERISI", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Nama Penumpang: ${seat['nama_penumpang'] ?? 'N/A'}"),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tutup"))],
      ),
    );
  }

  void _processBooking(Map<String, dynamic> seat) {
    // Navigasi ke form pengisian nama penumpang
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Memproses booking kursi ${seat['nomor_kursi']}...")),
    );
  }
}