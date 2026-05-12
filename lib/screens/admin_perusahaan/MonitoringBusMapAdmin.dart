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
  List<CircleMarker> _geofenceCircles = [];

  final MapController _mapController = MapController();
  late WebSocketChannel channel;

  int? selectedBusId;

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final Set<String> notifiedCheckpoints = {};

  List<dynamic> geofenceData = [];

  @override
  void initState() {
    super.initState();

    initNotifications();

    _initWebSocket();
    _fetchBuses();
  }

  double distance = 0;
  double duration = 0;

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
      print("FETCH BUS ERROR: $e");
    }
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
                _busData[index]['latitude'] = bus['latitude'];

                _busData[index]['longitude'] = bus['longitude'];

                final lat = double.tryParse(bus['latitude'].toString()) ?? 0;

                final lng = double.tryParse(bus['longitude'].toString()) ?? 0;

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
  Future<void> fetchGeofence(int routeId) async {
    try {
      final res = await http.get(
        Uri.parse("${ApiService.baseUrl}/api/routes/$routeId/geofence"),
      );

      final data = jsonDecode(res.body);

      if (data['success']) {
        List<dynamic> temp = [];

        // TERMINAL AWAL
        temp.add({
          "name": data['terminal_awal']['nama_terminal'],
          "lat": data['terminal_awal']['lat'],
          "lng": data['terminal_awal']['lng'],
          "radius": 1000.0,
          "type": "terminal_awal",
        });

        // CHECKPOINT
        for (var cp in data['checkpoints']) {
          temp.add({
            "name": cp['nama'],
            "lat": cp['lat'],
            "lng": cp['lng'],
            "radius": 1000.0,
            "type": "checkpoint",
          });
        }

        // TERMINAL TUJUAN
        temp.add({
          "name": data['terminal_tujuan']['nama_terminal'],
          "lat": data['terminal_tujuan']['lat'],
          "lng": data['terminal_tujuan']['lng'],
          "radius": 1000.0,
          "type": "terminal_tujuan",
        });

        setState(() {
          geofenceData = temp;
        });
      }
    } catch (e) {
      print("FETCH GEOFENCE ERROR: $e");
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
      final points = await fetchRoutePath(bus['route_id']);

      if (points.isEmpty) {
        print("❌ ROUTE KOSONG");
        return;
      }

      await fetchGeofence(bus['route_id']);

      // ================= POLYLINE =================
      setState(() {
        _polylines = [
          Polyline(points: points, strokeWidth: 6, color: Colors.blue),
        ];
      });

      // ================= MARKER CHECKPOINT =================
      final checkpointMarkers = <Marker>[];

      final geofenceCircles = <CircleMarker>[];

      for (var checkpoint in geofenceData) {
        final point = LatLng(checkpoint['lat'], checkpoint['lng']);

        Color zoneColor = Colors.orange;

        if (checkpoint['type'] == 'terminal_awal') {
          zoneColor = Colors.green;
        }

        if (checkpoint['type'] == 'terminal_tujuan') {
          zoneColor = Colors.red;
        }

        // ================= MARKER =================
        checkpointMarkers.add(
          Marker(
            point: point,
            width: 140,
            height: 60,
            child: Column(
              children: [
                Icon(Icons.location_on, color: zoneColor, size: 35),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    checkpoint['name'],
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        // ================= GEOFENCE =================
        geofenceCircles.add(
          CircleMarker(
            point: point,

            radius: checkpoint['radius'],

            useRadiusInMeter: true,

            color: zoneColor.withOpacity(0.3),

            borderColor: zoneColor,

            borderStrokeWidth: 3,
          ),
        );
      }

      // ================= UPDATE UI =================
      setState(() {
        _markers = [
          ..._markers.where(
            (m) => m.child.toString().contains("directions_bus"),
          ),
          ...checkpointMarkers,
        ];

        _geofenceCircles = geofenceCircles;
        print("TOTAL GEOFENCE: ${_geofenceCircles.length}");

        final allPoints = geofenceData
            .map(
              (e) => LatLng(
                double.parse(e['lat'].toString()),
                double.parse(e['lng'].toString()),
              ),
            )
            .toList();

        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(allPoints),
            padding: const EdgeInsets.all(50),
          ),
        );
      });

      // ================= AUTO MOVE =================
      if (points.isNotEmpty) {
        _mapController.move(points.first, 7);
      }

      print("✅ ROUTE DIGAMBAR");
    } catch (e) {
      print("❌ DRAW ROUTE ERROR: $e");
    }
  }

  Future<List<LatLng>> fetchRoutePath(int routeId) async {
    try {
      final res = await http.get(Uri.parse("${ApiService.baseUrl}/api/routes"));

      final data = jsonDecode(res.body);

      final routes = data['data'];

      // ================= DEBUG =================
      print("ROUTE ID BUS: $routeId");
      print("SEMUA ROUTE: $routes");

      // ================= CARI ROUTE =================
      final route = routes.firstWhere(
        (r) => r['id'].toString() == routeId.toString(),
        orElse: () => null,
      );

      // ================= ROUTE TIDAK ADA =================
      if (route == null) {
        print("❌ ROUTE TIDAK DITEMUKAN");
        return [];
      }

      final path = route['path'];

      // ================= PATH KOSONG =================
      if (path == null || path.isEmpty) {
        print("❌ PATH KOSONG");
        return [];
      }

      return List.from(path).map<LatLng>((p) {
        return LatLng(
          double.parse(p['lat'].toString()),
          double.parse(p['lng'].toString()),
        );
      }).toList();
    } catch (e) {
      print("FETCH ROUTE PATH ERROR: $e");
      return [];
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
    for (var checkpoint in geofenceData) {
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
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
              ),

              // ================= POLYLINE =================
              PolylineLayer(polylines: _polylines),

              // ================= GEOFENCE =================
              CircleLayer(circles: _geofenceCircles),

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
