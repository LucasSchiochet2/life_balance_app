import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/report_model.dart';
import '../utils/background_service.dart';
import 'login_page.dart';
import 'add_bill_page.dart';
import 'cards_page.dart';
import 'workout_list_page.dart';
import '../components/CategoryChart.dart';
import '../components/SummaryCard.dart';
import '../components/MonthSelector.dart';
import '../components/GroupedBillList.dart';
class ReportPage extends StatefulWidget {
  final String token;
  final int userId;

  const ReportPage({super.key, required this.token, required this.userId});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  late Future<ReportResponse> futureReport;

  // Estados de Filtro
  int? touchedIndex;
  List<Map<String, dynamic>>? filteredBills; // Estrutura: [{ 'month': string, 'bills': List<Bill> }]
  bool isLoadingBills = false;
  int? selectedCategoryId;
  int selectedMonthIndex = 0;

  final List<Color> availableColors = const [
    Color(0xFF014040),
    Color(0xFF02735E),
    Color(0xFF03A678),
    Color(0xFFF27405),
    Color(0xFF7928F5),
  ];

  @override
  void initState() {
    super.initState();
    futureReport = fetchReport();
  }

  // --- API CALLS ---

  Future<ReportResponse> fetchReport() async {
    try {
      final response = await http.get(
        Uri.parse('https://finance-health-production.up.railway.app/api/bills/${widget.userId}'),
        // Uri.parse('http://finance-health.test/api/bills/${widget.userId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return ReportResponse.fromJson(decoded);
      }
      if (response.statusCode == 401) {
        // Token expirado ou inválido
        _logout();
      }
      throw Exception('Falha ao carregar relatório');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Remove token e userId
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  // Adicione o parâmetro String month
Future<void> fetchBillsByCategory(int categoryId, String month) async {
  setState(() {
    isLoadingBills = true;
    selectedCategoryId = categoryId;
    filteredBills = null; 
  });

  try {
    final url = 'https://finance-health-production.up.railway.app/api/bills/${widget.userId}/category/$categoryId?month=$month';
    // final url = 'http://finance-health.test/api/bills/${widget.userId}/category/$categoryId?month=$month';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      List<Map<String, dynamic>> groupedData = [];

      if (decoded is Map && decoded['data'] is List) {
        for (var monthItem in decoded['data']) {
          List<Bill> billsForThisMonth = (monthItem['bills'] as List)
              .map((i) => Bill.fromJson(i))
              .toList();

          groupedData.add({
            'month': monthItem['month'],
            'bills': billsForThisMonth,
          });
        }
      }
      setState(() => filteredBills = groupedData);
    }
  } catch (e) {
    print("Erro ao buscar contas: $e");
  } finally {
    if (mounted) setState(() => isLoadingBills = false);
  }
}
  // --- UI BUILDER ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Relatório Financeiro"),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: "Testar Notificações",
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text("Verificando contas vencendo..."))
              );
              bool hasNotification = await checkForBillsAndNotify();
              if (hasNotification) {
                 ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Notificações enviadas!"))
                 );
              } else {
                 ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Nenhuma conta para notificar."))
                 );
              }
            },
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
             DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: const Text('Cartões'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CardsPage(token: widget.token, userId: widget.userId)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.fitness_center),
              title: const Text('Treinos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WorkoutListPage(token: widget.token, userId: widget.userId)),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddBillPage(token: widget.token, userId: widget.userId)),
          );
          if (result == true) {
            setState(() {
              futureReport = fetchReport();
              filteredBills = null;
              selectedCategoryId = null;
            });
          }
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<ReportResponse>(
        future: futureReport,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return const Center(child: Text("Erro ao carregar dados."));
          if (!snapshot.hasData || snapshot.data!.data.isEmpty) return const Center(child: Text("Nenhum dado encontrado."));

          final reportResponse = snapshot.data!;
          final currentMonthData = reportResponse.data[selectedMonthIndex];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MonthSelector(
                  reports: reportResponse.data,
                  selectedIndex: selectedMonthIndex,
                  onSelected: (idx) => setState(() {
                    selectedMonthIndex = idx;
                    selectedCategoryId = null;
                    filteredBills = null;
                    touchedIndex = null;
                  }),
                ),
                const SizedBox(height: 16),
                SummaryCard(report: currentMonthData),
                const SizedBox(height: 30),
                const Text("Distribuição por Categoria", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                CategoryChart(
                    categories: currentMonthData.summaryByCategory,
                    touchedIndex: touchedIndex,
                    availableColors: availableColors, // Agora o nome bate com o 'final' lá do componente
                    onCategoryTap: (id, index) {
                      if (touchedIndex != index) {
                        setState(() => touchedIndex = index);
                        fetchBillsByCategory(id, currentMonthData.month);
                      }
                    },
                ),
                const Divider(height: 40),
                _buildListHeader(),
                const SizedBox(height: 10),
                isLoadingBills 
                  ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                  : GroupedBillList(
                      groupedBills: filteredBills,
                      monthlyBills: currentMonthData.bills,
                      onBillTap: (bill) => _showBillDetails(bill),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
  void _showBillDetails(Bill bill) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(bill.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Valor: R\$ ${bill.amount.toStringAsFixed(2)}"),
            Text("Vencimento: ${bill.dueDate}"),
            if (bill.category != null) Text("Categoria: ${bill.category!.name}"),
            if (bill.description.isNotEmpty) Text("Descrição: ${bill.description}"),
            const SizedBox(height: 10),
            Text("Status: ${bill.paid ? 'Pago' : 'Pendente'}", 
              style: TextStyle(color: bill.paid ? const Color(0xFF03A678) : const Color(0xFFF27405), fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _editBill(bill);
            }, 
            child: const Text("Editar")
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _confirmDelete(bill);
            }, 
            child: const Text("Excluir", style: TextStyle(color: Color(0xFFF27405))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Fechar"),
          ),
        ],
      ),
    );
  }

  Future<void> _editBill(Bill bill) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddBillPage(
          token: widget.token, 
          userId: widget.userId,
          billToEdit: bill,
        ),
      ),
    );
    if (result == true) {
      _refreshData();
    }
  }

  Future<void> _confirmDelete(Bill bill) async {

    if (bill.isRecurring || bill.isInstallment) {
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(bill.isInstallment ? "Excluir Parcelas" : "Excluir Recorrência"),
          content: Text("A conta '${bill.name}' é ${bill.isInstallment ? 'parcelada' : 'recorrente'}. O que deseja fazer?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'), 
              child: const Text("Cancelar")
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'single'), 
              child: const Text("Excluir apenas esta")
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'all'), 
              child: const Text("Excluir TODAS", style: TextStyle(color: Color(0xFFF27405)))
            ),
          ],
        ),
      );

      if (action == 'single') _deleteBill(bill.id, deleteAll: false);
      if (action == 'all') _deleteBill(bill.id, deleteAll: true);

    } else {
      // Exclusão normal
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Confirmar Exclusão"),
          content: Text("Deseja realmente excluir a conta '${bill.name}'?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Excluir", style: TextStyle(color: Color(0xFFF27405)))),
          ],
        ),
      );

      if (confirm == true) {
        _deleteBill(bill.id, deleteAll: false);
      }
    }
  }

  Future<void> _deleteBill(int billId, {bool deleteAll = false}) async {
    try {
      // final baseUrl = 'http://finance-health.test/api/bills/${widget.userId}/$billId';
      final baseUrl = 'https://finance-health-production.up.railway.app/api/bills/${widget.userId}/$billId';
      final url = deleteAll ? '$baseUrl?delete_all=true' : baseUrl;

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conta excluída com sucesso!')));
           _refreshData();
        }
      } else {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir: ${response.body}')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  void _refreshData() {
    setState(() {
      futureReport = fetchReport();
      // If we are seeing a filtered view, we should probably re-fetch that category too,
      // but simpler to just reset for now or let the user navigate again.
      // Or better: Re-fetch current selection if any.
      if (selectedCategoryId != null) {
          // Re-fetch category details if needed, or just clear filter
          // Clearing is safer to avoid state mismatch
          filteredBills = null;
          selectedCategoryId = null; 
      }
    });
  }

  Widget _buildListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          selectedCategoryId != null ? "Filtrado por Categoria" : "Contas do Mês",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (selectedCategoryId != null)
          TextButton(
            onPressed: () => setState(() {
              selectedCategoryId = null;
              filteredBills = null;
              touchedIndex = null;
            }),
            child: const Text("Limpar Filtro"),
          ),
      ],
    );
  }
}
class _BillTile extends StatelessWidget {
  final Bill bill;
  const _BillTile({required this.bill});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(bill.paid ? Icons.check_circle : Icons.pending, color: bill.paid ? Colors.green : Colors.orange),
        title: Text(bill.name),
        subtitle: Text(bill.dueDate.split(' ')[0]),
        trailing: Text("R\$ ${bill.amount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}