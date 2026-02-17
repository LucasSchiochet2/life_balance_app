import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_page.dart';
import 'screens/report_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
