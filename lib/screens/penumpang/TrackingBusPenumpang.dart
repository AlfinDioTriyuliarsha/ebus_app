import 'dart:async';
import 'dart:convert';

import 'package:ebus_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class TrackingBusPenumpang extends StatefulWidget {
  final int busId;

  const TrackingBusPenumpang({super.key, required this.busId});

  @override
  State<TrackingBusPenumpang> createState() => _TrackingBusPenumpangState();
}

class _TrackingBusPenumpangState extends State<TrackingBusPenumpang> {
  final MapController _mapController = MapController();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Set<String> notifiedGeofences = {};
  List<Map<String, dynamic>> geofenceData = [];

  Timer? realtimeTimer;

  LatLng? currentBusPosition;

  String platNomor = "-";
  String nomorBus = "-";

  bool isLoading = true;

  bool firstLoad = true;

  // ================= ROUTE =================
  List<LatLng> routePoints = [];
  List<Polyline> polylines = [];

  // ================= GEOFENCE =================
  List<CircleMarker> geofenceCircles = [];

  // ================= MARKERS =================
  List<Marker> checkpointMarkers = [];

  int? routeId;
  int? companyId;

  @override
  void initState() {
    super.initState();
    initNotification();

    requestNotificationPermission();

    loadTracking();

    Future.delayed(const Duration(seconds: 3), () {
      showGeofenceNotification("TEST NOTIF", "Notifikasi berhasil muncul");
    });
  }

  @override
  void dispose() {
    realtimeTimer?.cancel();

    super.dispose();
  }

