import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:ebus_app/services/api_service.dart';
// ignore: library_prefixes
import 'dart:math' as Math;

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

  // ignore: prefer_final_fields
  bool _isLoading = true;
  Timer? _timer;

  final MapController _mapController = MapController();

  int? selectedBusId;
  bool isTrackingMode = false;

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

  // =========================
  // FETCH DATA
  // =========================
  Future<void> _fetchBusesByCompany() async {
    final url = Uri.parse(
      "${ApiService.baseUrl}/api/buses?company_id=${widget.companyId}",
    );

    final res = await http.get(url);
    final data = jsonDecode(res.body);

    _busData = List<Map<String, dynamic>>.from(data['data'] ?? []);

    if (!isTrackingMode) {
      _generateMarkers();
    }
  }

  // =========================
  // MARKER SEMUA BUS
  // =========================
  void _generateMarkers() {
    List<Marker> markers = [];

    for (var bus in _busData) {
      double lat = double.tryParse(bus['latitude'].toString()) ?? 0;
      double lng = double.tryParse(bus['longitude'].toString()) ?? 0;

      if (lat == 0 || lng == 0) continue;

      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 50,
          height: 50,
          child: Column(
            children: [
              const Icon(Icons.directions_bus, color: Colors.green),
              Text(bus['plat_nomor'], style: const TextStyle(fontSize: 10)),
            ],
          ),
        ),
      );
    }

    setState(() {
      _busMarkers = markers;
      _busRoutes = [];
    });
  }

  // =========================
  // GET ROUTE OSRM
  // =========================
  Future<Map<String, dynamic>> getRoute(LatLng start, LatLng end) async {
    final url = Uri.parse(
      "${ApiService.baseUrl}/api/routes/direction"
      "?start_lat=${start.latitude}"
      "&start_lng=${start.longitude}"
      "&end_lat=${end.latitude}"
      "&end_lng=${end.longitude}",
    );

    final res = await http.get(url);
    final data = jsonDecode(res.body);

    return {
      "points": (data['data'] as List)
          .map((e) => LatLng(e['lat'], e['lng']))
          .toList(),
      "distance": data['distance'],
      "duration": data['duration'],
    };
  }

  // =========================
  // DRAW ROUTE
  // =========================
  Future<void> _drawRoute(Map<String, dynamic> bus) async {
    _timer?.cancel(); // 🔥 STOP REFRESH

    isTrackingMode = true;

    final start = LatLng(
      double.parse(bus['latitude'].toString()),
      double.parse(bus['longitude'].toString()),
    );

    final end = LatLng(-7.9839, 112.6214);

    final result = await getRoute(start, end);

    final List<LatLng> routePoints = result['points'];

    distance = result['distance'];
    duration = result['duration'];

    setState(() {
      _busRoutes = [
        Polyline(points: routePoints, strokeWidth: 6, color: Colors.red),
      ];
    });

    _animateBus(routePoints);
  }

  // =========================
  // ANIMASI SMOOTH + ROTASI
  // =========================
  Future<void> _animateBus(List<LatLng> route) async {
    for (int i = 0; i < route.length - 1; i++) {
      final start = route[i];
      final end = route[i + 1];

      const steps = 25;

      for (int j = 0; j <= steps; j++) {
        final lat =
            start.latitude + (end.latitude - start.latitude) * (j / steps);

        final lng =
            start.longitude + (end.longitude - start.longitude) * (j / steps);

        final angle = _bearing(start, end);

        setState(() {
          _busMarkers = [
            Marker(
              point: LatLng(lat, lng),
              width: 60,
              height: 60,
              child: Transform.rotate(
                angle: angle,
                child: const Icon(
                  Icons.directions_bus,
                  color: Colors.green,
                  size: 40,
                ),
              ),
            ),
          ];
        });

        await Future.delayed(const Duration(milliseconds: 30));
      }
    }
  }

  double _bearing(LatLng a, LatLng b) {
    final lat1 = a.latitude * Math.pi / 180;
    final lat2 = b.latitude * Math.pi / 180;
    final dLon = (b.longitude - a.longitude) * Math.pi / 180;

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
      appBar: AppBar(title: const Text("Monitoring Armada")),
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

          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(10),
              color: Colors.white,
              child: Column(
                children: [
                  DropdownButton<int>(
                    value: selectedBusId,
                    hint: const Text("Pilih Bus"),
                    items: _busData.map((bus) {
                      return DropdownMenuItem<int>(
                        value: bus['id'],
                        child: Text(bus['plat_nomor']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      selectedBusId = value;

                      final bus = _busData.firstWhere((b) => b['id'] == value);

                      _drawRoute(bus);
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
