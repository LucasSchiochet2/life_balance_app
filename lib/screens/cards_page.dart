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
                 final card = cards[index];
                 return Card(
                   elevation: 3,
                   margin: const EdgeInsets.only(bottom: 16),
                   child: ExpansionTile(
                     leading: const Icon(Icons.credit_card, size: 32, color: Color(0xFF02735E)),
                     title: Text(card.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                     subtitle: Text("Limite: R\$ ${card.limit.toStringAsFixed(2)}"),
                     children: [
                        if (card.invoices.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text("Nenhuma fatura encontrada."),
                          )
                        else
                          ...card.invoices.map((invoice) {
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
                          }).toList()
                     ],
                   ),
                 );
               },
             ),
    );
  }
}
