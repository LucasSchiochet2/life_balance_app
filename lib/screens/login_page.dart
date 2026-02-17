import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'register_page.dart';
import 'report_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> login() async {
    try {
      final response = await http.post(
        // Uri.parse('https://finance-health-production.up.railway.app/api/login'),
        Uri.parse('http://finance-health.test/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text,
          'password': passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        print("Login sucesso");
        // Tenta extrair o token se existir, ou usa um dummy para teste
        String token = "dummy_token";
        int userId = 1; // Default
        try {
          final body = jsonDecode(response.body);
          if (body is Map) {
            if (body.containsKey('token')) {
              token = body['token'];
            } else if (body.containsKey('access_token')) {
              token = body['access_token'];
            }

            if (body.containsKey('user') && body['user'] is Map && body['user'].containsKey('id')) {
               var id = body['user']['id'];
               if (id is int) {
                 userId = id;
               } else if (id is String) {
                 userId = int.tryParse(id) ?? 1;
               }
            }
          }
        } catch (e) {
          print("Erro ao parsear dados de login: $e");
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ReportPage(token: token, userId: userId)),
        );
      } else {
        print("Erro no login");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Falha no login")),
        );
      }
    } catch (e) {
      print("Erro de conexão: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro de conexão: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Senha"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: login,
              child: const Text("Entrar"),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RegisterPage()),
                );
              },
              child: const Text("Criar conta"),
            )
          ],
        ),
      ),
    );
  }
}
