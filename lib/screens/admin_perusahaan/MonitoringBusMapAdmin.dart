import 'dart:async';
import 'dart:convert';
// ignore: library_prefixes
import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:ebus_app/services/api_service.dart';
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
  List<Marker> _checkpointMarkers = [];

  final Map<int, double> busSpeeds = {};

  final MapController _mapController = MapController();

  int? selectedBusId;

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final Set<String> notifiedCheckpoints = {};

  List<dynamic> geofenceData = [];

  @override
  void initState() {
    super.initState();

    initNotifications();

    _startRealtimePolling();
    _fetchBuses();
  }

  double distance = 0;
  double duration = 0;

  String perjalananStatus = "Hijau";
  Color statusColor = Colors.green;

  Timer? etaTimer;
  Timer? realtimeTimer;

  Map<int, LatLng> smoothPositions = {};

  final Map<int, LatLng> previousPositions = {};
  final Map<int, DateTime> previousTimes = {};
  final Map<int, double> currentSpeeds = {};

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

  void _startRealtimePolling() {
    realtimeTimer?.cancel();

    realtimeTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final res = await http.get(
          Uri.parse(
            "${ApiService.baseUrl}/api/buses?company_id=${widget.companyId}",
          ),
        );

        final data = jsonDecode(res.body)['data'];

        if (!mounted) return;

        setState(() {
          _busData = List<Map<String, dynamic>>.from(data);
        });

        // ================= UPDATE MARKER =================
        _generateRealtimeMarkers();

        // ================= CHECKPOINT =================
        for (var bus in _busData) {
          final lat = double.tryParse(bus['latitude']?.toString() ?? "0") ?? 0;

          final lng = double.tryParse(bus['longitude']?.toString() ?? "0") ?? 0;

          if (lat == 0 || lng == 0) continue;

          checkCheckpoint(lat, lng);

          calculateSpeed(bus['id'], lat, lng);

          // ================= ETA =================
          if (selectedBusId != null && selectedBusId == bus['id']) {
            if (geofenceData.isNotEmpty) {
              await calculateETA(
                startLat: lat,
                startLng: lng,
                endLat: double.parse(geofenceData.last['lat'].toString()),
                endLng: double.parse(geofenceData.last['lng'].toString()),
              );
            }
          }
        }

        print("✅ REALTIME UPDATED");
      } catch (e) {
        print("❌ POLLING ERROR: $e");
      }
    });
  }

  @override
  void dispose() {
    etaTimer?.cancel();

    realtimeTimer?.cancel();

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
        if (data['terminal_awal'] != null) {
          temp.add({
            "name": data['terminal_awal']['nama_terminal'],
            "lat": data['terminal_awal']['lat'],
            "lng": data['terminal_awal']['lng'],
            "radius": 1000.0,
            "type": "terminal_awal",
          });
        }

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
        if (data['terminal_tujuan'] != null) {
          temp.add({
            "name": data['terminal_tujuan']['nama_terminal'],
            "lat": data['terminal_tujuan']['lat'],
            "lng": data['terminal_tujuan']['lng'],
            "radius": 1000.0,
            "type": "terminal_tujuan",
          });
        }

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

  // =======================
  //calculate
  // =======================
  Future<void> calculateETA({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final url =
          "https://router.project-osrm.org/route/v1/driving/"
          "$startLng,$startLat;$endLng,$endLat"
          "?overview=false";

      final response = await http.get(Uri.parse(url));

      final data = jsonDecode(response.body);

      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final route = data['routes'][0];

        setState(() {
          // meter
          distance = route['distance'];

          // detik
          duration = route['duration'];
        });

        determineStatus();
      }
    } catch (e) {
      print("CALCULATE ETA ERROR: $e");
    }
  }

  void determineStatus() {
    double durationHours = duration / 3600;

    // ================= HIJAU =================
    if (durationHours <= 1) {
      setState(() {
        perjalananStatus = "Hijau - Perjalanan Lancar";

        statusColor = Colors.green;
      });
    }
    // ================= KUNING =================
    else if (durationHours > 1 && durationHours <= 4) {
      setState(() {
        perjalananStatus = "Kuning - Kendala Ringan";

        statusColor = Colors.orange;
      });
    }
    // ================= MERAH =================
    else {
      setState(() {
        perjalananStatus = "Merah - Kendala Berat";

        statusColor = Colors.red;
      });
    }
  }

  void calculateSpeed(int busId, double lat, double lng) {
    final now = DateTime.now();

    // ================= PERTAMA =================
    if (!previousPositions.containsKey(busId)) {
      previousPositions[busId] = LatLng(lat, lng);

      previousTimes[busId] = now;

      currentSpeeds[busId] = 0;

      return;
    }

    final oldPos = previousPositions[busId]!;

    final oldTime = previousTimes[busId]!;

    // ================= HITUNG JARAK =================
    final movedDistance = Geolocator.distanceBetween(
      oldPos.latitude,
      oldPos.longitude,
      lat,
      lng,
    );

    // ================= HITUNG WAKTU =================
    final seconds = now.difference(oldTime).inSeconds.toDouble();

    if (seconds <= 0) return;

    // ================= KM/H =================
    double speed = (movedDistance / seconds) * 3.6;

    // ================= FILTER GPS LONCAT =================
    if (speed > 150) {
      print("⚠️ GPS LONCAT BUS $busId");

      return;
    }

    // ================= FILTER DIAM =================
    if (movedDistance < 1) {
      speed = 0;
    }

    currentSpeeds[busId] = speed;

    print("🚌 BUS $busId SPEED: ${speed.toStringAsFixed(1)} km/h");

    // update posisi
    previousPositions[busId] = LatLng(lat, lng);

    previousTimes[busId] = now;

    // update status hanya untuk bus terpilih
    if (selectedBusId == busId) {
      determineTrafficStatus(speed);
    }
  }

  void determineTrafficStatus(double speed) {
    if (speed > 30) {
      setState(() {
        perjalananStatus = "Hijau - Lancar";
        statusColor = Colors.green;
      });
    } else if (speed > 10) {
      setState(() {
        perjalananStatus = "Kuning - Padat";
        statusColor = Colors.orange;
      });
    } else {
      setState(() {
        perjalananStatus = "Merah - Macet";
        statusColor = Colors.red;
      });
    }
  }

  // =========================
  // MARKER REALTIME
  // =========================
  void _generateRealtimeMarkers() {
    final markers = _busData
        .where((bus) {
          // hanya bus tracking aktif
          if (bus['is_tracking'] != 1) {
            return false;
          }

          if (selectedBusId == null) {
            return true;
          }

          return bus['id'] == selectedBusId;
        })
        .map((bus) {
          double lat = double.tryParse(bus['latitude']?.toString() ?? "0") ?? 0;

          double lng =
              double.tryParse(bus['longitude']?.toString() ?? "0") ?? 0;

          if (lat == 0 || lng == 0) return null;

          // ================= POSITION ASLI =================
          final newPosition = LatLng(lat, lng);

          // ================= POSITION SEBELUMNYA =================
          final oldPosition = smoothPositions[bus['id']];

          LatLng finalPosition = newPosition;

          // ================= SMOOTH POSITION =================
          if (oldPosition != null) {
            finalPosition = LatLng(
              oldPosition.latitude +
                  ((newPosition.latitude - oldPosition.latitude) * 0.15),

              oldPosition.longitude +
                  ((newPosition.longitude - oldPosition.longitude) * 0.15),
            );
          }

          smoothPositions[bus['id']] = finalPosition;

          return Marker(
            point: LatLng(lat, lng),
            width: 80,
            height: 80,
            child: Column(
              children: [
                const Icon(Icons.directions_bus, color: Colors.green, size: 36),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        bus['plat_nomor'] ?? '',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        "${currentSpeeds[bus['id']]?.toStringAsFixed(1) ?? '0'} km/h",
                        style: const TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        })
        .whereType<Marker>()
        .toList();

    setState(() {
      _markers = [...markers, ..._checkpointMarkers];
    });
  }

  // =========================
  // drawRoute
  // =========================
  Future<void> _drawRoute(Map<String, dynamic> bus) async {
    try {
      if (bus['route_id'] == null) {
        print("❌ ROUTE ID NULL");
        return;
      }

      final points = await fetchRoutePath(bus['route_id']);

      if (points.isEmpty) {
        print("❌ ROUTE KOSONG");
        return;
      }

      await fetchGeofence(bus['route_id']);

      // ================= CHECKPOINT =================
      final checkpointMarkers = <Marker>[];

      final geofenceCircles = <CircleMarker>[];

      for (var checkpoint in geofenceData) {
        final point = LatLng(
          double.parse(checkpoint['lat'].toString()),
          double.parse(checkpoint['lng'].toString()),
        );

        Color zoneColor = Colors.orange;

        if (checkpoint['type'] == 'terminal_awal') {
          zoneColor = Colors.green;
        }

        if (checkpoint['type'] == 'terminal_tujuan') {
          zoneColor = Colors.red;
        }

        checkpointMarkers.add(
          Marker(
            point: point,
            width: 100,
            height: 40,
            child: Column(
              children: [
                Icon(Icons.location_on, color: zoneColor, size: 25),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    checkpoint['name'],
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        geofenceCircles.add(
          CircleMarker(
            point: point,
            radius: checkpoint['radius'],
            useRadiusInMeter: true,
            color: zoneColor.withOpacity(0.2),
            borderColor: zoneColor,
            borderStrokeWidth: 2,
          ),
        );
      }

      setState(() {
        _polylines = [
          Polyline(points: points, strokeWidth: 5, color: Colors.blue),
        ];

        _checkpointMarkers = checkpointMarkers;

        _geofenceCircles = geofenceCircles;
      });

      _generateRealtimeMarkers();

      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(50),
        ),
      );

      print("✅ ROUTE DIGAMBAR");
    } catch (e) {
      print("❌ DRAW ROUTE ERROR: $e");
    }
  }

  Future<List<LatLng>> fetchRoutePath(int routeId) async {
    try {
      final res = await http.get(
        Uri.parse(
          "${ApiService.baseUrl}/api/routes?company_id=${widget.companyId}",
        ),
      );

      print("ROUTE RESPONSE: ${res.body}");

      final data = jsonDecode(res.body);

      if (data['success'] != true) {
        print("❌ API ROUTE FAILED");
        return [];
      }

      final routes = data['data'];

      final route = routes.firstWhere(
        (r) => r['id'].toString() == routeId.toString(),
        orElse: () => null,
      );

      if (route == null) {
        print("❌ ROUTE TIDAK DITEMUKAN");
        return [];
      }

      final path = route['path'];

      if (path == null || path.isEmpty) {
        print("❌ PATH KOSONG");
        return [];
      }

      print("✅ TOTAL TITIK ROUTE: ${path.length}");

      return List.from(path).map<LatLng>((p) {
        return LatLng(
          double.parse(p['lat'].toString()),
          double.parse(p['lng'].toString()),
        );
      }).toList();
    } catch (e) {
      print("FETCH ROUTE ERROR: $e");
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
            top: 10,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 40,
                    child: DropdownButton<int?>(
                      value: selectedBusId,
                      isExpanded: true,
                      underline: const SizedBox(),
                      hint: const Text(
                        "Pilih Bus",
                        style: TextStyle(fontSize: 12),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text(
                            "Semua Bus",
                            style: TextStyle(fontSize: 12),
                          ),
                        ),

                        ..._busData.map(
                          (b) => DropdownMenuItem<int?>(
                            value: b['id'],
                            child: Text(
                              b['plat_nomor'],
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) async {
                        setState(() {
                          selectedBusId = val;
                        });

                        // SEMUA BUS
                        if (val == null) {
                          setState(() {
                            _polylines = [];
                            _checkpointMarkers = [];
                            _geofenceCircles = [];
                          });

                          _generateRealtimeMarkers();
                          return;
                        }

                        final bus = _busData.firstWhere((b) => b['id'] == val);

                        await _drawRoute(bus);

                        final lat =
                            double.tryParse(bus['latitude'].toString()) ?? 0;

                        final lng =
                            double.tryParse(bus['longitude'].toString()) ?? 0;

                        if (geofenceData.isNotEmpty) {
                          await calculateETA(
                            startLat: lat,
                            startLng: lng,
                            endLat: double.parse(
                              geofenceData.last['lat'].toString(),
                            ),
                            endLng: double.parse(
                              geofenceData.last['lng'].toString(),
                            ),
                          );
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        "Jarak ${(distance / 1000).toStringAsFixed(1)} km",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        "ETA ${(duration / 60).toStringAsFixed(0)} mnt",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Row(
                        children: [
                          Icon(Icons.circle, color: statusColor, size: 10),

                          const SizedBox(width: 4),

                          Text(
                            perjalananStatus,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
