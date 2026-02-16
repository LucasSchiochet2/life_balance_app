import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import '../models/report_model.dart';
import 'add_bill_page.dart';

class ReportPage extends StatefulWidget {
  final String token; // Assuming authentication token is passed

  const ReportPage({super.key, required this.token});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  late Future<ReportResponse> futureReport; // Changed type

  // Filtros
  int? touchedIndex;
  List<Bill>? filteredBills;
  bool isLoadingBills = false;
  int? selectedCategoryId;
  
  // Month selection
  int selectedMonthIndex = 0; // Default to first (usually latest)

  final List<Color> availableColors = const [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
  ];

  @override
  void initState() {
    super.initState();
    futureReport = fetchReport();
  }

  Future<ReportResponse> fetchReport() async {
    try {
        final response = await http.get(
        // The endpoint likely changed to return the monthly list, or it's the same endpoint with changed response
        // User didn't specify URL change, so keeping it similar but assuming it returns the new structure
        Uri.parse('https://finance-health-production.up.railway.app/api/bills/1'), 
        headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
        },
        );

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          // Check if it's the new structure { data: [...] }
          if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
               return ReportResponse.fromJson(decoded);
          } else {
              // Fallback or unexpected format
              throw Exception('Unexpected JSON format');
          }
        } else {
          throw Exception('Failed to load report');
        }
    } catch (e) {
        print("Error fetching report: $e");
        rethrow;
    }
  }

  Future<void> fetchBillsByCategory(int categoryId) async {
    setState(() {
      isLoadingBills = true;
      selectedCategoryId = categoryId;
      filteredBills = null; // Clear previous filter while loading
    });

    try {
      final response = await http.get(
        Uri.parse('https://finance-health-production.up.railway.app/api/bills/1/category/$categoryId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          List<Bill> allBills = [];

          if (decoded is Map && decoded.containsKey('data') && decoded['data'] is List) {
            // New structure: { data: [ { month: '...', bills: [...] } ] }
            for (var monthData in decoded['data']) {
              if (monthData['bills'] is List) {
                allBills.addAll((monthData['bills'] as List).map((i) => Bill.fromJson(i)));
              }
            }
          }
          
          // Se não tiver bills dentro de data[], tenta a estrutura antiga
          if (allBills.isEmpty && decoded is Map && decoded.containsKey('data')) {
               if (decoded['data'] is List) {
                  // Pode ser lista direta de bills
                  try {
                    allBills = (decoded['data'] as List).map((i) => Bill.fromJson(i)).toList();
                  } catch (e) {
                    // Ignore, structure didn't match bill
                  }
               }
          }

          setState(() {
            filteredBills = allBills;
          });
      } else {
        _mockFilter(categoryId);
      }
    } catch (e) {
      print("Error fetching specific bills: $e");
      _mockFilter(categoryId);
    } finally {
      setState(() {
        isLoadingBills = false;
      });
    }
  }

  void _mockFilter(int categoryId) {
    // Caso a API falhe, não mostra nada ou exibe erro, 
    // pois o usuário pediu para usar o GET da API.
    // Se quiser manter comportamento de fallback, implemente aqui.
    setState(() {
        filteredBills = [];
    });
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Não foi possível buscar as contas desta categoria.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Relatório Financeiro")),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
            final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddBillPage(token: widget.token)),
            );
            if (result == true) {
                // Refresh data
                setState(() {
                    futureReport = fetchReport();
                    filteredBills = null;
                    selectedCategoryId = null;
                    touchedIndex = null;
                });
            }
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<ReportResponse>(
        future: futureReport,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // Simplified error handling
            return Center(child: Text('Erro ao carregar dados. Verifique sua conexão.'));
          } else if (snapshot.hasData) {
            final reportResponse = snapshot.data!;
            if (reportResponse.data.isEmpty) {
                return const Center(child: Text("Nenhum dado encontrado."));
            }

            // Get current month
            if (selectedMonthIndex >= reportResponse.data.length) {
                selectedMonthIndex = 0; // Reset if index out of bounds after refresh
            }
            final currentMonthData = reportResponse.data[selectedMonthIndex];
            final billsToShow = filteredBills ?? currentMonthData.bills;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Month Selector
                   if (reportResponse.data.length > 1) ...[
                   SingleChildScrollView(
                     scrollDirection: Axis.horizontal,
                     child: Row(
                       children: reportResponse.data.asMap().entries.map((entry) {
                         final idx = entry.key;
                         final report = entry.value;
                         final isSelected = idx == selectedMonthIndex;
                         return Padding(
                           padding: const EdgeInsets.only(right: 8.0),
                           child: ChoiceChip(
                             label: Text(report.month),
                             selected: isSelected,
                             onSelected: (selected) {
                               if (selected) {
                                  setState(() {
                                      selectedMonthIndex = idx;
                                      // Reset filters when changing month
                                      selectedCategoryId = null;
                                      filteredBills = null;
                                      touchedIndex = null;
                                  });
                               }
                             },
                           ),
                         );
                       }).toList(),
                     ),
                   ),
                   const SizedBox(height: 10),
                   ],

                  _buildSummaryCard(currentMonthData),
                  const SizedBox(height: 20),
                  const Text(
                    "Por Categoria (Toque no gráfico)",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  
                  // Pie Chart
                  if (currentMonthData.summaryByCategory.isNotEmpty) ...[
                  AspectRatio(
                    aspectRatio: 1.3,
                    child: Row(
                      children: [
                        const SizedBox(height: 18),
                        Expanded(child: AspectRatio(aspectRatio: 1, child: _buildPieChart(currentMonthData.summaryByCategory))),
                        const SizedBox(width: 28),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildIndicators(currentMonthData.summaryByCategory),
                  ] else 
                    const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("Sem dados de categoria neste mês"))),

                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                        Text(
                          selectedCategoryId != null ? "Contas Filtradas" : "Contas Recentes",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (selectedCategoryId != null)
                            TextButton(
                                onPressed: () {
                                    setState(() {
                                        selectedCategoryId = null;
                                        filteredBills = null;
                                        touchedIndex = null;
                                    });
                                },
                                child: const Text("Limpar Filtro")
                            )
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (isLoadingBills)
                    const Center(child: CircularProgressIndicator())
                  else
                    _buildBillsList(billsToShow),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
  
  Widget _buildPieChart(List<CategorySummary> categories) {
      return PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    pieTouchResponse == null ||
                    pieTouchResponse.touchedSection == null) {
                  return;
                }
                
                final index = pieTouchResponse.touchedSection!.touchedSectionIndex;
                
                if (index >= 0 && index < categories.length) {
                    // Only trigger if clicking a different section
                    if (touchedIndex != index) {
                         touchedIndex = index;
                         final categoryId = categories[index].categoryId;
                         fetchBillsByCategory(categoryId);
                    }
                }
              });
            },
          ),
          borderData: FlBorderData(show: false),
          sectionsSpace: 0,
          centerSpaceRadius: 40,
          sections: List.generate(categories.length, (i) {
            final isTouched = i == touchedIndex;
            final fontSize = isTouched ? 25.0 : 16.0;
            final radius = isTouched ? 60.0 : 50.0;
            final category = categories[i];
            
            // Assign a color based on index
            final color = availableColors[i % availableColors.length];
            
            return PieChartSectionData(
              color: color,
              value: category.percentage,
              title: '${category.percentage.toStringAsFixed(0)}%',
              radius: radius,
              titleStyle: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
              ),
            );
          }),
        ),
      );
  }

  Widget _buildIndicators(List<CategorySummary> categories) {
      return Column(
          children: List.generate(categories.length, (i) {
              final category = categories[i];
              final color = availableColors[i % availableColors.length];
              final isTouched = i == touchedIndex;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                    children: [
                        Container(
                            width: 16, height: 16,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(
                            category.categoryName,
                            style: TextStyle(
                                fontWeight: isTouched ? FontWeight.bold : FontWeight.normal,
                                fontSize: 16,
                            ),
                        ),
                        const Spacer(),
                        Text("R\$ ${category.totalAmount.toStringAsFixed(2)}")
                    ],
                ),
              );
          }),
      );
  }

  Widget _buildSummaryCard(MonthlyReport report) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Total Gasto (${report.month})", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              "R\$ ${report.totalAmount.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 8),
            Text("${report.totalCount} transações"),
          ],
        ),
      ),
    );
  }
  
  // Replaced _buildCategoryList with chart logic, so removing it.

  Widget _buildBillsList(List<Bill> bills) {
    if (bills.isEmpty) {
        return const Center(child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text("Nenhuma conta encontrada"),
        ));
    }

    return Column(
      children: bills.map((bill) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
                bill.paid ? Icons.check_circle : Icons.pending,
                color: bill.paid ? Colors.green : Colors.orange,
            ),
            title: Text(bill.name),
            subtitle: Text(bill.dueDate.split(' ')[0]), // Displaying date part
            trailing: Text(
              "R\$ ${bill.amount.toStringAsFixed(2)}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }
}
