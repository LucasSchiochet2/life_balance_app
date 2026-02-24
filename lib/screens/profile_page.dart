import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class ProfilePage extends StatefulWidget {
  final String token;
  final int userId;

  const ProfilePage({Key? key, required this.token, required this.userId}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _salaryController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isFetching = true;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    setState(() => _isFetching = true);
    try {
      final response = await http.get(
        Uri.parse('https://finance-health-production.up.railway.app/api/user/${widget.userId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        // Assuming the API returns the user object directly or wrappers in 'data'
        final userData = decoded is Map && decoded.containsKey('data') ? decoded['data'] : decoded;
        
        final user = User.fromJson(userData);
        _nameController.text = user.name;
        _emailController.text = user.email;
        _salaryController.text = user.salary.toString();
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao carregar perfil: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro de conexão: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> body = {
        'name': _nameController.text,
        'email': _emailController.text,
        'salary': double.tryParse(_salaryController.text) ?? 0.0,
      };

      if (_currentPasswordController.text.isNotEmpty || _newPasswordController.text.isNotEmpty) {
         if (_newPasswordController.text != _confirmPasswordController.text) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('A nova senha e a confirmação não conferem.')),
            );
            setState(() => _isLoading = false);
            return;
         }
         if (_currentPasswordController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Informe a senha atual para alterar a senha.')),
            );
            setState(() => _isLoading = false);
            return;
         }
         body['current_password'] = _currentPasswordController.text;
         body['password'] = _newPasswordController.text;
         body['password_confirmation'] = _confirmPasswordController.text;
      }

      final response = await http.put(
        Uri.parse('https://finance-health-production.up.railway.app/api/user/${widget.userId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil atualizado com sucesso!')),
          );
          // Clear password fields on success
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        }
      } else {
        if (mounted) {
          final errorMsg = jsonDecode(response.body)['message'] ?? 'Erro desconhecido';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao atualizar: $errorMsg')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Meu Perfil")),
      body: _isFetching 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Informações Pessoais", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: "Nome"),
                    validator: (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: "Email"),
                    validator: (v) => v == null || v.isEmpty ? 'Informe o email' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _salaryController,
                    decoration: const InputDecoration(labelText: "Salário Mensal (R\$)"),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => v == null || v.isEmpty ? 'Informe o salário' : null,
                  ),
                  const SizedBox(height: 32),
                  const Text("Alterar Senha", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("Preencha apenas se desejar alterar sua senha.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _currentPasswordController,
                    decoration: const InputDecoration(labelText: "Senha Atual"),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _newPasswordController,
                    decoration: const InputDecoration(labelText: "Nova Senha"),
                    obscureText: true,
                    validator: (v) {
                       if (v != null && v.isNotEmpty && v.length < 8) {
                         return 'A senha deve ter no mínimo 8 caracteres';
                       }
                       return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: const InputDecoration(labelText: "Confirmar Nova Senha"),
                    obscureText: true,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Salvar Alterações"),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
