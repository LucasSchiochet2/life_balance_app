import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddCardPage extends StatefulWidget {
  final String token;
  final int userId;

  const AddCardPage({Key? key, required this.token, required this.userId}) : super(key: key);

  @override
  State<AddCardPage> createState() => _AddCardPageState();
}

class _AddCardPageState extends State<AddCardPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _limitController = TextEditingController();
  
  DateTime? _closingDate;
  DateTime? _expirationDate;
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context, bool isClosing) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isClosing) {
          _closingDate = picked;
        } else {
          _expirationDate = picked;
        }
      });
    }
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;
    if (_closingDate == null || _expirationDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione as datas.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Format as YYYY-MM-DD
      final closingStr = "${_closingDate!.year}-${_closingDate!.month.toString().padLeft(2, '0')}-${_closingDate!.day.toString().padLeft(2, '0')}";
      final expirationStr = "${_expirationDate!.year}-${_expirationDate!.month.toString().padLeft(2, '0')}-${_expirationDate!.day.toString().padLeft(2, '0')}";

      final response = await http.post(
        Uri.parse('https://finance-health-production.up.railway.app/api/cards/${widget.userId}'),
        // Uri.parse('http://finance-health.test/api/cards'), // Assuming this endpoint for creating cards
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'name': _nameController.text,
          'limit': double.tryParse(_limitController.text) ?? 0.0,
          'closing_day': closingStr, 
          'expiration_date': expirationStr,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context, true); // Return true to refresh list
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao salvar: ${response.body}')),
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
      appBar: AppBar(title: const Text("Novo Cartão")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Nome do Cartão"),
                validator: (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _limitController,
                decoration: const InputDecoration(labelText: "Limite (R\$)"),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v == null || v.isEmpty ? 'Informe o limite' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_closingDate == null 
                  ? "Selecionar Dia de Fechamento" 
                  : "Fechamento: ${_closingDate!.day}/${_closingDate!.month}/${_closingDate!.year}"),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, true),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_expirationDate == null 
                  ? "Selecionar Data de Vencimento" 
                  : "Vencimento: ${_expirationDate!.day}/${_expirationDate!.month}/${_expirationDate!.year}"),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, false),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveCard,
                child: _isLoading 
                  ? const CircularProgressIndicator() 
                  : const Text("Salvar Cartão"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
