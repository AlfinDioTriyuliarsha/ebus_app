import 'package:flutter/material.dart';

class DriverDashboard extends StatelessWidget {
  final String email;
  final int userId;
  final int busId;

  const DriverDashboard({
    super.key,
    required this.email,
    required this.userId,
    required this.busId,
  });

  @override
  Widget build(BuildContext context) {
    // ❌ belum dapat bus
    if (busId == 0) {
      return Scaffold(
        appBar: AppBar(title: const Text("Driver Dashboard")),
        body: const Center(
          child: Text(
            "⚠️ Anda belum mendapat bus dari admin",
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    // ✅ sudah dapat bus
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Dashboard")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Email: $email"),
          Text("User ID: $userId"),
          Text("Bus ID: $busId"),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {
              // nanti bisa ke tracking / map
            },
            child: const Text("Mulai Jalan"),
          ),

          ElevatedButton(
            onPressed: () {
              // refresh manual
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => DriverDashboard(
                    email: email,
                    userId: userId,
                    busId: busId,
                  ),
                ),
              );
            },
            child: const Text("Refresh"),
          ),
        ],
      ),
    );
  }
}