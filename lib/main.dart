import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'dart:io' show Platform;
import 'utils/background_service.dart';
import 'screens/login_page.dart';
import 'screens/report_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await Workmanager().initialize(
      callbackDispatcher, 
      isInDebugMode: true 
    );
    
    await Workmanager().registerPeriodicTask(
      "1", 
      taskName, 
      frequency: const Duration(hours: 24),
    );
  }

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  final userId = prefs.getInt('userId');

  runApp(MyApp(
    initialRoute: (token != null && userId != null)
        ? ReportPage(token: token, userId: userId)
        : const LoginPage(),
  ));
}

class MyApp extends StatelessWidget {
  final Widget initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD81B60),
          primary: const Color(0xFFD81B60),
          onPrimary: Colors.white,
          secondary: const Color(0xFFF06292),
          onSecondary: Colors.white,
          tertiary: const Color(0xFFAD1457),
          error: const Color(0xFFC2185B),
          surface: Colors.white,
          onSurface: const Color(0xFF4A102A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFD81B60),
          foregroundColor: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF0F6),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD81B60),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: initialRoute,
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Life Balance App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Resumo Financeiro',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text('Total gasto este mês: R\$ 0,00'),
            SizedBox(height: 10),
            Text('Total de contas pendentes: 0'),
          ],
        ),
      ),

    );
  }
}
