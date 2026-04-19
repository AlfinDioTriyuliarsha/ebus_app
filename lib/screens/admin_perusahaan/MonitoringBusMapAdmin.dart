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

  final Map<int, int> _busIndexTracker = {};
  // ignore: prefer_final_fields
  Map<Marker, Map<String, dynamic>> _markerBusMap = {};

  bool _isLoading = true;
  String? _error;
  Timer? _timer;

  final PopupController _popupController = PopupController();

  @override
  void initState() {
    super.initState();
    _fetchBusesByCompany();

    // Refresh tiap 2 detik biar gerak halus
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

  void _generateMarkersAndRoutes() {
    List<Marker> markers = [];

    for (var bus in _busData) {
      double lat = double.tryParse(bus['latitude']?.toString() ?? "0") ?? 0.0;
      double lng = double.tryParse(bus['longitude']?.toString() ?? "0") ?? 0.0;

      if (lat == 0.0 || lng == 0.0) continue;

      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 50,
          height: 50,
          child: Column(
            children: [
              const Icon(Icons.directions_bus, color: Colors.green, size: 35),
              Text(
                bus['plat_nomor'] ?? '',
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
      );

      // 🔥 GEOFENCING REAL
      final halte = [LatLng(-6.2000, 106.8166), LatLng(-7.9839, 112.6214)];

      for (var h in halte) {
        final distance = const Distance().as(
          LengthUnit.Meter,
          LatLng(lat, lng),
          h,
        );

        if (distance < 100) {
          debugPrint("🚨 Bus ${bus['plat_nomor']} masuk halte!");
        }
      }
    }

    setState(() {
      _busMarkers = markers;
      _busRoutes = []; // ❗ tidak pakai polyline lagi
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
            options: MapOptions(
              initialCenter: const LatLng(-7.9839, 112.6214),
              initialZoom: 6,
              onTap: (_, __) => _popupController.hideAllPopups(),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
              ),

              PolylineLayer(polylines: _busRoutes),

              PopupMarkerLayerWidget(
                options: PopupMarkerLayerOptions(
                  popupController: _popupController,
                  markers: _busMarkers,
                  popupDisplayOptions: PopupDisplayOptions(
                    builder: (context, marker) {
                      final bus = _markerBusMap[marker];

                      if (bus == null) return const SizedBox();

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "🚍 ${bus['plat_nomor'] ?? 'N/A'}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const Divider(),
                              Text("Driver: ${bus['driver_name'] ?? '-'}"),
                              Text("Status: ${bus['status'] ?? '-'}"),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          if (_error != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
