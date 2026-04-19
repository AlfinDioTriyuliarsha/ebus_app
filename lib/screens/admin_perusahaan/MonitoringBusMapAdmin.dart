import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:ebus_app/services/api_service.dart';

class MonitoringBusMapAdmin extends StatefulWidget {
  final int companyId;

  const MonitoringBusMapAdmin({super.key, required this.companyId});

  @override
  State<MonitoringBusMapAdmin> createState() => _MonitoringBusMapAdminState();
}

class _MonitoringBusMapAdminState extends State<MonitoringBusMapAdmin> {
  List<Map<String, dynamic>> _busData = [];
  List<Marker> _busMarkers = [];
  List<Polyline> _busRoutes = [];

  final Map<Marker, Map<String, dynamic>> _markerBusMap = {};

  bool _isLoading = true;
  String? _error;
  Timer? _timer;

  final PopupController _popupController = PopupController();
  final MapController _mapController = MapController();

  int? selectedBusId;

  @override
  void initState() {
    super.initState();
    _fetchBusesByCompany();

    _timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _fetchBusesByCompany(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchBusesByCompany() async {
    try {
      final url = Uri.parse(
        "${ApiService.baseUrl}/api/buses?company_id=${widget.companyId}",
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List buses = decoded['data'] ?? [];

        if (mounted) {
          setState(() {
            _busData = List<Map<String, dynamic>>.from(buses);
            _isLoading = false;
            _error = null;
          });

          _generateMarkersAndRoutes();
        }
      } else {
        setState(() {
          _error = "Server Error: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Koneksi Gagal ke API";
        _isLoading = false;
      });
    }
  }

  void _generateMarkersAndRoutes() {
    List<Marker> markers = [];
    List<Polyline> polylines = [];
    _markerBusMap.clear();

    for (var bus in _busData) {
      // FILTER: hanya tampilkan bus yang dipilih
      if (selectedBusId != null && bus['id'] != selectedBusId) continue;

      double lat = double.tryParse(bus['latitude']?.toString() ?? "0") ?? 0.0;
      double lng = double.tryParse(bus['longitude']?.toString() ?? "0") ?? 0.0;

      if (lat == 0.0 || lng == 0.0) continue;

      final marker = Marker(
        point: LatLng(lat, lng),
        width: 50,
        height: 50,
        child: Column(
          children: [
            const Icon(Icons.directions_bus, color: Colors.green, size: 35),
            Text(bus['plat_nomor'] ?? '', style: const TextStyle(fontSize: 10)),
          ],
        ),
      );

      markers.add(marker);
      _markerBusMap[marker] = bus;

      // ✅ DRAW ROUTE (Polyline)
      if (bus['route'] != null && bus['route'] is List) {
        List<LatLng> routePoints = [];

        for (var point in bus['route']) {
          double rLat = double.tryParse(point['lat'].toString()) ?? 0.0;
          double rLng = double.tryParse(point['lng'].toString()) ?? 0.0;

          routePoints.add(LatLng(rLat, rLng));
        }

        if (routePoints.isNotEmpty) {
          polylines.add(
            Polyline(points: routePoints, strokeWidth: 4, color: Colors.blue),
          );
        }
      }

      // ✅ AUTO FOCUS KE BUS YANG DIPILIH
      if (selectedBusId != null) {
        _mapController.move(LatLng(lat, lng), 15);
      }
    }

    setState(() {
      _busMarkers = markers;
      _busRoutes = polylines;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _busData.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Monitoring Armada Kami"),
        backgroundColor: const Color(0xFF001F3F),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(-7.9839, 112.6214),
              initialZoom: 6,
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
                    builder: (context, marker) {
                      final bus = _markerBusMap[marker];
                      if (bus == null) return const SizedBox();

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "🚍 ${bus['plat_nomor']}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const Divider(),
                              Text("Driver: ${bus['driver_name'] ?? '-'}"),
                              Text("Status: ${bus['status'] ?? '-'}"),
                              Text("Rute: ${bus['nama_rute'] ?? '-'}"),
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

          // ✅ DROPDOWN PILIH BUS
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(blurRadius: 5, color: Colors.black26),
                ],
              ),
              child: DropdownButton<int>(
                value: selectedBusId,
                hint: const Text("Pilih Bus"),
                underline: const SizedBox(),
                items: _busData.map((bus) {
                  return DropdownMenuItem<int>(
                    value: bus['id'],
                    child: Text(bus['plat_nomor'] ?? ''),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedBusId = value;
                  });
                  _generateMarkersAndRoutes();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
