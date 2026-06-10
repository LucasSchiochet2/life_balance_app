import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/report_model.dart';
import '../utils/background_service.dart';
import 'login_page.dart';
import 'add_bill_page.dart';
import 'add_investment_page.dart';
import 'cards_page.dart';
import 'diet_page.dart';
import 'investment_goal_page.dart';
import 'workout_list_page.dart';
import 'profile_page.dart';
import '../components/CategoryChart.dart';
import '../components/SummaryCard.dart';
import '../components/MonthSelector.dart';
import '../components/GroupedBillList.dart';
import '../models/monthly_spend_model.dart';
import '../components/SalaryProgressBar.dart';
import '../utils/category_icons.dart';

class ReportPage extends StatefulWidget {
  final String token;
  final int userId;

  const ReportPage({super.key, required this.token, required this.userId});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  late Future<ReportResponse> futureReport;
  late Future<List<MonthlySpend>> futureMonthlySpend;
  bool _showInvestmentActions = false;
  int _selectedBillTypeIndex = 0;

  // Estados de Filtro
  int? touchedIndex;
  List<Map<String, dynamic>>?
  filteredBills; // Estrutura: [{ 'month': string, 'bills': List<Bill> }]
  bool isLoadingBills = false;
  int? selectedCategoryId;
  int selectedMonthIndex = 0;

  final List<Color> availableColors = const [
    Color(0xFFD81B60),
    Color(0xFFF06292),
    Color(0xFFAD1457),
    Color(0xFFF8BBD0),
    Color(0xFFC2185B),
    Color(0xFF880E4F),
    Color(0xFFE91E63),
  ];

  String get _selectedBillType =>
      _selectedBillTypeIndex == 0 ? 'fixa' : 'variavel';

  String get _selectedBillTypeTitle =>
      _selectedBillTypeIndex == 0 ? 'Contas Fixas' : 'Contas Variaveis';

  String get _selectedExpenseType =>
      _selectedBillTypeIndex == 0 ? 'despesas fixas' : 'despesas variaveis';

  @override
  void initState() {
    super.initState();
    futureReport = fetchReport();
    futureMonthlySpend = fetchMonthlySpend();
  }

  // --- API CALLS ---

