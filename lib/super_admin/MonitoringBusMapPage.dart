import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class MonitoringBusMapPage extends StatefulWidget {
  const MonitoringBusMapPage({super.key});

  @override
  State<MonitoringBusMapPage> createState() => _MonitoringBusMapPageState();
}

class _MonitoringBusMapPageState extends State<MonitoringBusMapPage> {
  // ⚠️ Bagian baseUrl lama dihapus karena kita sekarang pakai ApiService.baseUrl secara konsisten

  List<Map<String, dynamic>> _busData = [];
  List<Marker> _busMarkers = [];
  List<Polyline> _busRoutes = [];
  List<String> _companies = [];
  String? _selectedCompany;

  bool _isLoading = true;
  String? _error;
  Timer? _timer;

  final PopupController _popupController = PopupController();

  @override
  void initState() {
    super.initState();
    _fetchBuses();
    // Refresh otomatis setiap 5 detik
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchBuses());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchBuses() async {
    try {
      // Menggunakan ApiService.baseUrl agar otomatis mengarah ke Railway
      final url = Uri.parse("https://ebusapp-production.up.railway.app/api/buses");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        
        // Menangani jika data dibungkus dalam field 'data' atau tidak
        final List buses = decoded is List ? decoded : (decoded['data'] ?? []);

        final List<Map<String, dynamic>> busList =
            List<Map<String, dynamic>>.from(buses);

        final companies = busList
            .map((b) => b['company_name'] ?? 'Unknown')
            .where((name) => name != 'Unknown')
            .toSet()
            .toList();

        if (mounted) {
          setState(() {
            _busData = busList;
            _companies = companies.cast<String>();
            _isLoading = false;
            _error = null; // Reset error jika berhasil
          });
          _applyFilter();
        }
      } else {
        if (mounted) {
          setState(() {
            _error = "Server Error: ${response.statusCode}";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Koneksi Gagal. Pastikan Backend aktif.";
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilter() {
    List<Map<String, dynamic>> filtered = _busData;

    if (_selectedCompany != null && _selectedCompany != "Semua") {
      filtered = _busData
          .where((bus) => bus['company_name'] == _selectedCompany)
          .toList();
    }

    List<Marker> markers = [];
    List<Polyline> polylines = [];

    for (var bus in filtered) {
      // Pastikan latitude dan longitude ada dan bukan nol
      if (bus['latitude'] != null && bus['longitude'] != null) {
        double lat = double.tryParse(bus['latitude'].toString()) ?? 0.0;
        double lng = double.tryParse(bus['longitude'].toString()) ?? 0.0;

        if (lat != 0.0 && lng != 0.0) {
          markers.add(
            Marker(
              point: LatLng(lat, lng),
              width: 40,
              height: 40,
              child: const Icon(
                Icons.directions_bus,
                color: Colors.blue,
                size: 32,
              ),
            ),
          );
        }

        if (bus['route'] != null && bus['route'] is List) {
          final List<LatLng> routePoints = (bus['route'] as List)
              .map((p) => LatLng(
                    double.tryParse(p['lat'].toString()) ?? 0.0,
                    double.tryParse(p['lng'].toString()) ?? 0.0,
                  ))
              .toList();

          polylines.add(
            Polyline(points: routePoints, strokeWidth: 4, color: Colors.red),
          );
        }
      }
    }

    if (mounted) {
      setState(() {
        _busMarkers = markers;
        _busRoutes = polylines;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _busData.isEmpty) return const Center(child: CircularProgressIndicator());
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Monitoring Armada"),
        actions: [
          if (_companies.isNotEmpty)
            DropdownButton<String>(
              value: _selectedCompany ?? "Semua",
              underline: const SizedBox(),
              items: [
                const DropdownMenuItem(value: "Semua", child: Text("Semua Perusahaan")),
                ..._companies.map((c) => DropdownMenuItem(value: c, child: Text(c))),
              ],
              onChanged: (val) {
                setState(() => _selectedCompany = val);
                _applyFilter();
              },
            ),
          const SizedBox(width: 15),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(-2.5489, 118.0149), // Center ke Indonesia
              initialZoom: 5,
              onTap: (_, __) => _popupController.hideAllPopups(),
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
              ),
              PolylineLayer(polylines: _busRoutes),
              PopupMarkerLayerWidget(
                options: PopupMarkerLayerOptions(
                  popupController: _popupController,
                  markers: _busMarkers,
                  popupDisplayOptions: PopupDisplayOptions(
                    builder: (BuildContext context, Marker marker) {
                      // Mencari data bus berdasarkan koordinat marker
                      final bus = _busData.firstWhere(
                        (b) => (double.tryParse(b['latitude'].toString()) == marker.point.latitude),
                        orElse: () => {},
                      );

                      if (bus.isEmpty) return const SizedBox.shrink();

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "🚍 ${bus['plate_number'] ?? 'Tanpa Nomor'}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const Divider(),
                              Text("Perusahaan: ${bus['company_name'] ?? '-'}"),
                              Text("Status: ${bus['status'] ?? '-'}"),
                              Text("Wilayah: ${bus['city'] ?? '-'}, ${bus['province'] ?? '-'}"),
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
          if (_error != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(10),
                color: Colors.red.withOpacity(0.8),
                child: Text(_error!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
              ),
            ),
        ],
      ),
    );
  }
}