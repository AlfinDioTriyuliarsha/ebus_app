import 'dart:async';
import 'dart:convert';
import 'package:ebus_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class MonitoringBusMapPage extends StatefulWidget {
  final int companyId;
  const MonitoringBusMapPage({super.key, required this.companyId});

  @override
  State<MonitoringBusMapPage> createState() => _MonitoringBusMapPageState();
}

class _MonitoringBusMapPageState extends State<MonitoringBusMapPage> {
  List<Map<String, dynamic>> _busData = [];
  List<Marker> _busMarkers = [];
  List<Polyline> _busRoutes = [];

  // FIXED: List companies sekarang menampung data lengkap dari tabel companies
  List<Map<String, dynamic>> _companyList = [];
  String? _selectedCompanyName;

  bool _isLoading = true;
  String? _error;
  Timer? _timer;

  final PopupController _popupController = PopupController();

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    // Refresh otomatis data bus setiap 5 detik
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchBuses());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Melakukan fetch perusahaan satu kali di awal, lalu fetch bus
  Future<void> _fetchInitialData() async {
    await _fetchCompanies();
    await _fetchBuses();
  }

  // FIXED: Fungsi untuk mengambil data perusahaan langsung dari tabel companies
  Future<void> _fetchCompanies() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/api/company"),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List rawData = (decoded is Map && decoded.containsKey('data'))
            ? decoded['data']
            : (decoded is List ? decoded : []);

        if (mounted) {
          setState(() {
            _companyList = List<Map<String, dynamic>>.from(rawData);
          });
        }
      }
    } catch (e) {
      debugPrint("Gagal mengambil daftar perusahaan: $e");
    }
  }

  Future<void> _fetchBuses() async {
    try {
      final url = Uri.parse("${ApiService.baseUrl}/api/buses");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List buses = decoded is List ? decoded : (decoded['data'] ?? []);

        if (mounted) {
          setState(() {
            _busData = List<Map<String, dynamic>>.from(buses);
            _isLoading = false;
            _error = null;
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

    // Filter berdasarkan nama perusahaan yang dipilih di dropdown
    if (_selectedCompanyName != null && _selectedCompanyName != "Semua") {
      filtered = _busData
          .where((bus) => bus['company_name'] == _selectedCompanyName)
          .toList();
    }

    List<Marker> markers = [];
    List<Polyline> polylines = [];

    for (var bus in filtered) {
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
              .map(
                (p) => LatLng(
                  double.tryParse(p['lat'].toString()) ?? 0.0,
                  double.tryParse(p['lng'].toString()) ?? 0.0,
                ),
              )
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
    if (_isLoading && _busData.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Monitoring Armada"),
        backgroundColor: Colors.orange,
        actions: [
          // Dropdown sekarang mengambil data dari _companyList yang akurat
          DropdownButton<String>(
            value: _selectedCompanyName ?? "Semua",
            underline: const SizedBox(),
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            items: [
              const DropdownMenuItem(
                value: "Semua",
                child: Text("Semua Perusahaan"),
              ),
              ..._companyList.map(
                (c) => DropdownMenuItem(
                  value: c['company_name'].toString(),
                  child: Text(c['company_name'].toString()),
                ),
              ),
            ],
            onChanged: (val) {
              setState(() => _selectedCompanyName = val);
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
              initialCenter: const LatLng(-2.5489, 118.0149),
              initialZoom: 5,
              onTap: (_, __) => _popupController.hideAllPopups(),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
              ),
              PolylineLayer(polylines: _busRoutes),
              PopupMarkerLayerWidget(
                options: PopupMarkerLayerOptions(
                  popupController: _popupController,
                  markers: _busMarkers,
                  popupDisplayOptions: PopupDisplayOptions(
                    builder: (BuildContext context, Marker marker) {
                      final bus = _busData.firstWhere(
                        (b) =>
                            (double.tryParse(b['latitude'].toString()) ==
                            marker.point.latitude),
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
                                "🚍 ${bus['plat_nomor'] ?? 'Tanpa Nomor'}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const Divider(),
                              Text("Perusahaan: ${bus['company_name'] ?? '-'}"),
                              Text("Status: ${bus['status'] ?? '-'}"),
                              Text(
                                "Wilayah: ${bus['city'] ?? '-'}, ${bus['province'] ?? '-'}",
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
          if (_error != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(10),
                color: Colors.red.withOpacity(0.8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
