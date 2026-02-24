import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/card_model.dart';
import 'add_card_page.dart';  // We will create this next
import 'login_page.dart'; // For logout if needed
import 'package:shared_preferences/shared_preferences.dart';

class CardsPage extends StatefulWidget {
  final String token;
  final int userId;

  const CardsPage({Key? key, required this.token, required this.userId}) : super(key: key);

  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> {
  List<CreditCard> cards = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCards();
  }

  Future<void> _fetchCards() async {
    setState(() => isLoading = true);
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
        // decoded structure: { "data": [...] }
        if (decoded is Map && decoded['data'] is List) {
           final List data = decoded['data'];
           setState(() {
             cards = data.map((json) => CreditCard.fromJson(json)).toList();
           });
        }
      } else if (response.statusCode == 401) {
         // Handle unauthorized
      }
    } catch (e) {
      print("Erro cards: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meus Cartões"),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddCardPage(token: widget.token, userId: widget.userId)
            ),
          );
          if (result == true) {
            _fetchCards();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : cards.isEmpty 
           ? const Center(child: Text("Nenhum cartão cadastrado."))
           : ListView.builder(
               padding: const EdgeInsets.all(16),
               itemCount: cards.length,
               itemBuilder: (context, index) {
                 return _CardItem(
                   card: cards[index],
                   token: widget.token,
                   userId: widget.userId,
                   onEditSuccess: _fetchCards,
                 );
               },
             ),
    );
  }
}

class _CardItem extends StatefulWidget {
  final CreditCard card;
  final String token;
  final int userId;
  final VoidCallback onEditSuccess;

  const _CardItem({
    Key? key, 
    required this.card,
    required this.token,
    required this.userId,
    required this.onEditSuccess,
  }) : super(key: key);

  @override
  State<_CardItem> createState() => _CardItemState();
}

class _CardItemState extends State<_CardItem> {
  bool _showAllInvoices = false;

  @override
  Widget build(BuildContext context) {
    final invoices = widget.card.invoices;
    // Take first 5 or all depending on state
    final visibleInvoices = _showAllInvoices 
        ? invoices 
        : invoices.take(5).toList();

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: const Icon(Icons.credit_card, size: 32, color: Color(0xFF02735E)),
        title: Text(widget.card.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Limite: R\$ ${widget.card.limit.toStringAsFixed(2)}"),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.edit, size: 18),
                label: const Text("Editar"),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddCardPage(
                        token: widget.token,
                        userId: widget.userId,
                        cardToEdit: widget.card,
                      ),
                    ),
                  );
                  if (result == true) {
                    widget.onEditSuccess();
                  }
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          if (invoices.isEmpty)
             const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Nenhuma fatura encontrada."),
             )
          else ...[
             ...visibleInvoices.map((invoice) {
                return ExpansionTile(
                  title: Text("Fatura: ${invoice.month}"),
                  subtitle: Text("Total: R\$ ${invoice.totalAmount.toStringAsFixed(2)} (${invoice.count} contas)"),
                  leading: const Icon(Icons.receipt_long, color: Color(0xFF014040)),
                  children: invoice.bills.map((bill) {
                    return ListTile(
                      contentPadding: const EdgeInsets.only(left: 32, right: 16),
                      title: Text(bill.name),
                      trailing: Text("R\$ ${bill.amount.toStringAsFixed(2)}"),
                    );
                  }).toList(),
                );
             }).toList(),
             
             if (invoices.length > 5)
               TextButton(
                 onPressed: () {
                   setState(() {
                     _showAllInvoices = !_showAllInvoices;
                   });
                 },
                 child: Text(_showAllInvoices ? "Ver menos" : "Ver mais (${invoices.length - 5} restantes)"),
               ),
          ]
        ],
      ),
    );
  }
}