  Future<List<MonthlySpend>> fetchMonthlySpend() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://finance-health-production.up.railway.app/api/monthly-spend/${widget.userId}',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          final List<dynamic> data = decoded['data'];
          return data.map((e) => MonthlySpend.fromJson(e)).toList();
        } else if (decoded is List) {
          return decoded.map((e) => MonthlySpend.fromJson(e)).toList();
        }
        return [];
      }
      return [];
    } catch (e) {
      debugPrint("Erro ao buscar monthly spend: $e");
      return [];
    }
  }

  Future<ReportResponse> fetchReport() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://finance-health-production.up.railway.app/api/bills/${widget.userId}',
        ).replace(queryParameters: {'bill_type': _selectedBillType}),
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
      final url = Uri.parse(
        'https://finance-health-production.up.railway.app/api/bills/${widget.userId}/category/$categoryId',
      ).replace(queryParameters: {'month': month, 'bill_type': _selectedBillType});
      // final url = 'http://finance-health.test/api/bills/${widget.userId}/category/$categoryId?month=$month';
      final response = await http.get(
        url,
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
                const SnackBar(content: Text("Verificando contas vencendo...")),
              );
              bool hasNotification = await checkForBillsAndNotify();
              if (hasNotification) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Notificações enviadas!")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Nenhuma conta para notificar."),
                  ),
                );
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 100, // Altura reduzida
              child: DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(16.0),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Menu',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
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
                  MaterialPageRoute(
                    builder: (context) =>
                        CardsPage(token: widget.token, userId: widget.userId),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.restaurant),
              title: const Text('Dieta'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DietPage(token: widget.token, userId: widget.userId),
                  ),
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
                  MaterialPageRoute(
                    builder: (context) => WorkoutListPage(
                      token: widget.token,
                      userId: widget.userId,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Meu Perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProfilePage(token: widget.token, userId: widget.userId),
                  ),
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
      floatingActionButton: _buildFloatingActions(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedBillTypeIndex,
        onDestinationSelected: _changeBillType,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.push_pin_outlined),
            selectedIcon: Icon(Icons.push_pin),
            label: 'Fixas',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_horiz),
            selectedIcon: Icon(Icons.swap_horizontal_circle),
            label: 'Variaveis',
          ),
        ],
      ),
      body: FutureBuilder<ReportResponse>(
        future: futureReport,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Erro ao carregar dados."));
          }
          if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
            return Center(
              child: Text("Nenhuma conta em $_selectedBillTypeTitle."),
            );
          }

          final reportResponse = snapshot.data!;
          final currentMonthIndex = selectedMonthIndex
              .clamp(0, reportResponse.data.length - 1)
              .toInt();
          final currentMonthData = reportResponse.data[currentMonthIndex];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBillTypeHeader(),
                const SizedBox(height: 16),
                MonthSelector(
                  reports: reportResponse.data,
                  selectedIndex: currentMonthIndex,
                  onSelected: (idx) => setState(() {
                    selectedMonthIndex = idx;
                    selectedCategoryId = null;
                    filteredBills = null;
                    touchedIndex = null;
                  }),
                ),
                const SizedBox(height: 16),
                SummaryCard(report: currentMonthData),
                const SizedBox(height: 20),
                _buildSpendingByCategorySection(currentMonthData),
                const SizedBox(height: 20),
                const Text(
                  "Distribuição por Categoria",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                CategoryChart(
                  categories: currentMonthData.summaryByCategory,
                  touchedIndex: touchedIndex,
                  availableColors:
                      availableColors, // Agora o nome bate com o 'final' lá do componente
                  onCategoryTap: (id, index) {
                    if (touchedIndex != index) {
                      setState(() => touchedIndex = index);
                      fetchBillsByCategory(id, currentMonthData.month);
                    }
                  },
                ),
                const SizedBox(height: 20),
                FutureBuilder<List<MonthlySpend>>(
                  future: futureMonthlySpend,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final spendList = snapshot.data!;

                    try {
                      // currentMonthData.month format example: "06/2026" or "2026-06"
                      int m = 0;
                      int y = 0;
                      if (currentMonthData.month.contains('/')) {
                        final parts = currentMonthData.month.split('/');
                        if (parts.length >= 2) {
                          m = int.tryParse(parts[0]) ?? 0;
                          y = int.tryParse(parts[1]) ?? 0;
                        }
                      } else if (currentMonthData.month.contains('-')) {
                        final parts = currentMonthData.month.split('-');
                        if (parts.length >= 2) {
                          y = int.tryParse(parts[0]) ?? 0;
                          m = int.tryParse(parts[1]) ?? 0;
                        }
                      }

                      if (m > 0 && y > 0) {
                        final match = spendList.firstWhere(
                          (s) => s.month == m && s.year == y,
                          orElse: () => MonthlySpend(
                            month: m,
                            year: y,
                            userSalary: 0,
                            debitExpensesCurrentMonth: 0,
                            creditCardInvoicePreviousMonth: 0,
                            totalSpendForMonth: 0,
                            spendPercentageOfSalary: "0%",
                          ),
                        );

                        if (match.userSalary > 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20.0),
                            child: SalaryProgressBar(monthlySpend: match),
                          );
                        }
                      }
                    } catch (e) {
                      debugPrint("Erro ao processar monthly spend display: $e");
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const Divider(height: 20),
                _buildListHeader(),
                const SizedBox(height: 10),
                isLoadingBills
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      )
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

  Widget _buildSpendingByCategorySection(MonthlyReport report) {
    if (report.summaryByCategory.isEmpty) {
      return _buildSpendingByCategoryCard(
        const Text("Nenhum gasto por categoria encontrado."),
      );
    }

    return _buildSpendingByCategoryCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${report.month} - Total: R\$ ${report.totalAmount.toStringAsFixed(2)} - ${report.totalCount} contas",
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ...report.summaryByCategory.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final color = availableColors[index % availableColors.length];
            final progress = (item.percentage / 100).clamp(0.0, 1.0).toDouble();

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.categoryName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        "R\$ ${item.totalAmount.toStringAsFixed(2)}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: const Color(0xFFFFE4EE),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${item.percentage.toStringAsFixed(2)}% - ${item.count} contas",
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBillTypeHeader() {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFFFFE4EE),
          foregroundColor: const Color(0xFFD81B60),
          child: Icon(
            _selectedBillTypeIndex == 0
                ? Icons.push_pin
                : Icons.swap_horizontal_circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _selectedBillTypeTitle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildSpendingByCategoryCard(Widget child) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Gastos por Categoria",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
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
            if (bill.category != null)
              Text("Categoria: ${bill.category!.name}"),
            Text("Tipo: ${_expenseTypeLabel(bill.categoryName)}"),
            if (bill.description.isNotEmpty)
              Text("Descrição: ${bill.description}"),
            const SizedBox(height: 10),
            Text(
              "Status: ${bill.paid ? 'Pago' : 'Pendente'}",
              style: TextStyle(
                color: bill.paid
                    ? const Color(0xFFD81B60)
                    : const Color(0xFFC2185B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _editBill(bill);
            },
            child: const Text("Editar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _confirmDelete(bill);
            },
            child: const Text(
              "Excluir",
              style: TextStyle(color: Color(0xFFC2185B)),
            ),
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

  String _expenseTypeLabel(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\u00e1\u00e0\u00e3\u00e2\u00e4]'), 'a')
        .replaceAll(RegExp(r'[\u00e9\u00e8\u00ea\u00eb]'), 'e')
        .replaceAll(RegExp(r'[\u00ed\u00ec\u00ee\u00ef]'), 'i')
        .replaceAll(RegExp(r'[\u00f3\u00f2\u00f5\u00f4\u00f6]'), 'o')
        .replaceAll(RegExp(r'[\u00fa\u00f9\u00fb\u00fc]'), 'u')
        .replaceAll(RegExp(r'[\u00e7]'), 'c');

    return normalized == 'despesas fixas'
        ? 'Despesas Fixas'
        : 'Despesas Variaveis';
  }

  Future<void> _confirmDelete(Bill bill) async {
    if (bill.isRecurring || bill.isInstallment) {
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            bill.isInstallment ? "Excluir Parcelas" : "Excluir Recorrência",
          ),
          content: Text(
            "A conta '${bill.name}' é ${bill.isInstallment ? 'parcelada' : 'recorrente'}. O que deseja fazer?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'single'),
              child: const Text("Excluir apenas esta"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'all'),
              child: const Text(
                "Excluir TODAS",
                style: TextStyle(color: Color(0xFFC2185B)),
              ),
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
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                "Excluir",
                style: TextStyle(color: Color(0xFFC2185B)),
              ),
            ),
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
      final baseUrl =
          'https://finance-health-production.up.railway.app/api/bills/${widget.userId}/$billId';
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Conta excluída com sucesso!')),
          );
          _refreshData();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir: ${response.body}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  void _refreshData() {
    setState(() {
      futureReport = fetchReport();
      futureMonthlySpend = fetchMonthlySpend();
      filteredBills = null;
      selectedCategoryId = null;
      touchedIndex = null;
    });
  }

  void _changeBillType(int index) {
    if (index == _selectedBillTypeIndex) return;

    setState(() {
      _selectedBillTypeIndex = index;
      selectedMonthIndex = 0;
      selectedCategoryId = null;
      filteredBills = null;
      touchedIndex = null;
      _showInvestmentActions = false;
      futureReport = fetchReport();
      futureMonthlySpend = fetchMonthlySpend();
    });
  }

  Future<void> _openAddBill() async {
    if (_showInvestmentActions) {
      setState(() => _showInvestmentActions = false);
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddBillPage(
          token: widget.token,
          userId: widget.userId,
          initialExpenseType: _selectedExpenseType,
        ),
      ),
    );

    if (result == true) {
      _refreshData();
    }
  }

  Future<void> _openAddInvestment() async {
    setState(() => _showInvestmentActions = false);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddInvestmentPage(token: widget.token, userId: widget.userId),
      ),
    );

    if (result == true) {
      _refreshData();
    }
  }

  Future<void> _openInvestmentGoal() async {
    setState(() => _showInvestmentActions = false);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            InvestmentGoalPage(token: widget.token, userId: widget.userId),
      ),
    );
  }

  Widget _buildFloatingActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _showInvestmentActions
              ? Column(
                  key: const ValueKey('investment-actions'),
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FloatingActionButton.extended(
                      heroTag: 'investment_goal_fab',
                      onPressed: _openInvestmentGoal,
                      icon: const Icon(Icons.flag),
                      label: const Text('Alterar meta'),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.extended(
                      heroTag: 'add_investment_fab',
                      onPressed: _openAddInvestment,
                      icon: const Icon(Icons.trending_up),
                      label: const Text('Adicionar investimento'),
                    ),
                    const SizedBox(height: 12),
                  ],
                )
              : const SizedBox.shrink(),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: 'investment_fab',
              tooltip: 'Investimentos',
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFD81B60),
              onPressed: () {
                setState(() {
                  _showInvestmentActions = !_showInvestmentActions;
                });
              },
              child: ClipOval(
                child: Image.asset(
                  'assets/icon/poupig.png',
                  width: 38,
                  height: 38,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            FloatingActionButton(
              heroTag: 'add_bill_fab',
              tooltip: 'Adicionar conta',
              onPressed: _openAddBill,
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          selectedCategoryId != null
              ? "Filtrado por Categoria"
              : "Contas do Mês",
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
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFFE4EE),
          foregroundColor: const Color(0xFFD81B60),
          child: Icon(billCategoryIcon(bill)),
        ),
        title: Text(bill.name),
        subtitle: Text(bill.dueDate.split(' ')[0]),
        trailing: Text(
          "R\$ ${bill.amount.toStringAsFixed(2)}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
