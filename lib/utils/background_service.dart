import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

const String taskName = "checkBillsTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  if (kIsWeb) return;
  Workmanager().executeTask((task, inputData) async {
    if (task == taskName) {
      return await checkForBillsAndNotify();
    }
    return Future.value(true);
  });
}

Future<bool> checkForBillsAndNotify() async {
  if (kIsWeb) {
    print("Background service not supported on web");
    return false;
  }

  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    
    if (userId == null) {
      print("User ID not found in SharedPreferences");
      return Future.value(true);
    }

    print("Checking bills for user: $userId");
    final response = await http.get(
      Uri.parse('https://finance-health-production.up.railway.app/api/bills/$userId/notify'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> bills = jsonDecode(response.body);
      print("Bills to notify: ${bills.length}");
      
      if (bills.isNotEmpty) {
        final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
            FlutterLocalNotificationsPlugin();
        
        const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        
        const InitializationSettings initializationSettings = InitializationSettings(
          android: initializationSettingsAndroid,
        );

        await flutterLocalNotificationsPlugin.initialize(initializationSettings);

        for (var bill in bills) {
          String title = bill['description'] ?? 'Conta vencendo';
          String amount = bill['amount']?.toString() ?? '0.00';
          String dueDate = bill['due_date'] ?? 'Hoje';
          
          const AndroidNotificationDetails androidPlatformChannelSpecifics =
              AndroidNotificationDetails(
            'bill_channel_id',
            'Contas a Vencer',
            channelDescription: 'Notificações de contas próximas do vencimento',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: false,
          );
          
          const NotificationDetails platformChannelSpecifics =
              NotificationDetails(android: androidPlatformChannelSpecifics);

          await flutterLocalNotificationsPlugin.show(
            bill['id'] is int ? bill['id'] : DateTime.now().millisecond,
            'Conta Vencendo ($dueDate): $title',
            'Valor: R\$ $amount',
            platformChannelSpecifics,
          );
        }
      }
      return true;
    } else {
      print("Failed to fetch bills: ${response.statusCode}");
      return false;
    }
  } catch (e) {
    print("Error in background task: $e");
    return Future.value(false);
  }
}

