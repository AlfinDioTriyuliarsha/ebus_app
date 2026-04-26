import 'dart:async';
import 'dart:convert';
// ignore: library_prefixes
import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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

  List<Marker> _markers = [];
  List<Polyline> _polylines = [];

  Timer? _timer;
  final MapController _mapController = MapController();

  int? selectedBusId;

  double distance = 0;
  double duration = 0;

  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();

    _fetchBuses();

    _timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _fetchBusesRealtime(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // =========================
  // FETCH AWAL
  // =========================
  Future<void> _fetchBuses() async {
    try {
      final res = await http.get(
        Uri.parse(
          "${ApiService.baseUrl}/api/buses?company_id=${widget.companyId}",
        ),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'];

        setState(() {
          _busData = List<Map<String, dynamic>>.from(data);
        });

        _generateRealtimeMarkers();
      }
    } catch (e) {
      debugPrint("ERROR FETCH BUS: $e");
    }
  }

  // =========================
  // FETCH REALTIME (TIAP 2 DETIK)
  // =========================
  Future<void> _fetchBusesRealtime() async {
    try {
      final res = await http.get(
        Uri.parse(
          "${ApiService.baseUrl}/api/buses?company_id=${widget.companyId}",
        ),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'];

        setState(() {
          _busData = List<Map<String, dynamic>>.from(data);
        });

        if (selectedBusId == null) {
          _generateRealtimeMarkers();
        } else {
          final bus = _busData.firstWhere((b) => b['id'] == selectedBusId);
          _drawRoute(bus);
        }
      }
    } catch (e) {
      debugPrint("ERROR REALTIME: $e");
    }
  }

  // =========================
  // MARKER SEMUA BUS
  // =========================
  void _generateRealtimeMarkers() {
    List<Marker> markers = [];

    for (var bus in _busData) {
      double lat = double.tryParse(bus['latitude']?.toString() ?? "0") ?? 0;
      double lng = double.tryParse(bus['longitude']?.toString() ?? "0") ?? 0;

      if (lat == 0 || lng == 0) continue;

      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 50,
          height: 50,
          child: Column(
            children: [
              const Icon(Icons.directions_bus, color: Colors.green),
              Text(
                bus['plat_nomor'] ?? '',
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
      );
    }

    setState(() {
      _markers = markers;
      _polylines = [];
    });
  }

  // =========================
  // DRAW ROUTE (1 BUS)
  // =========================
  Future<void> _drawRoute(Map<String, dynamic> bus) async {
  final routeData = bus['route']; // ✅ FIX DI SINI
  print("ROUTE DATA: $routeData");

  if (routeData == null || routeData.isEmpty) return;

  List<LatLng> route = [];

    try {
      List decoded = routeData is String
          ? jsonDecode(routeData)
          : routeData;

      route = decoded.map<LatLng>((p) {
        return LatLng(
          double.parse(p['lat'].toString()),
          double.parse(p['lng'].toString()),
        );
      }).toList();
    } catch (e) {
      debugPrint("ERROR PARSE ROUTE: $e");
      return;
    }

    final start = route.first;

    setState(() {
      _polylines = [
        Polyline(points: route, strokeWidth: 6, color: Colors.red)
      ];
    });

    _mapController.move(start, 14);

    _animateBus(route);
  }

  // =========================
  // ANIMASI BUS
  // =========================
  Future<void> _animateBus(List<LatLng> route) async {
    if (_isAnimating) return;
    _isAnimating = true;

    for (int i = 0; i < route.length - 1; i++) {
      final start = route[i];
      final end = route[i + 1];

      const steps = 20;

      for (int j = 0; j <= steps; j++) {
        final lat =
            start.latitude + (end.latitude - start.latitude) * (j / steps);
        final lng =
            start.longitude + (end.longitude - start.longitude) * (j / steps);

        final angle = _bearing(start, end);

        setState(() {
          _markers = [
            Marker(
              point: LatLng(lat, lng),
              width: 60,
              height: 60,
              child: Transform.rotate(
                angle: angle,
                child: const Icon(
                  Icons.directions_bus,
                  size: 40,
                  color: Colors.green,
                ),
              ),
            ),
          ];
        });

        await Future.delayed(const Duration(milliseconds: 40));
      }
    }

    _isAnimating = false;
  }

  // =========================
  // HITUNG ARAH
  // =========================
  double _bearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * Math.pi / 180;
    final lon1 = start.longitude * Math.pi / 180;
    final lat2 = end.latitude * Math.pi / 180;
    final lon2 = end.longitude * Math.pi / 180;

    final dLon = lon2 - lon1;

    final y = Math.sin(dLon) * Math.cos(lat2);
    final x =
        Math.cos(lat1) * Math.sin(lat2) -
        Math.sin(lat1) * Math.cos(lat2) * Math.cos(dLon);

    return Math.atan2(y, x);
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Monitoring Armada"),
        backgroundColor: const Color(0xFF001F3F),
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
              PolylineLayer(polylines: _polylines),
              MarkerLayer(markers: _markers),
            ],
          ),

          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  DropdownButton<int>(
                    value: selectedBusId,
                    hint: const Text("Pilih Bus"),
                    items: [
                      const DropdownMenuItem(value: null, child: Text("Semua")),
                      ..._busData.map(
                        (b) => DropdownMenuItem(
                          value: b['id'],
                          child: Text(b['plat_nomor']),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        selectedBusId = val;
                      });

                      if (selectedBusId == null) {
                        _generateRealtimeMarkers();
                      } else {
                        final bus = _busData.firstWhere(
                          (b) => b['id'] == selectedBusId,
                        );
                        _drawRoute(bus); // ✔ ini akan pakai route terbaru
                      }
                    },
                  ),
                  Text("Jarak: ${(distance / 1000).toStringAsFixed(1)} km"),
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
