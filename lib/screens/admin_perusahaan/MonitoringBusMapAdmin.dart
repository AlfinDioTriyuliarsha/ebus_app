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

  int? selectedBusId; // null = semua bus
  double distance = 0;
  double duration = 0;

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

  Future<Map<String, dynamic>> getRouteDetail(LatLng start, LatLng end) async {
    final url = Uri.parse(
      "${ApiService.baseUrl}/api/routes/direction"
      "?start_lat=${start.latitude}"
      "&start_lng=${start.longitude}"
      "&end_lat=${end.latitude}"
      "&end_lng=${end.longitude}",
    );

    final res = await http.get(url);
    final data = jsonDecode(res.body);

    if (data['success'] == true) {
      final List points = data['data'];

      return {
        "points": points.map((e) => LatLng(e['lat'], e['lng'])).toList(),
        "distance": data['distance'] ?? 0,
        "duration": data['duration'] ?? 0,
      };
    }

    return {};
  }

  Future<void> _drawRoute(Map<String, dynamic> bus) async {
    double lat = double.tryParse(bus['latitude']?.toString() ?? "0") ?? 0;
    double lng = double.tryParse(bus['longitude']?.toString() ?? "0") ?? 0;

    if (lat == 0 || lng == 0) return;

    final start = LatLng(lat, lng);

    // 🔥 sementara pakai tujuan dummy (bisa kamu ganti dari DB nanti)
    final end = LatLng(-7.9839, 112.6214);

    final result = await getRouteDetail(start, end);

    final List<LatLng> routePoints = result['points'] ?? [];

    distance = result['distance'] ?? 0;
    duration = result['duration'] ?? 0;

    List<Marker> markers = [];

    // 🚍 marker bus
    markers.add(
      Marker(
        point: start,
        width: 50,
        height: 50,
        child: const Icon(Icons.directions_bus, color: Colors.green, size: 40),
      ),
    );

    // 🟢 START
    markers.add(
      Marker(
        point: start,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_on, color: Colors.green),
      ),
    );

    // 🔴 END
    markers.add(
      Marker(
        point: end,
        width: 40,
        height: 40,
        child: const Icon(Icons.flag, color: Colors.red),
      ),
    );

    setState(() {
      _busMarkers = markers;

      _busRoutes = [
        Polyline(
          points: routePoints,
          strokeWidth: 6,
          color: Colors.red, // 🔥 penting
        ),
      ];
    });

    // 🔥 ANIMASI BUS
    _animateBus(routePoints);
  }

  void _animateBus(List<LatLng> route) async {
    for (var point in route) {
      setState(() {
        _busMarkers = [
          Marker(
            point: point,
            width: 50,
            height: 50,
            child: const Icon(Icons.directions_bus, color: Colors.green, size: 40),
          )
        ];
      });

      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  void _generateMarkersAndRoutes() {
    List<Marker> markers = [];
    List<Polyline> polylines = [];
    _markerBusMap.clear();

    for (var bus in _busData) {
      // ✅ FILTER BUS
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

      // =========================
      // 🔥 HANDLE ROUTE
      // =========================
      List routeData = [];

      if (bus['route'] != null) {
        routeData = bus['route'];
      } else if (bus['route_path'] != null) {
        try {
          routeData = jsonDecode(bus['route_path']);
        } catch (e) {
          debugPrint("❌ route_path gagal decode");
        }
      }

      if (routeData.isEmpty) {
        debugPrint("⚠️ Bus ${bus['plat_nomor']} tidak punya route");
      }

      List<LatLng> routePoints = [];

      for (var point in routeData) {
        double rLat = double.tryParse(point['lat'].toString()) ?? 0.0;
        double rLng = double.tryParse(point['lng'].toString()) ?? 0.0;

        if (rLat != 0 && rLng != 0) {
          routePoints.add(LatLng(rLat, rLng));
        }
      }

      if (routePoints.isNotEmpty) {
        polylines.add(
          Polyline(
            points: routePoints,
            strokeWidth: 4,
            color: selectedBusId == null
                ? Colors.blue.withOpacity(0.4)
                : Colors.red,
          ),
        );
      }

      // AUTO FOCUS
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
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
              ),

              PolylineLayer(polylines: _busRoutes),

              MarkerLayer(markers: _busMarkers),
            ],
          ),

          // ✅ DROPDOWN (ADA "SEMUA")
            Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔽 DROPDOWN
                  DropdownButton<int>(
                    value: selectedBusId,
                    hint: const Text("Pilih Bus"),
                    underline: const SizedBox(),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text("Semua Bus"),
                      ),
                      ..._busData.map((bus) {
                        return DropdownMenuItem<int>(
                          value: bus['id'],
                          child: Text(bus['plat_nomor']),
                        );
                      // ignore: unnecessary_to_list_in_spreads
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedBusId = value;
                      });

                      if (value != null) {
                        final bus = _busData.firstWhere((b) => b['id'] == value);
                        _drawRoute(bus); // 🔥 jalanin route OSRM
                      } else {
                        _generateMarkersAndRoutes(); // tampil semua lagi
                      }
                    },
                  ),

                  const SizedBox(height: 8),

                  // 📏 INFO JARAK
                  Text("Jarak: ${(distance / 1000).toStringAsFixed(1)} km"),

                  // ⏱ ETA
                  Text("ETA: ${(duration / 60).toStringAsFixed(0)} menit"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
