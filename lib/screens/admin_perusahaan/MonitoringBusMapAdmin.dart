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
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MonitoringBusMapAdmin extends StatefulWidget {
  final int companyId;
  final int busId;
  final int userId;

  const MonitoringBusMapAdmin({
    super.key,
    required this.companyId,
    required this.busId,
    required this.userId,
  });

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

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final Set<String> notifiedCheckpoints = {};

  final List<Map<String, dynamic>> checkpoints = [
    {
      'name': 'Rumah Makan',
      'lat': -7.9504767,
      'lng': 112.6665545,
      'radius': 100.0,
    },

    {
      'name': 'Terminal',
      'lat': -7.9510000,
      'lng': 112.6670000,
      'radius': 100.0,
    },
  ];

  @override
  void initState() {
    super.initState();

    initNotifications();

    _initWebSocket();
    _fetchBuses();
  }

  double distance = 0;
  double duration = 0;

  // ignore: prefer_final_fields
  bool _isAnimating = false;
  // ignore: annotate_overrides
  bool get wantKeepAlive => true;

  Future<void> initNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await notificationsPlugin.initialize(settings);
  }

  // =========================
  // INIT WEBSOCKET
  // =========================
  void _initWebSocket() {
    channel = WebSocketChannel.connect(
      Uri.parse('wss://ebusapp-production-4fdd.up.railway.app'),
    );

    channel.stream.listen(
      (message) {
        try {
          print("🔥 WS MESSAGE: $message");

          final data = jsonDecode(message);

          if (data == null) return;

          if (data['type'] == 'bus_location') {
            final bus = data['data'];

            if (bus == null) return;

            setState(() {
              final index = _busData.indexWhere(
                (b) => b['id'].toString() == bus['bus_id'].toString(),
              );

              if (index != -1) {
                _busData[index]['latitude'] =
                    bus['latitude'];

                _busData[index]['longitude'] =
                    bus['longitude'];

                final lat = double.tryParse(
                      bus['latitude'].toString(),
                    ) ??
                    0;

                final lng = double.tryParse(
                      bus['longitude'].toString(),
                    ) ??
                    0;

                checkCheckpoint(lat, lng);
              }

              _markers = _busData
                  .map((b) {
                    final lat = double.tryParse(b['latitude'].toString()) ?? 0;

                    final lng = double.tryParse(b['longitude'].toString()) ?? 0;

                    if (lat == 0 || lng == 0) {
                      return null;
                    }

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
        } catch (e) {
          print("❌ WS ERROR PARSE: $e");
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

      _generateRealtimeMarkers();
    } catch (e) {
      print("❌ FETCH ERROR: $e");

      _generateRealtimeMarkers();
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
  // drawRoute
  // =========================
  Future<void> _drawRoute(Map<String, dynamic> bus) async {
    try {
      final routeData = bus['route'];

      if (routeData == null) {
        print("❌ ROUTE NULL");
        return;
      }

      List decoded = routeData is String ? jsonDecode(routeData) : routeData;

      List<LatLng> points = decoded.map<LatLng>((p) {
        return LatLng(
          double.parse(p['lat'].toString()),
          double.parse(p['lng'].toString()),
        );
      }).toList();

      // ================= POLYLINE =================
      setState(() {
        _polylines = [
          Polyline(points: points, strokeWidth: 6, color: Colors.blue),
        ];
      });

      // ================= CHECKPOINT =================
      final checkpointMarkers = checkpoints.map((c) {
        return Marker(
          point: LatLng(c['lat'], c['lng']),
          width: 40,
          height: 40,
          child: Column(
            children: [
              const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 30,
              ),

              Text(
                c['name'],
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        );
      }).toList();

      setState(() {
        _markers.addAll(checkpointMarkers);
      });

      // ================= AUTO MOVE =================
      if (points.isNotEmpty) {
        _mapController.move(points.first, 8);
      }

      print("✅ ROUTE DIGAMBAR");
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

  bool isInsideGeofence({
    required double busLat,
    required double busLng,
    required double checkpointLat,
    required double checkpointLng,
    required double radius,
  }) {
    double distance = Geolocator.distanceBetween(
      busLat,
      busLng,
      checkpointLat,
      checkpointLng,
    );

    return distance <= radius;
  }

  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'checkpoint_channel',
          'Checkpoint Notifications',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await notificationsPlugin.show(0, title, body, details);
  }

  void checkCheckpoint(double lat, double lng) {
    for (var checkpoint in checkpoints) {
      final inside = isInsideGeofence(
        busLat: lat,
        busLng: lng,
        checkpointLat: checkpoint['lat'],
        checkpointLng: checkpoint['lng'],
        radius: checkpoint['radius'],
      );

      final checkpointName = checkpoint['name'];

      if (inside && !notifiedCheckpoints.contains(checkpointName)) {
        notifiedCheckpoints.add(checkpointName);

        print("✅ MASUK CHECKPOINT: $checkpointName");

        showNotification("Checkpoint", "Bus mendekati $checkpointName");
      }
    }
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

              // ================= POLYLINE =================
              PolylineLayer(polylines: _polylines),

              // ================= MARKER =================
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
                  DropdownButton<int?>(
                    value: selectedBusId,
                    hint: const Text("Pilih Bus"),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text("Semua"),
                      ),

                      ..._busData.map(
                        (b) => DropdownMenuItem<int?>(
                          value: b['id'],
                          child: Text(b['plat_nomor']),
                        ),
                      ),
                    ],

                    onChanged: (int? val) {
                      setState(() {
                        selectedBusId = val;
                      });

                      if (selectedBusId == null) {
                        _generateRealtimeMarkers();

                        setState(() {
                          _polylines = [];
                        });

                        return;
                      }

                      final found = _busData.where(
                        (b) => b['id'] == selectedBusId,
                      );

                      if (found.isEmpty) return;

                      final bus = found.first;

                      _drawRoute(bus);

                      _generateRealtimeMarkers();
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
