import 'dart:async';
import 'dart:convert';
// ignore: library_prefixes
import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
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
  List<Map<String, dynamic>> _busData = [];
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];

  final MapController _mapController = MapController();
  late WebSocketChannel channel;

  int? selectedBusId;
  bool _userInteracting = false;

  @override
  void initState() {
    super.initState();

    _initWebSocket();
    _generateRealtimeMarkers();
  }

  double distance = 0;
  double duration = 0;

  // ignore: prefer_final_fields
  bool _isAnimating = false;
  // ignore: annotate_overrides
  bool get wantKeepAlive => true;

  // =========================
  // INIT WEBSOCKET
  // =========================
  void _initWebSocket() {
    channel = WebSocketChannel.connect(
      Uri.parse('wss://ebusapp-production-4fdd.up.railway.app'),
    );

    channel.stream.listen(
      (message) {
        print("🔥 WS MESSAGE: $message");

        final data = jsonDecode(message);

        if (data['type'] == 'bus_location') {
          final bus = data['data'];

          setState(() {
            final index = _busData.indexWhere(
              (b) => b['id'].toString() == bus['bus_id'].toString(),
            );

            if (index != -1) {
              _busData[index]['latitude'] = bus['latitude'];
              _busData[index]['longitude'] = bus['longitude'];
            } else {
              _busData.add({
                'id': bus['bus_id'],
                'latitude': bus['latitude'],
                'longitude': bus['longitude'],
                'plat_nomor': 'BUS ${bus['bus_id']}',
              });
            }

            _markers = _busData
                .map((b) {
                  final lat = double.tryParse(b['latitude'].toString()) ?? 0;
                  final lng = double.tryParse(b['longitude'].toString()) ?? 0;

                  if (lat == 0 || lng == 0) return null;

                  return Marker(
                    point: LatLng(lat, lng),
                    width: 50,
                    height: 50,
                    child: Column(
                      children: [
                        const Icon(Icons.directions_bus, color: Colors.green),
                        Text(b['plat_nomor'] ?? ''),
                      ],
                    ),
                  );
                })
                .whereType<Marker>()
                .toList();
          });
        }
      },
      onError: (e) => print("❌ WS ERROR: $e"),
      onDone: () => print("⚠️ WS CLOSED"),
    );
  }

  @override
  void dispose() {
    channel.sink.close(); // 🔥 WAJIB
    super.dispose();
  }

  // =========================
  // FETCH AWAL
  // =========================
  // ignore: unused_element
  Future<void> _fetchBuses() async {
    try {
      final res = await http.get(
        Uri.parse(
          "${ApiService.baseUrl}/api/buses?company_id=${widget.companyId}",
        ),
      );

      final data = jsonDecode(res.body)['data'];

      setState(() {
        _busData = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      print("❌ FETCH ERROR: $e");
    }
  }

  // =======================
  // rute
  // =======================
  Future<List<LatLng>> getRealRoute(List<LatLng> points) async {
    final coordinates = points
        .map((p) => "${p.longitude},${p.latitude}")
        .join(";");

    final url =
        "https://router.project-osrm.org/route/v1/driving/$coordinates?overview=full&geometries=geojson";

    final res = await http.get(Uri.parse(url));

    final data = jsonDecode(res.body);

    final coords = data['routes'][0]['geometry']['coordinates'];

    return coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
  }

  // =========================
  // MARKER REALTIME
  // =========================
  void _generateRealtimeMarkers() {
    final markers = _busData
        .map((bus) {
          double lat = double.tryParse(bus['latitude']?.toString() ?? "0") ?? 0;
          double lng =
              double.tryParse(bus['longitude']?.toString() ?? "0") ?? 0;

          if (lat == 0 || lng == 0) return null;

          return Marker(
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
          );
        })
        .whereType<Marker>()
        .toList();

    setState(() {
      _markers = markers;
    });
  }

  // =========================
  // DRAW ROUTE
  // =========================
  // ignore: unused_element
  Future<void> _drawRoute(Map<String, dynamic> bus) async {
    final routeData = bus['path'] ?? bus['route'];

    if (routeData == null || routeData.isEmpty) return;

    try {
      List decoded = routeData is String ? jsonDecode(routeData) : routeData;

      List<LatLng> rawRoute = decoded.map<LatLng>((p) {
        return LatLng(
          double.parse(p['lat'].toString()),
          double.parse(p['lng'].toString()),
        );
      }).toList();

      List<LatLng> realRoute = await getRealRoute(rawRoute);

      setState(() {
        _polylines = [
          Polyline(
            points: realRoute,
            strokeWidth: 10,
            color: Colors.black.withOpacity(0.2),
          ),
          Polyline(points: realRoute, strokeWidth: 6, color: Colors.blue),
        ];
      });

      if (!_userInteracting) {
        _mapController.move(realRoute.first, 7);
      }
    } catch (e) {
      print("❌ DRAW ROUTE ERROR: $e");
    }
  }

  // =========================
  // HITUNG ARAH
  // =========================
  // ignore: unused_element
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
    super.build(context);
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
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  _userInteracting = true;
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
              ),
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
                        // ignore: unused_local_variable
                        final bus = _busData.firstWhere(
                          (b) => b['id'] == selectedBusId,
                        );
                        _generateRealtimeMarkers();
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
