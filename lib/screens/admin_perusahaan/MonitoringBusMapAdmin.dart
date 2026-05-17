import 'dart:async';
import 'dart:convert';
import 'dart:math' as Math;

import 'package:ebus_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

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
  State<MonitoringBusMapAdmin> createState() =>
      _MonitoringBusMapAdminState();
}

class _MonitoringBusMapAdminState
    extends State<MonitoringBusMapAdmin>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final MapController _mapController = MapController();

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  List<Map<String, dynamic>> _busData = [];

  Map<String, dynamic>? selectedBus;

  List<Marker> _markers = [];
  List<Marker> _busMarkers = [];
  List<Marker> _checkpointMarkers = [];

  List<Polyline> _polylines = [];

  List<CircleMarker> _geofenceCircles = [];

  List<dynamic> geofenceData = [];

  Timer? realtimeTimer;

  final Set<String> notifiedCheckpoints = {};

  // =========================
  // PER BUS
  // =========================
  final Map<int, LatLng> previousPositions = {};
  final Map<int, DateTime> previousTimes = {};
  final Map<int, double> busSpeeds = {};
  final Map<int, LatLng> smoothPositions = {};

  double distance = 0;
  double duration = 0;

  String perjalananStatus = "Memuat...";
  Color statusColor = Colors.green;

  @override
  void initState() {
    super.initState();

    initNotifications();

    _initializeMap();
  }

  Future<void> initNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await notificationsPlugin.initialize(settings);
  }

  Future<void> _initializeMap() async {
    await _fetchBuses();

    _startRealtimePolling();
  }

  // =========================
  // FETCH BUS
  // =========================
  Future<void> _fetchBuses() async {
    try {
      final res = await http.get(
        Uri.parse(
          "${ApiService.baseUrl}/api/buses?company_id=${widget.companyId}",
        ),
      );

      final data = jsonDecode(res.body);

      print("🔥 RAW BUS DATA: ${res.body}");

      if (data['success'] != true) {
        print("❌ API FAILED");
        return;
      }

      final buses = List<Map<String, dynamic>>.from(data['data']);

      setState(() {
        _busData = buses;
      });

      print("✅ TOTAL BUS: ${buses.length}");

      // =========================
      // PILIH BUS BERDASARKAN busId
      // =========================
      if (buses.isNotEmpty) {
        selectedBus = buses.firstWhere(
          (b) => b['id'] == widget.busId,
          orElse: () => buses.first,
        );

        await _drawRoute(selectedBus!);
      }

      _generateRealtimeMarkers();
    } catch (e) {
      print("❌ FETCH BUS ERROR: $e");
    }
  }

  // =========================
  // REALTIME
  // =========================
  void _startRealtimePolling() {
    realtimeTimer?.cancel();

    realtimeTimer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) async {
        try {
          final res = await http.get(
            Uri.parse(
              "${ApiService.baseUrl}/api/buses?company_id=${widget.companyId}",
            ),
          );

          if (res.statusCode != 200) {
            print("❌ BUS TIDAK ADA");
            return;
          }

          final data = jsonDecode(res.body);

          final buses =
              List<Map<String, dynamic>>.from(data['data']);

          setState(() {
            _busData = buses;
          });

          // =========================
          // UPDATE BUS TERPILIH
          // =========================
          if (selectedBus != null) {
            final updatedBus = buses.firstWhere(
              (b) => b['id'] == selectedBus!['id'],
              orElse: () => selectedBus!,
            );

            selectedBus = updatedBus;
          }

          // =========================
          // UPDATE MARKER
          // =========================
          _generateRealtimeMarkers();

          // =========================
          // LOOP BUS
          // =========================
          for (var bus in buses) {
            final busId = bus['id'];

            final lat =
                double.tryParse(bus['latitude']?.toString() ?? "0") ?? 0;

            final lng =
                double.tryParse(bus['longitude']?.toString() ?? "0") ?? 0;

            print("GPS BUS $busId => $lat , $lng");

            if (lat == 0 || lng == 0) {
              print("GPS KOSONG");
              continue;
            }

            checkCheckpoint(lat, lng);

            calculateSpeed(busId, lat, lng);

            // ================= ETA
            if (selectedBus != null &&
                selectedBus!['id'] == busId) {
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
            }
          }

          print("✅ REALTIME UPDATED");
        } catch (e) {
          print("❌ POLLING ERROR: $e");
        }
      },
    );
  }

  // =========================
  // SPEED PER BUS
  // =========================
  void calculateSpeed(
    int busId,
    double lat,
    double lng,
  ) {
    final now = DateTime.now();

    if (!previousPositions.containsKey(busId)) {
      previousPositions[busId] = LatLng(lat, lng);

      previousTimes[busId] = now;

      return;
    }

    final oldPos = previousPositions[busId]!;

    final oldTime = previousTimes[busId]!;

    final movedDistance = Geolocator.distanceBetween(
      oldPos.latitude,
      oldPos.longitude,
      lat,
      lng,
    );

    final seconds =
        now.difference(oldTime).inSeconds.toDouble();

    if (seconds <= 0) return;

    final speed = (movedDistance / seconds) * 3.6;

    // =========================
    // FILTER SPEED TIDAK MASUK AKAL
    // =========================
    if (speed < 300) {
      busSpeeds[busId] = speed;

      print(
        "🚌 BUS $busId SPEED: ${speed.toStringAsFixed(1)} km/h",
      );

      determineTrafficStatus(speed);
    }

    previousPositions[busId] = LatLng(lat, lng);

    previousTimes[busId] = now;
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
  // MARKER
  // =========================
  void _generateRealtimeMarkers() {
    final markers = _busData
        .map((bus) {
          final busId = bus['id'];

          double lat =
              double.tryParse(bus['latitude']?.toString() ?? "0") ?? 0;

          double lng =
              double.tryParse(bus['longitude']?.toString() ?? "0") ?? 0;

          if (lat == 0 || lng == 0) return null;

          final oldPos = smoothPositions[busId];

          LatLng smoothPos = LatLng(lat, lng);

          if (oldPos != null) {
            smoothPos = LatLng(
              oldPos.latitude +
                  ((lat - oldPos.latitude) * 0.3),
              oldPos.longitude +
                  ((lng - oldPos.longitude) * 0.3),
            );
          }

          smoothPositions[busId] = smoothPos;

          return Marker(
            point: smoothPos,
            width: 90,
            height: 90,
            child: Column(
              children: [
                const Icon(
                  Icons.directions_bus,
                  color: Colors.green,
                  size: 40,
                ),
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
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        "${busSpeeds[busId]?.toStringAsFixed(1) ?? '0'} km/h",
                        style: const TextStyle(fontSize: 10),
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
      _busMarkers = markers;

      _markers = [
        ..._checkpointMarkers,
        ..._busMarkers,
      ];
    });
  }

  // =========================
  // DRAW ROUTE
  // =========================
  Future<void> _drawRoute(
    Map<String, dynamic> bus,
  ) async {
    try {
      if (bus['route_id'] == null) {
        print("❌ ROUTE ID NULL");
        return;
      }

      final points =
          await fetchRoutePath(bus['route_id']);

      if (points.isEmpty) {
        print("❌ ROUTE KOSONG");
        return;
      }

      await fetchGeofence(bus['route_id']);

      setState(() {
        _polylines = [
          Polyline(
            points: points,
            strokeWidth: 5,
            color: Colors.blue,
          ),
        ];
      });

      final checkpointMarkers = <Marker>[];
      final geofenceCircles = <CircleMarker>[];

      for (var checkpoint in geofenceData) {
        final point = LatLng(
          checkpoint['lat'],
          checkpoint['lng'],
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
            width: 140,
            height: 60,
            child: Column(
              children: [
                Icon(
                  Icons.location_on,
                  color: zoneColor,
                  size: 35,
                ),
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

        geofenceCircles.add(
          CircleMarker(
            point: point,
            radius: checkpoint['radius'],
            useRadiusInMeter: true,
            color: zoneColor.withOpacity(0.3),
            borderColor: zoneColor,
            borderStrokeWidth: 2,
          ),
        );
      }

      setState(() {
        _checkpointMarkers = checkpointMarkers;
        _geofenceCircles = geofenceCircles;

        _markers = [
          ..._checkpointMarkers,
          ..._busMarkers,
        ];
      });

      _mapController.move(points.first, 7);

      print("✅ ROUTE DIGAMBAR");
    } catch (e) {
      print("❌ DRAW ROUTE ERROR: $e");
    }
  }

  // =========================
  // FETCH ROUTE
  // =========================
  Future<List<LatLng>> fetchRoutePath(
    int routeId,
  ) async {
    try {
      final res = await http.get(
        Uri.parse(
          "${ApiService.baseUrl}/api/routes/$routeId",
        ),
      );

      final data = jsonDecode(res.body);

      if (data['success'] != true) {
        return [];
      }

      final path = data['data']['path'];

      return List.from(path).map((p) {
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
  // FETCH GEOFENCE
  // =========================
  Future<void> fetchGeofence(
    int routeId,
  ) async {
    try {
      final res = await http.get(
        Uri.parse(
          "${ApiService.baseUrl}/api/routes/$routeId/geofence",
        ),
      );

      final data = jsonDecode(res.body);

      if (data['success']) {
        List<dynamic> temp = [];

        if (data['terminal_awal'] != null) {
          temp.add({
            "name":
                data['terminal_awal']['nama_terminal'],
            "lat": data['terminal_awal']['lat'],
            "lng": data['terminal_awal']['lng'],
            "radius": 1000.0,
            "type": "terminal_awal",
          });
        }

        for (var cp in data['checkpoints']) {
          temp.add({
            "name": cp['nama'],
            "lat": cp['lat'],
            "lng": cp['lng'],
            "radius": 1000.0,
            "type": "checkpoint",
          });
        }

        if (data['terminal_tujuan'] != null) {
          temp.add({
            "name":
                data['terminal_tujuan']['nama_terminal'],
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

  Future<void> calculateETA({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final url =
          "https://router.project-osrm.org/route/v1/driving/"
          "$startLng,$startLat;$endLng,$endLat?overview=false";

      final response =
          await http.get(Uri.parse(url));

      final data = jsonDecode(response.body);

      if (data['routes'] != null &&
          data['routes'].isNotEmpty) {
        final route = data['routes'][0];

        setState(() {
          distance = route['distance'];
          duration = route['duration'];
        });
      }
    } catch (e) {
      print("ETA ERROR: $e");
    }
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

  Future<void> showNotification(
    String title,
    String body,
  ) async {
    const AndroidNotificationDetails
    androidDetails = AndroidNotificationDetails(
      'checkpoint_channel',
      'Checkpoint Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details =
        NotificationDetails(
      android: androidDetails,
    );

    await notificationsPlugin.show(
      0,
      title,
      body,
      details,
    );
  }

  void checkCheckpoint(
    double lat,
    double lng,
  ) {
    for (var checkpoint in geofenceData) {
      final inside = isInsideGeofence(
        busLat: lat,
        busLng: lng,
        checkpointLat: checkpoint['lat'],
        checkpointLng: checkpoint['lng'],
        radius: checkpoint['radius'],
      );

      final checkpointName = checkpoint['name'];

      if (inside &&
          !notifiedCheckpoints.contains(
            checkpointName,
          )) {
        notifiedCheckpoints.add(checkpointName);

        print(
          "✅ MASUK CHECKPOINT: $checkpointName",
        );

        showNotification(
          "Checkpoint",
          "Bus mendekati $checkpointName",
        );
      }
    }
  }

  @override
  void dispose() {
    realtimeTimer?.cancel();

    super.dispose();
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
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter:
              const LatLng(-7.9839, 112.6214),
          initialZoom: 6,
        ),
        children: [
          TileLayer(
            urlTemplate:
                "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          ),

          PolylineLayer(polylines: _polylines),

          CircleLayer(circles: _geofenceCircles),

          MarkerLayer(markers: _markers),
        ],
      ),
    );
  }
}