import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddBillPage extends StatefulWidget {
  final String token;

  const AddBillPage({super.key, required this.token});

  @override
  State<AddBillPage> createState() => _AddBillPageState();
}

class _AddBillPageState extends State<AddBillPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _descriptionController = TextEditingController(); 
  final _installmentCountController = TextEditingController();
  
  bool _isLoading = false;
  bool _isRecurring = false;
  bool _isInstallment = false;
  int _selectedCategoryId = 1;
  
  final List<Map<String, dynamic>> _categories = [
    {'id': 1, 'name': 'Alimentação'},
    {'id': 2, 'name': 'Transporte'},
    {'id': 3, 'name': 'Lazer'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _dueDateController.dispose();
    _descriptionController.dispose();
    _installmentCountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('http://finance-health.test/api/bills/1'); 

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'name': _nameController.text,
          'amount': double.tryParse(_amountController.text) ?? 0.0,
          'due_date': _dueDateController.text,
          'description': _descriptionController.text,
          'category_bill_id': _selectedCategoryId,
          'is_recurring': _isRecurring ? 1 : 0,
          'is_installment': _isInstallment ? 1 : 0,
          'installment_count': _isInstallment ? int.tryParse(_installmentCountController.text) : null,
          'paid': 0,
          'payment_method': 'credit_card',
          'user_id': 1 
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Conta adicionada com sucesso!')),
            );
            Navigator.pop(context, true); 
        }
      } else {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erro ao adicionar: ${response.body}')),
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
      appBar: AppBar(title: const Text("Nova Conta")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Nome da Conta"),
                  validator: (value) => value == null || value.isEmpty ? "Campo obrigatório" : null,
                ),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: "Valor (R\$)"),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => value == null || value.isEmpty ? "Campo obrigatório" : null,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: "Descrição (Opcional)"),
                ),
                TextFormField(
                  controller: _dueDateController,
                  decoration: const InputDecoration(
                      labelText: "Data de Vencimento",
                      suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101)
                      );
                      if(pickedDate != null ){
                          String formattedDate = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2,'0')}-${pickedDate.day.toString().padLeft(2,'0')}";
                          setState(() {
                             _dueDateController.text = formattedDate;
                          });
                      }
                  },
                  validator: (value) => value == null || value.isEmpty ? "Campo obrigatório" : null,
                ),
            
                DropdownButtonFormField<int>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(labelText: "Categoria"),
                  items: _categories.map((cat) {
                    return DropdownMenuItem<int>(
                      value: cat['id'],
                      child: Text(cat['name']),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCategoryId = val!;
                    });
                  },
                ),
                
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text("Conta Recorrente (Mensal)"),
                  value: _isRecurring,
                  onChanged: (val) {
                    setState(() {
                      _isRecurring = val;
                      if (val) _isInstallment = false; // Usually mutually exclusive or handled differently
                    });
                  },
                ),

                SwitchListTile(
                  title: const Text("Parcelamento"),
                  value: _isInstallment,
                  onChanged: (val) {
                    setState(() {
                      _isInstallment = val;
                      if (val) _isRecurring = false;
                    });
                  },
                ),

                if (_isInstallment)
                  TextFormField(
                    controller: _installmentCountController,
                    decoration: const InputDecoration(labelText: "Número de Parcelas"),
                    keyboardType: TextInputType.number,
                    validator: (value) => _isInstallment && (value == null || value.isEmpty) 
                        ? "Informe o número de parcelas" 
                        : null,
                  ),

                if (_isInstallment)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      "Nota: O valor informado acima será considerado o valor de cada parcela.",
                      style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  ),


                const SizedBox(height: 20),
                _isLoading 
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submit,
                      child: const Text("Salvar Conta"),
                    )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
