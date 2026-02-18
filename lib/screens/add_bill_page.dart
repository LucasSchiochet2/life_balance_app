import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/card_model.dart';
import '../models/report_model.dart';

class AddBillPage extends StatefulWidget {
  final String token;
  final int userId;
  final Bill? billToEdit;

  const AddBillPage({
    super.key, 
    required this.token, 
    required this.userId,
    this.billToEdit,
  });

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
  bool _notificationEnabled = false;
  int _selectedCategoryId = 1;
  
  String _selectedPaymentMethod = 'money'; // Default. Options: money, credit_card, debit_card
  int? _selectedCardId;
  List<CreditCard> _availableCards = [];

  final List<Map<String, dynamic>> _categories = [
    {'id': 1, 'name': 'Alimentação'},
    {'id': 2, 'name': 'Transporte'},
    {'id': 3, 'name': 'Lazer'},
    {'id': 4, 'name': 'Saúde'},
    {'id': 5, 'name': 'Educação'},
    {'id': 6, 'name': 'Moradia'},
    {'id': 7, 'name': 'Contas e Assinaturas'},
    {'id': 8, 'name': 'Outros'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchCards(); // Fetch cards for selection
    if (widget.billToEdit != null) {
      final bill = widget.billToEdit!;
      _nameController.text = bill.name;
      _amountController.text = bill.amount.toString();
      _dueDateController.text = bill.dueDate; 
      _descriptionController.text = bill.description;
      _selectedCategoryId = bill.categoryId;
      _isRecurring = bill.isRecurring;
      _isInstallment = bill.isInstallment;
      _notificationEnabled = bill.notificationEnabled;
      // Note: Payment details (credit card id etc) would populate here if available in Bill model
    }
  }

  Future<void> _fetchCards() async {
    try {
      final response = await http.get(
        Uri.parse('https://finance-health-production.up.railway.app/api/cards/${widget.userId}'),
        // Uri.parse('http://finance-health.test/api/cards/${widget.userId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['data'] is List) {
           final List data = decoded['data'];
           setState(() {
             _availableCards = data.map((json) => CreditCard.fromJson(json)).toList();
           });
        }
      }
    } catch (e) {
      print("Erro ao carregar cartões: $e");
    }
  }

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

    final isEditing = widget.billToEdit != null;
    bool updateAll = false;

    // Se estiver editando e for recorrente ou parcela
    if (isEditing && (widget.billToEdit!.isRecurring || widget.billToEdit!.isInstallment)) {
        final result = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(widget.billToEdit!.isInstallment ? "Atualizar Parcelas" : "Atualizar Recorrência"),
            content: Text("Esta conta é ${widget.billToEdit!.isInstallment ? 'parcelada' : 'recorrente'}. Como deseja salvar as alterações?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'cancel'),
                child: const Text("Cancelar")
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'single'),
                child: const Text("Apenas esta")
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'all'),
                child: const Text("Todas futuras")
              ),
            ],
          ),
        );

        if (result == 'cancel' || result == null) return;
        if (result == 'all') updateAll = true;
    }

    setState(() {
      _isLoading = true;
    });
    // final url = isEditing
    //     ? Uri.parse('http://finance-health.test/api/bills/${widget.userId}/${widget.billToEdit!.id}')
    //     : Uri.parse('http://finance-health.test/api/bills/${widget.userId}');
    final url = isEditing
        ? Uri.parse('https://finance-health-production.up.railway.app/api/bills/${widget.userId}/${widget.billToEdit!.id}')
        : Uri.parse('https://finance-health-production.up.railway.app/api/bills/${widget.userId}');

    try {
      final bodyMap = {
          'name': _nameController.text,
          'amount': double.tryParse(_amountController.text) ?? 0.0,
          'due_date': _dueDateController.text,
          'description': _descriptionController.text,
          'category_bill_id': _selectedCategoryId,
          'is_recurring': _isRecurring ? 1 : 0,
          'is_installment': _isInstallment ? 1 : 0,
          'notification_enabled': _notificationEnabled ? 1 : 0,
          'installment_count': _isInstallment ? int.tryParse(_installmentCountController.text) : null,
          'paid': isEditing ? (widget.billToEdit!.paid ? 1 : 0) : 0,
          'payment_method': _selectedPaymentMethod,
          'credit_card_id': _selectedPaymentMethod == 'credit_card' ? _selectedCardId : null,
          'user_id': widget.userId 
      };

      if (updateAll) {
        bodyMap['update_all'] = true;
      }

      final body = jsonEncode(bodyMap);

      final response = isEditing
          ? await http.put(
              url,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ${widget.token}',
              },
              body: body,
            )
          : await http.post(
              url,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ${widget.token}',
              },
              body: body,
            );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isEditing ? 'Conta atualizada!' : 'Conta adicionada com sucesso!')),
            );
            Navigator.pop(context, true); 
        }
      } else {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erro ao ${isEditing ? "atualizar" : "adicionar"}: ${response.body}')),
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
      appBar: AppBar(title: Text(widget.billToEdit != null ? "Editar Conta" : "Nova Conta")),
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
                      labelText: "Data de Vencimento / Compra",
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
                        // Format as YYYY-MM-DD
                        String formattedDate = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2,'0')}-${pickedDate.day.toString().padLeft(2,'0')}";
                          setState(() {
                             _dueDateController.text = formattedDate;
                          });
                      }
                  },
                  validator: (value) => value == null || value.isEmpty ? "Campo obrigatório" : null,
                ),
                
                const SizedBox(height: 10),

                // Payment Method Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedPaymentMethod,
                  decoration: const InputDecoration(labelText: "Método de Pagamento"),
                  items: const [
                    DropdownMenuItem(value: 'money', child: Text("Dinheiro / Débito / Pix")),
                    DropdownMenuItem(value: 'credit_card', child: Text("Cartão de Crédito")),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedPaymentMethod = val!;
                      // Reset recurrence/installment logic if needed based on payment type
                      if (val == 'credit_card') {
                         // Maybe default to single installment if not installment
                      }
                    });
                  },
                ),

                // Credit Card Selection (Only if credit_card)
                if (_selectedPaymentMethod == 'credit_card') 
                   Padding(
                     padding: const EdgeInsets.only(top: 10.0),
                     child: DropdownButtonFormField<int>(
                      value: _selectedCardId,
                      decoration: const InputDecoration(labelText: "Selecione o Cartão"),
                      items: _availableCards.map((card) {
                        return DropdownMenuItem<int>(
                          value: card.id,
                          child: Text("${card.name} (Lim: ${card.limit})"),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCardId = val;
                        });
                      },
                      validator: (val) => _selectedPaymentMethod == 'credit_card' && val == null ? 'Selecione um cartão' : null,
                                       ),
                   ),

                const SizedBox(height: 10),
            
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

                SwitchListTile(
                  title: const Text("Notificar Vencimento"),
                  value: _notificationEnabled,
                  onChanged: (val) {
                    setState(() {
                      _notificationEnabled = val;
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
