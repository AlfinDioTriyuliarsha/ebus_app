import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ebus_app/services/api_service.dart';

class ManajemenAgentPage extends StatefulWidget {
  final int companyId;
  const ManajemenAgentPage({super.key, required this.companyId});

  @override
  State<ManajemenAgentPage> createState() => _ManajemenAgentPageState();
}

class _ManajemenAgentPageState extends State<ManajemenAgentPage> {
  List<dynamic> _agents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAgents();
  }

  Future<void> _fetchAgents() async {
    try {
      final res = await http.get(
        Uri.parse(
          "${ApiService.baseUrl}/api/company/${widget.companyId}/agents",
        ),
      );
      if (res.statusCode == 200)
        // ignore: curly_braces_in_flow_control_structures
        setState(() {
          _agents = jsonDecode(res.body)['data'];
          _isLoading = false;
        });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manajemen Agent")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _agents.length,
              itemBuilder: (context, index) => ListTile(
                leading: const Icon(Icons.store),
                title: Text(_agents[index]['nama_agent']),
                subtitle: Text(_agents[index]['lokasi']),
                trailing: const Icon(Icons.edit),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