  // ================= LOAD TRACKING =================
  Future<void> loadTracking() async {
    await fetchBus();

    print("BUS ID: ${widget.busId}");
    print("ROUTE ID: $routeId");
    print("COMPANY ID: $companyId");

    // ================= FETCH ROUTE =================
    if (routeId != null && companyId != null) {
      final points = await fetchRoutePath(routeId!, companyId!);

      print("TOTAL POINTS: ${points.length}");

      setState(() {
        routePoints = points;

        polylines = [
          Polyline(points: points, strokeWidth: 5, color: Colors.blue),
        ];
      });

      // ================= FETCH GEOFENCE =================
      await fetchGeofence(routeId!);

      // ================= FIT CAMERA =================
      if (points.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _mapController.fitCamera(
              CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(points),
                padding: const EdgeInsets.all(50),
              ),
            );
          }
        });
      }
    }

    // ================= REALTIME =================
    startRealtimeTracking();
  }

  // ================= FETCH BUS =================
  Future<void> fetchBus() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/api/buses"),
      );

      final data = jsonDecode(response.body);

      if (data['success']) {
        final buses = List.from(data['data']);

        final bus = buses.firstWhere((b) => b['id'] == widget.busId);

        final lat = double.tryParse(bus['latitude'].toString()) ?? 0;

        final lng = double.tryParse(bus['longitude'].toString()) ?? 0;

        setState(() {
          currentBusPosition = LatLng(lat, lng);

          platNomor = bus['plat_nomor'] ?? '-';

          nomorBus = bus['nomor_bus'] ?? '-';

          routeId = bus['route_id'];

          companyId = bus['company_id'];

          isLoading = false;
        });

        // ================= MOVE CAMERA =================
        if (firstLoad && currentBusPosition != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _mapController.move(currentBusPosition!, 15);
            }
          });

          firstLoad = false;
        }
      }
    } catch (e) {
      print("TRACKING ERROR: $e");
    }
  }

  // ================= FETCH ROUTE =================
  Future<List<LatLng>> fetchRoutePath(int routeId, int companyId) async {
    try {
      final res = await http.get(
        Uri.parse("${ApiService.baseUrl}/api/routes?company_id=$companyId"),
      );

      print("ROUTE STATUS: ${res.statusCode}");
      print("ROUTE BODY: ${res.body}");

      final data = jsonDecode(res.body);

      if (data['success'] != true) {
        print("❌ API ROUTE FAILED");
        return [];
      }

      final routes = List.from(data['data']);

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
        print("❌ PATH ROUTE KOSONG");
        return [];
      }

      final points = List.from(path).map<LatLng>((p) {
        return LatLng(
          double.parse(p['lat'].toString()),
          double.parse(p['lng'].toString()),
        );
      }).toList();

      print("✅ TOTAL ROUTE POINTS: ${points.length}");

      return points;
    } catch (e) {
      print("FETCH ROUTE ERROR: $e");
      return [];
    }
  }

  // ================= FETCH GEOFENCE =================
  Future<void> fetchGeofence(int routeId) async {
    try {
      final res = await http.get(
        Uri.parse("${ApiService.baseUrl}/api/routes/$routeId/geofence"),
      );

      print("GEOFENCE BODY: ${res.body}");

      final data = jsonDecode(res.body);

      List<CircleMarker> circles = [];

      List<Marker> markers = [];

      List<Map<String, dynamic>> tempGeofenceData = [];

      // ================= TERMINAL AWAL =================
      if (data['terminal_awal'] != null) {
        final lat = double.parse(data['terminal_awal']['lat'].toString());

        final lng = double.parse(data['terminal_awal']['lng'].toString());

        final point = LatLng(lat, lng);

        tempGeofenceData.add({"name": "Terminal Awal", "point": point});

        // CIRCLE
        circles.add(
          CircleMarker(
            point: point,
            radius: 1000,
            useRadiusInMeter: true,
            color: Colors.green.withOpacity(0.2),
            borderColor: Colors.green,
            borderStrokeWidth: 2,
          ),
        );

        // MARKER
        markers.add(
          Marker(
            point: point,
            width: 120,
            height: 80,

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, color: Colors.green, size: 35),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),

                  child: const Text(
                    "Terminal Awal",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // ================= CHECKPOINT =================
      for (var cp in data['checkpoints']) {
        final lat = double.parse(cp['lat'].toString());

        final lng = double.parse(cp['lng'].toString());

        final point = LatLng(lat, lng);

        tempGeofenceData.add({
          "name": cp['nama'] ?? 'Checkpoint',
          "point": point,
        });

        // CIRCLE
        circles.add(
          CircleMarker(
            point: point,
            radius: 1000,
            useRadiusInMeter: true,
            color: Colors.orange.withOpacity(0.2),
            borderColor: Colors.orange,
            borderStrokeWidth: 2,
          ),
        );

        // MARKER
        markers.add(
          Marker(
            point: point,
            width: 120,
            height: 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, color: Colors.orange, size: 35),

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
                    cp['nama'] ?? 'Checkpoint',
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
      }

      // ================= TERMINAL TUJUAN =================
      if (data['terminal_tujuan'] != null) {
        final lat = double.parse(data['terminal_tujuan']['lat'].toString());

        final lng = double.parse(data['terminal_tujuan']['lng'].toString());

        final point = LatLng(lat, lng);

        // ================= DATA NOTIFIKASI =================
        tempGeofenceData.add({"name": "Terminal Tujuan", "point": point});

        // CIRCLE
        circles.add(
          CircleMarker(
            point: point,
            radius: 1000,
            useRadiusInMeter: true,
            color: Colors.red.withOpacity(0.2),
            borderColor: Colors.red,
            borderStrokeWidth: 2,
          ),
        );

        // MARKER
        markers.add(
          Marker(
            point: point,
            width: 120,
            height: 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, color: Colors.red, size: 35),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),

                  child: const Text(
                    "Terminal Tujuan",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      setState(() {
        geofenceCircles = circles;

        checkpointMarkers = markers;

        geofenceData = tempGeofenceData;
      });
    } catch (e) {
      print("FETCH GEOFENCE ERROR: $e");
    }
  }

  // ================= INIT NOTIFICATION =================
  Future<void> initNotification() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(settings);
  }

  Future<void> requestNotificationPermission() async {
    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidImplementation?.requestNotificationsPermission();
  }

  Future<void> showGeofenceNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'geofence_channel',
          'Geofence Notifications',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  void checkGeofenceStatus() {
    if (currentBusPosition == null) return;

    final Distance distance = Distance();

    for (var geo in geofenceData) {
      final LatLng point = geo['point'];

      final String name = geo['name'];

      final meter = distance.as(LengthUnit.Meter, currentBusPosition!, point);

      if (meter <= 1000) {
        final id = "${point.latitude}-${point.longitude}";

        if (!notifiedGeofences.contains(id)) {
          notifiedGeofences.add(id);

          showGeofenceNotification("MASUK CHECKPOINT", name);

          print("✅ BUS MASUK: $name");
        }
      }
    }
  }

  // ================= REALTIME =================
  void startRealtimeTracking() {
    realtimeTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await fetchBus();
      checkGeofenceStatus();
    });
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          "Tracking Bus",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF001F3F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // ================= MAP =================
                FlutterMap(
                  mapController: _mapController,

                  options: MapOptions(
                    initialCenter:
                        currentBusPosition ?? const LatLng(-7.9839, 112.6214),

                    initialZoom: 15,
                  ),

                  children: [
                    // ================= TILE =================
                    TileLayer(
                      urlTemplate:
                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",

                      userAgentPackageName: 'com.example.ebus_app',
                    ),

                    // ================= GEOFENCE =================
                    CircleLayer(circles: geofenceCircles),

                    // ================= ROUTE =================
                    PolylineLayer(polylines: polylines),

                    // ================= CHECKPOINT MARKERS =================
                    MarkerLayer(markers: checkpointMarkers),

                    // ================= BUS MARKER =================
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: currentBusPosition!,

                          width: 100,
                          height: 100,

                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.directions_bus,
                                color: Colors.green,
                                size: 40,
                              ),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),

                                decoration: BoxDecoration(
                                  color: Colors.white,

                                  borderRadius: BorderRadius.circular(10),

                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),

                                      blurRadius: 5,
                                    ),
                                  ],
                                ),

                                child: Text(
                                  platNomor,

                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // ================= INFO CARD =================
                Positioned(
                  left: 15,
                  right: 15,
                  bottom: 20,

                  child: Container(
                    padding: const EdgeInsets.all(18),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.circular(20),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),

                    child: Column(
                      mainAxisSize: MainAxisSize.min,

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),

                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),

                                borderRadius: BorderRadius.circular(12),
                              ),

                              child: const Icon(
                                Icons.directions_bus,
                                color: Color(0xFF001F3F),
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  Text(
                                    nomorBus,

                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    platNomor,

                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        Row(
                          children: [
                            const Icon(
                              Icons.circle,
                              color: Colors.green,
                              size: 10,
                            ),

                            const SizedBox(width: 6),

                            const Text(
                              "Bus Sedang Berjalan",

                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Text(
                          "Jumlah Titik Rute : ${routePoints.length}",

                          style: TextStyle(color: Colors.grey.shade700),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          "Jumlah Geofence : ${geofenceCircles.length}",

                          style: TextStyle(color: Colors.grey.shade700),
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
