import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ebus_app/services/api_service.dart';

class DriverRequestPage extends StatefulWidget {
  const DriverRequestPage({super.key});

  @override
  State<DriverRequestPage> createState() => _DriverRequestPageState();
}

class _DriverRequestPageState extends State<DriverRequestPage> {
  List requests = [];
  List buses = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final reqRes = await http.get(
      Uri.parse("${ApiService.baseUrl}/api/driver-request"),
    );

    final busRes = await http.get(
      Uri.parse("${ApiService.baseUrl}/api/buses"),
    );

    setState(() {
      requests = jsonDecode(reqRes.body)['data'];
      buses = jsonDecode(busRes.body)['data'];
    });
  }

  Future<void> approve(int requestId, int busId) async {
    await http.put(
      Uri.parse("${ApiService.baseUrl}/api/driver-request/approve/$requestId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"bus_id": busId}),
    );

    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Request Driver")),
      body: ListView.builder(
        itemCount: requests.length,
        itemBuilder: (context, i) {
          final r = requests[i];

          return Card(
            child: ListTile(
              title: Text(r['driver_name']),
              trailing: DropdownButton<int>(
                hint: Text("Pilih Bus"),
                items: buses.map<DropdownMenuItem<int>>((b) {
                  return DropdownMenuItem(
                    value: b['id'],
                    child: Text(b['plat_nomor']),
                  );
                }).toList(),
                onChanged: (busId) {
                  if (busId != null) {
                    approve(r['id'], busId);
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}