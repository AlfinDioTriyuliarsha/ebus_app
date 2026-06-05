import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

Future<void> saveFCMToken(int userId) async {

  try {

    String? token = await FirebaseMessaging.instance.getToken();

    print("FCM TOKEN:");
    print(token);

    if (token == null) return;

    await http.put(
      Uri.parse(
        "${ApiService.baseUrl}/api/users/save-fcm-token/$userId",
      ),

      headers: {
        "Content-Type": "application/json",
      },

      body: jsonEncode({
        "token": token,
      }),
    );

    print("TOKEN BERHASIL DISIMPAN");

  } catch (e) {

    print("ERROR SAVE TOKEN: $e");

  }
}