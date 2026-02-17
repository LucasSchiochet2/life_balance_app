import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/workout_model.dart'; // Assume created

class CreateExercisePage extends StatefulWidget {
  final int userId;
  final String token;
  final Exercise? exerciseToEdit;

  const CreateExercisePage({
    super.key, 
    required this.userId, 
    required this.token,
    this.exerciseToEdit,
  });

  @override
  State<CreateExercisePage> createState() => _CreateExercisePageState();
}

class _CreateExercisePageState extends State<CreateExercisePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _muscleGroupController = TextEditingController();
  final _photoUrlController = TextEditingController(); // Optional
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.exerciseToEdit != null) {
      final e = widget.exerciseToEdit!;
      _nameController.text = e.name;
      _descriptionController.text = e.description;
      _muscleGroupController.text = e.muscleGroup;
      _photoUrlController.text = e.photoUrl ?? '';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final isEditing = widget.exerciseToEdit != null;
    final url = isEditing
      ? Uri.parse('https://finance-health-production.up.railway.app/api/exercises/${widget.userId}/${widget.exerciseToEdit!.id}')
      : Uri.parse('https://finance-health-production.up.railway.app/api/exercises/${widget.userId}');

    try {
      final body = jsonEncode({
          'name': _nameController.text,
          'description': _descriptionController.text,
          'muscle_group': _muscleGroupController.text,
          'photo_url': _photoUrlController.text.isNotEmpty ? _photoUrlController.text : null,
      });
      
      http.Response response;
      if (isEditing) {
        response = await http.put(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
          body: body,
        );
      } else {
        response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
          body: body,
        );
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pop(context, true); // Return success
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar exercício: ${response.body}')),
        );
      }
    } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro de conexão: $e')),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.exerciseToEdit != null ? 'Editar Exercício' : 'Novo Exercício')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome do Exercício'),
                validator: (value) => value == null || value.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _muscleGroupController,
                decoration: const InputDecoration(labelText: 'Grupo Muscular (ex: Peito)'),
                validator: (value) => value == null || value.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _photoUrlController,
                decoration: const InputDecoration(labelText: 'URL da Foto (Opcional)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
