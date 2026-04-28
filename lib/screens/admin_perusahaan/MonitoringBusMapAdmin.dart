import 'dart:async';
import 'dart:convert';
// ignore: library_prefixes
import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
// ignore: unused_import
import 'package:ebus_app/services/api_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class MonitoringBusMapAdmin extends StatefulWidget {
  final int companyId;

  const MonitoringBusMapAdmin({super.key, required this.companyId});

  @override
  State<MonitoringBusMapAdmin> createState() => _MonitoringBusMapAdminState();
}

class _MonitoringBusMapAdminState extends State<MonitoringBusMapAdmin>
    with AutomaticKeepAliveClientMixin {
  // ================= STATE =================
  List<Map<String, dynamic>> _busData = [];

  late WebSocketChannel channel;

  List<Marker> _markers = [];
  List<Polyline> _polylines = [];

  final MapController _mapController = MapController();

  int? selectedBusId;
  // ignore: prefer_final_fields
  bool _userInteracting = false;

  double distance = 0;
  double duration = 0;

  // 🔥 AI DATA
  final Map<int, double> _speed = {};
  final Map<int, DateTime> _lastUpdate = {};
  final Map<int, LatLng> _lastPositions = {};

  // 🔥 CACHE & HISTORY
  final Map<int, List<LatLng>> _routeCache = {};
  final Map<int, List<LatLng>> _history = {};

  @override
  bool get wantKeepAlive => true;

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  // ================= WEBSOCKET =================
  void _connectWebSocket() {
    channel = WebSocketChannel.connect(Uri.parse("ws://YOUR_SERVER_IP:3001"));

    channel.stream.listen((message) {
      final data = jsonDecode(message);

      if (data['type'] == 'bus_location') {
        setState(() {
          _busData = List<Map<String, dynamic>>.from(data['data']);
        });

        _processRealtimeData();
      }
    });
  }

  // ================= REALTIME PROCESS =================
  void _processRealtimeData() {
    for (var bus in _busData) {
      double lat = double.tryParse(bus['latitude']?.toString() ?? "0") ?? 0;
      double lng = double.tryParse(bus['longitude']?.toString() ?? "0") ?? 0;

      if (lat == 0 || lng == 0) continue;

      final current = LatLng(lat, lng);
      final id = bus['id'];

      // 🔥 HISTORY
      _history.putIfAbsent(id, () => []);
      _history[id]!.add(current);

      if (_history[id]!.length > 50) {
        _history[id]!.removeAt(0);
      }

      // 🔥 AI SPEED
      if (_lastPositions.containsKey(id)) {
        final prev = _lastPositions[id]!;
        final now = DateTime.now();
        final lastTime = _lastUpdate[id];

        if (lastTime != null) {
          final timeDiff = now.difference(lastTime).inSeconds;

          final dist = _distance(prev, current);

          if (timeDiff > 0) {
            double speed = dist / timeDiff;

            _speed[id] = (_speed[id] ?? speed) * 0.7 + speed * 0.3;
          }
        }

        _lastUpdate[id] = now;
      }

      _lastPositions[id] = current;
    }

    _generateMarkers();
  }

  // ================= DISTANCE =================
  double _distance(LatLng a, LatLng b) {
    const R = 6371000;

    final dLat = (b.latitude - a.latitude) * Math.pi / 180;
    final dLon = (b.longitude - a.longitude) * Math.pi / 180;

    final lat1 = a.latitude * Math.pi / 180;
    final lat2 = b.latitude * Math.pi / 180;

    final aHarv =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.sin(dLon / 2) *
            Math.sin(dLon / 2) *
            Math.cos(lat1) *
            Math.cos(lat2);

    final c = 2 * Math.atan2(Math.sqrt(aHarv), Math.sqrt(1 - aHarv));

    return R * c;
  }

  // ================= AI ETA =================
  double _calculateETA(int busId, double remainingDistance) {
    double speed = _speed[busId] ?? 10;

    if (speed < 5) speed *= 0.5;

    if (speed == 0) return 0;

    return remainingDistance / speed;
  }

  // ================= OSRM =================
  Future<List<LatLng>> getRealRoute(List<LatLng> points) async {
    final coords = points.map((p) => "${p.longitude},${p.latitude}").join(";");

    final url =
        "https://router.project-osrm.org/route/v1/driving/$coords?overview=full&geometries=geojson";

    final res = await http.get(Uri.parse(url));

    final data = jsonDecode(res.body);
    final route = data['routes'][0];

    distance = route['distance'];

    final geometry = route['geometry']['coordinates'] as List;

    return geometry.map<LatLng>((c) {
      return LatLng(c[1], c[0]);
    }).toList();
  }

  // ================= DRAW ROUTE =================
  // ignore: unused_element
  Future<void> _drawRoute(Map<String, dynamic> bus) async {
    final routeId = bus['route_id'];
    final busId = bus['id'];

    if (_routeCache.containsKey(routeId)) {
      final cached = _routeCache[routeId]!;

      duration = _calculateETA(busId, distance);

      setState(() {
        _polylines = _buildPolyline(cached, busId);
      });

      return;
    }

    final routeData = bus['path'] ?? bus['route'];

    if (routeData == null || routeData.isEmpty) return;

    List decoded = routeData is String ? jsonDecode(routeData) : routeData;

    List<LatLng> raw = decoded.map<LatLng>((p) {
      return LatLng(
        double.parse(p['lat'].toString()),
        double.parse(p['lng'].toString()),
      );
    }).toList();

    final realRoute = await getRealRoute(raw);

    _routeCache[routeId] = realRoute;

    duration = _calculateETA(busId, distance);

    setState(() {
      _polylines = _buildPolyline(realRoute, busId);
    });

    if (!_userInteracting) {
      _mapController.move(realRoute.first, 7);
    }
  }

  // ================= POLYLINE =================
  List<Polyline> _buildPolyline(List<LatLng> route, int busId) {
    return [
      Polyline(
        points: route,
        strokeWidth: 10,
        color: Colors.black.withOpacity(0.2),
      ),
      Polyline(points: route, strokeWidth: 6, color: Colors.blue),
      if (_history.containsKey(busId))
        Polyline(points: _history[busId]!, strokeWidth: 4, color: Colors.green),
    ];
  }

  // ================= MARKER =================
  void _generateMarkers() {
    List<Marker> markers = [];

    for (var bus in _busData) {
      double lat = double.tryParse(bus['latitude']?.toString() ?? "0") ?? 0;
      double lng = double.tryParse(bus['longitude']?.toString() ?? "0") ?? 0;

      if (lat == 0 || lng == 0) continue;

      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 70,
          height: 70,
          child: const Icon(Icons.directions_bus, color: Colors.blue, size: 30),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    super.build(context);

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
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              ),
              PolylineLayer(polylines: _polylines),
              MarkerLayer(markers: _markers),
            ],
          ),

          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(10),
              color: Colors.white,
              child: Column(
                children: [
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
