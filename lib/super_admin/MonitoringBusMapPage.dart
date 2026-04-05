import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:ebus_app/services/api_service.dart'; // Sesuaikan dengan nama project Anda

class MonitoringBusMapPage extends StatefulWidget {
  const MonitoringBusMapPage({super.key});

  @override
  State<MonitoringBusMapPage> createState() => _MonitoringBusMapPageState();
}

class _MonitoringBusMapPageState extends State<MonitoringBusMapPage> {
  // 🔥 Gunakan environment variable supaya fleksibel
  // flutter run --dart-define=API_URL=http://192.168.1.10:3000/api/buses
  static const String baseUrl = String.fromEnvironment(
    "API_URL",
    defaultValue: "http://localhost:3000/api/buses",
  );

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
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchBuses());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchBuses() async {
    try {
      final url = Uri.parse("${ApiService.baseUrl}/api/buses");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List buses = decoded['data'];

        final List<Map<String, dynamic>> busList =
            List<Map<String, dynamic>>.from(buses);

        final companies = busList
            .map((b) => b['company_name'] ?? 'Unknown')
            .toSet()
            .toList();

        if (mounted) {
          setState(() {
            _busData = busList;
            _companies = companies.cast<String>();
            _isLoading = false;
          });
          _applyFilter();
        }
      } else {
        setState(() {
          _error = "Gagal ambil data bus (${response.statusCode})";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Error: $e";
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
      if (bus['latitude'] != null && bus['longitude'] != null) {
        markers.add(
          Marker(
            point: LatLng(
              (bus['latitude'] as num).toDouble(),
              (bus['longitude'] as num).toDouble(),
            ),
            width: 40,
            height: 40,
            child: const Icon(
              Icons.directions_bus,
              color: Colors.blue,
              size: 32,
            ),
          ),
        );

        // Polyline contoh (jika ada field route di API)
        if (bus['route'] != null && bus['route'] is List) {
          final List<LatLng> routePoints = (bus['route'] as List)
              .map(
                (p) => LatLng(
                  (p['lat'] as num).toDouble(),
                  (p['lng'] as num).toDouble(),
                ),
              )
              .toList();

          polylines.add(
            Polyline(points: routePoints, strokeWidth: 4, color: Colors.red),
          );
        }
      }
    }

    setState(() {
      _busMarkers = markers;
      _busRoutes = polylines;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (_companies.isNotEmpty)
            DropdownButton<String>(
              value: _selectedCompany ?? "Semua",
              underline: const SizedBox(),
              items: [
                "Semua",
                ..._companies,
              ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) {
                setState(() => _selectedCompany = val);
                _applyFilter();
              },
            ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: const LatLng(-6.200000, 106.816666),
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
                  final index = _busMarkers.indexOf(marker);
                  final bus =
                      (_selectedCompany == null || _selectedCompany == "Semua")
                      ? _busData[index]
                      : _busData
                            .where((b) => b['company_name'] == _selectedCompany)
                            .toList()[index];

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "🚍 ${bus['plate_number'] ?? 'Tanpa Nomor'}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text("Perusahaan: ${bus['company_name'] ?? '-'}"),
                          Text("Status: ${bus['status'] ?? '-'}"),
                          Text(
                            "Lokasi: ${bus['latitude']}, ${bus['longitude']}",
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
}
