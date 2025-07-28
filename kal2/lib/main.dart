import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kalkulator Wymiarów',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class GlassItem {
  int thickness;
  int length;
  int width;
  int quantity;
  double m2PerPiece;
  double totalM2;
  double weight;
  double cost;

  GlassItem({
    this.thickness = 0,
    this.length = 0,
    this.width = 0,
    this.quantity = 1,
    this.m2PerPiece = 0,
    this.totalM2 = 0,
    this.weight = 0,
    this.cost = 0,
  });

  void calculate(double costPerTon) {
    m2PerPiece = (length * width) / 1000000;
    totalM2 = m2PerPiece * quantity;
    weight = 2.5 * thickness * totalM2;
    // Poprawka: waga w kg * koszt za tonę / 1000 / 2.5
    cost = (weight * costPerTon) / 1000 / 2.5;
  }

  Map<String, dynamic> toJson() => {
    'thickness': thickness,
    'length': length,
    'width': width,
    'quantity': quantity,
    'm2PerPiece': m2PerPiece,
    'totalM2': totalM2,
    'weight': weight,
    'cost': cost,
  };

  factory GlassItem.fromJson(Map<String, dynamic> json) => GlassItem(
    thickness: json['thickness'] ?? 0,
    length: json['length'] ?? 0,
    width: json['width'] ?? 0,
    quantity: json['quantity'] ?? 1,
    m2PerPiece: json['m2PerPiece'] ?? 0,
    totalM2: json['totalM2'] ?? 0,
    weight: json['weight'] ?? 0,
    cost: json['cost'] ?? 0,
  );
}

class CompanyData {
  String companyName = '';
  String clientName = '';
  String additionalNotes = '';
  String serviceType = 'Hartowanie szkła';
  String currentNumber = DateFormat('dd-MM-yyyy').format(DateTime.now());
  String issueDate = DateFormat('dd-MM-yyyy').format(DateTime.now());

  CompanyData();

  Map<String, dynamic> toJson() => {
    'companyName': companyName,
    'clientName': clientName,
    'additionalNotes': additionalNotes,
    'serviceType': serviceType,
    'currentNumber': currentNumber,
    'issueDate': issueDate,
  };

  factory CompanyData.fromJson(Map<String, dynamic> json) {
    var data = CompanyData();
    data.companyName = json['companyName'] ?? '';
    data.clientName = json['clientName'] ?? '';
    data.additionalNotes = json['additionalNotes'] ?? '';
    data.serviceType = json['serviceType'] ?? 'Hartowanie szkła';
    data.currentNumber = json['currentNumber'] ?? DateFormat('dd-MM-yyyy').format(DateTime.now());
    data.issueDate = json['issueDate'] ?? DateFormat('dd-MM-yyyy').format(DateTime.now());
    return data;
  }
}

class Project {
  String id;
  String name;
  DateTime createdAt;
  DateTime updatedAt;
  List<GlassItem> items;
  double costPerTon;
  CompanyData companyData;

  Project({
    String? id,
    required this.name,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<GlassItem>? items,
    this.costPerTon = 6000.0,
    CompanyData? companyData,
  }) : 
    id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now(),
    items = items ?? [],
    companyData = companyData ?? CompanyData();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'items': items.map((item) => item.toJson()).toList(),
    'costPerTon': costPerTon,
    'companyData': companyData.toJson(),
  };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'],
    name: json['name'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    items: (json['items'] as List).map((item) => GlassItem.fromJson(item)).toList(),
    costPerTon: json['costPerTon'] ?? 6000.0,
    companyData: CompanyData.fromJson(json['companyData'] ?? {}),
  );
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<GlassItem> items = [];
  double costPerTon = 6000.0;
  CompanyData companyData = CompanyData();
  Timer? _autoSaveTimer;
  Project? currentProject;
  List<Project> projectHistory = [];

  // Dodaj kontroler do nazwy projektu
  final TextEditingController _projectNameController = TextEditingController();

  String pdfSavePath = '';
  final TextEditingController _pdfPathController = TextEditingController();

  double _tableScale = 1.0;

  // Nawigacja klawiaturą - śledzenie aktualnej pozycji
  int _currentRow = 0;
  int _currentColumn = 0; // 0: grubość, 1: długość, 2: szerokość, 3: ilość
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this); // 6 zakładek
    _loadData();
    _startAutoSave();
    _loadPdfPath();
  }

  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _saveCurrentProject();
    });
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load current project
    String? currentProjectJson = prefs.getString('current_project');
    if (currentProjectJson != null) {
      currentProject = Project.fromJson(json.decode(currentProjectJson));
      setState(() {
        items = currentProject!.items;
        costPerTon = currentProject!.costPerTon;
        companyData = currentProject!.companyData;
      });
    } else {
      currentProject = Project(name: 'Nowy projekt');
    }

    // Load project history
    String? historyJson = prefs.getString('project_history');
    if (historyJson != null) {
      List<dynamic> historyList = json.decode(historyJson);
      projectHistory = historyList.map((item) => Project.fromJson(item)).toList();
    }
  }

  Future<void> _saveCurrentProject() async {
    if (currentProject == null) return;
    
    currentProject!.items = items;
    currentProject!.costPerTon = costPerTon;
    currentProject!.companyData = companyData;
    currentProject!.updatedAt = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_project', json.encode(currentProject!.toJson()));

    // Update history
    int existingIndex = projectHistory.indexWhere((p) => p.id == currentProject!.id);
    if (existingIndex != -1) {
      projectHistory[existingIndex] = currentProject!;
    } else {
      projectHistory.insert(0, currentProject!);
    }

    // Keep only last 50 projects
    if (projectHistory.length > 50) {
      projectHistory = projectHistory.sublist(0, 50);
    }

    await prefs.setString('project_history', json.encode(
      projectHistory.map((p) => p.toJson()).toList()
    ));
  }

  void _addItem() {
    setState(() {
      items.add(GlassItem());
    });
    _saveCurrentProject();
  }

  void _removeItem(int index) {
    setState(() {
      items.removeAt(index);
    });
    _saveCurrentProject();
  }

  void _updateItem(int index, GlassItem item) {
    setState(() {
      items[index] = item;
      items[index].calculate(costPerTon);
    });
    _saveCurrentProject();
  }

  Map<int, List<GlassItem>> _groupByThickness() {
    Map<int, List<GlassItem>> grouped = {};
    for (var item in items) {
      if (!grouped.containsKey(item.thickness)) {
        grouped[item.thickness] = [];
      }
      grouped[item.thickness]!.add(item);
    }
    return grouped;
  }

  double _getTotalM2() {
    return items.fold(0.0, (sum, item) => sum + item.totalM2);
  }

  double _getTotalWeight() {
    return items.fold(0.0, (sum, item) => sum + item.weight);
  }

  double _getTotalCost() {
    return items.fold(0.0, (sum, item) => sum + item.cost);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _saveCurrentProject();
    _tabController.dispose();
    
    // Zwolnij kontrolery i focus nodes
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    
    super.dispose();
  }

  // Dodaj funkcję do tworzenia nowego projektu
  void _createNewProject() async {
    String? newName = await showDialog<String>(
      context: context,
      builder: (context) {
        _projectNameController.text = '';
        return AlertDialog(
          title: const Text('Nowy projekt'),
          content: TextField(
            controller: _projectNameController,
            decoration: const InputDecoration(labelText: 'Nazwa projektu'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(_projectNameController.text.trim()),
              child: const Text('Utwórz'),
            ),
          ],
        );
      },
    );
    if (newName != null && newName.isNotEmpty) {
      setState(() {
        currentProject = Project(name: newName);
        items = [];
        costPerTon = 6000.0;
        companyData = CompanyData();
      });
      await _saveCurrentProject();
    }
  }

  // Dodaj funkcję do zmiany nazwy projektu
  void _renameProject() async {
    String? newName = await showDialog<String>(
      context: context,
      builder: (context) {
        _projectNameController.text = currentProject?.name ?? '';
        return AlertDialog(
          title: const Text('Zmień nazwę projektu'),
          content: TextField(
            controller: _projectNameController,
            decoration: const InputDecoration(labelText: 'Nazwa projektu'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(_projectNameController.text.trim()),
              child: const Text('Zmień'),
            ),
          ],
        );
      },
    );
    if (newName != null && newName.isNotEmpty && currentProject != null) {
      setState(() {
        currentProject!.name = newName;
      });
      await _saveCurrentProject();
    }
  }

  Future<void> _loadPdfPath() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      pdfSavePath = prefs.getString('pdf_save_path') ?? '';
      _pdfPathController.text = pdfSavePath;
    });
  }

  Future<void> _savePdfPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pdf_save_path', path);
    setState(() {
      pdfSavePath = path;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2FA), // jaśniejsze tło
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        title: Row(
          children: [
            Expanded(child: Text(currentProject?.name ?? 'Kalkulator wymiarów', style: const TextStyle(color: Colors.black))),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.black54),
              tooltip: 'Zmień nazwę projektu',
              onPressed: _renameProject,
            ),
            IconButton(
              icon: const Icon(Icons.add_box_outlined, color: Colors.black54),
              tooltip: 'Nowy projekt',
              onPressed: _createNewProject,
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.deepPurple,
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.deepPurple,
          tabs: const [
            Tab(text: 'Pozycje'),
            Tab(text: 'Podsumowanie'),
            Tab(text: 'Koszt hartowania'),
            Tab(text: 'Dane'),
            Tab(text: 'Historia'),
            Tab(icon: Icon(Icons.settings), text: 'Ustawienia'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMainTab(),
          _buildSummaryTab(),
          _buildCostTab(),
          _buildDataTab(),
          _buildHistoryTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildMainTab() {
    return Focus(
      autofocus: true,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
          _addItem();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Column(
        children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add, color: Colors.deepPurple),
                label: const Text('Wstaw pozycję', style: TextStyle(color: Colors.deepPurple)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.deepPurple),
                  elevation: 0,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _clearAllItems,
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: const Text('Wyczyść wszystko', style: TextStyle(color: Colors.red)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.red),
                  elevation: 0,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.zoom_out, color: Colors.deepPurple),
                tooltip: 'Oddal tabelę',
                onPressed: () {
                  setState(() {
                    _tableScale = (_tableScale - 0.1).clamp(0.6, 2.0);
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in, color: Colors.deepPurple),
                tooltip: 'Powiększ tabelę',
                onPressed: () {
                  setState(() {
                    _tableScale = (_tableScale + 0.1).clamp(0.6, 2.0);
                  });
                },
              ),
              ElevatedButton.icon(
                onPressed: _generateExcel,
                icon: const Icon(Icons.table_chart, color: Colors.white),
                label: const Text('Eksportuj do Excel', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  elevation: 0,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _generatePDF,
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text('Zapisz PDF', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: Transform.scale(
                scale: _tableScale,
                alignment: Alignment.topLeft,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFE5E5EA)),
                  dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                    (states) => states.contains(WidgetState.selected) ? Colors.deepPurple[50] : null,
                  ),
                  columns: const [
                    DataColumn(label: Text('Lp')),
                    DataColumn(label: Text('Grubość')),
                    DataColumn(label: Text('Długość')),
                    DataColumn(label: Text('Szerokość')),
                    DataColumn(label: Text('Ilość')),
                    DataColumn(label: Text('m²/szt')),
                    DataColumn(label: Text('m²')),
                    DataColumn(label: Text('waga [kg]')),
                    DataColumn(label: Text('Koszt [zł]')),
                    DataColumn(label: Text('Akcje')),
                  ],
                  rows: items.asMap().entries.map((entry) {
                    int index = entry.key;
                    GlassItem item = entry.value;
                    return DataRow(
                      cells: [
                        DataCell(Text('${index + 1}')),
                        DataCell(_buildEditableCell(item.thickness.toString(), (value) {
                          item.thickness = int.tryParse(value) ?? 0;
                          _updateItem(index, item);
                        }, index, 0)),
                        DataCell(_buildEditableCell(item.length.toString(), (value) {
                          item.length = int.tryParse(value) ?? 0;
                          _updateItem(index, item);
                        }, index, 1)),
                        DataCell(_buildEditableCell(item.width.toString(), (value) {
                          item.width = int.tryParse(value) ?? 0;
                          _updateItem(index, item);
                        }, index, 2)),
                        DataCell(_buildEditableCell(item.quantity.toString(), (value) {
                          item.quantity = int.tryParse(value) ?? 1;
                          _updateItem(index, item);
                        }, index, 3)),
                        DataCell(Text(item.m2PerPiece.toStringAsFixed(3))),
                        DataCell(Text(item.totalM2.toStringAsFixed(3))),
                        DataCell(Text(item.weight.toStringAsFixed(2))),
                        DataCell(Text(item.cost.toStringAsFixed(2))),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeItem(index),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFFE5E5EA),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('Suma m²: ${_getTotalM2().toStringAsFixed(3)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Suma waga: ${_getTotalWeight().toStringAsFixed(2)} kg', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Suma koszt: ${_getTotalCost().toStringAsFixed(2)} zł', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
      ),
    );
  }

  void _clearAllItems() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potwierdź'),
        content: const Text('Czy na pewno chcesz usunąć wszystkie pozycje?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Wyczyść'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        items.clear();
      });
      _saveCurrentProject();
    }
  }

  Widget _buildEditableCell(String value, Function(String) onChanged, int row, int column) {
    final String cellKey = '${row}_$column';
    
    // Utwórz lub pobierz kontroler dla tej komórki
    if (!_controllers.containsKey(cellKey)) {
      _controllers[cellKey] = TextEditingController(text: value);
      _focusNodes[cellKey] = FocusNode();
    } else {
      _controllers[cellKey]!.text = value;
    }
    
    _controllers[cellKey]!.selection = TextSelection.collapsed(offset: value.length);
    
    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          // Usunięto obsługę klawisza space z tej lokalizacji
          // bo jest już obsługiwana globalnie w Focus widget
          
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _moveToCell(row - 1, column);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _moveToCell(row + 1, column);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _moveToCell(row, column - 1);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _moveToCell(row, column + 1);
          }
        }
      },
      child: TextField(
        controller: _controllers[cellKey],
        focusNode: _focusNodes[cellKey],
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }

  void _moveToCell(int row, int column) {
    // Sprawdź granice
    if (row < 0 || row >= items.length || column < 0 || column > 3) {
      return;
    }
    
    setState(() {
      _currentRow = row;
      _currentColumn = column;
    });
    
    final String cellKey = '${row}_$column';
    if (_focusNodes.containsKey(cellKey)) {
      _focusNodes[cellKey]!.requestFocus();
    }
  }

  Widget _buildSummaryTab() {
    Map<int, List<GlassItem>> grouped = _groupByThickness();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Podsumowanie', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
            columns: const [
              DataColumn(label: Text('Lp')),
              DataColumn(label: Text('Szyby')),
              DataColumn(label: Text('Ilość')),
              DataColumn(label: Text('m²/szt')),
              DataColumn(label: Text('m²')),
              DataColumn(label: Text('waga [kg]')),
            ],
            rows: grouped.entries.map((entry) {
              int thickness = entry.key;
              List<GlassItem> thicknessItems = entry.value;
              
              int totalQuantity = thicknessItems.fold(0, (sum, item) => sum + item.quantity);
              double totalM2 = thicknessItems.fold(0.0, (sum, item) => sum + item.totalM2);
              double avgM2PerPiece = totalQuantity > 0 ? totalM2 / totalQuantity : 0;
              double totalWeight = thicknessItems.fold(0.0, (sum, item) => sum + item.weight);
              
              return DataRow(cells: [
                DataCell(Text('${grouped.keys.toList().indexOf(thickness) + 1}')),
                DataCell(Text('Grubość $thickness')),
                DataCell(Text('$totalQuantity')),
                DataCell(Text(avgM2PerPiece.toStringAsFixed(3))),
                DataCell(Text(totalM2.toStringAsFixed(3))),
                DataCell(Text(totalWeight.toStringAsFixed(2))),
              ]);
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Dodaj automatyczny zapis po zmianie kosztu
  Widget _buildCostTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Koszt hartowania', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: TextEditingController(text: costPerTon.toStringAsFixed(2)),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Koszt za tonę (zł)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    onChanged: (value) {
                      setState(() {
                        costPerTon = double.tryParse(value) ?? 6000.0;
                        for (int i = 0; i < items.length; i++) {
                          items[i].calculate(costPerTon);
                        }
                      });
                      _saveCurrentProject();
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ten koszt jest używany do obliczania kosztu każdej pozycji',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Dodaj automatyczny zapis po zmianie danych firmy
  Widget _buildDataTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dane firmy', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Usunięto pole "Nazwa Twojej firmy"
          TextField(
            controller: TextEditingController(text: companyData.clientName),
            decoration: const InputDecoration(
              labelText: 'Firma klienta',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              companyData.clientName = value;
              _saveCurrentProject();
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: TextEditingController(text: companyData.serviceType),
            decoration: const InputDecoration(
              labelText: 'Typ usługi',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              companyData.serviceType = value;
              _saveCurrentProject();
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: TextEditingController(text: companyData.currentNumber),
            decoration: const InputDecoration(
              labelText: 'Numer bieżący',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              companyData.currentNumber = value;
              _saveCurrentProject();
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: TextEditingController(text: companyData.issueDate),
            decoration: const InputDecoration(
              labelText: 'Data wystawienia',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              companyData.issueDate = value;
              _saveCurrentProject();
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: TextEditingController(text: companyData.additionalNotes),
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Dodatkowe uwagi',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              companyData.additionalNotes = value;
              _saveCurrentProject();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _generateExcel() async {
    try {
      // Tworzymy nowy workbook
      final excel = Excel.createExcel();
      final Sheet sheet = excel['Arkusz1'];

      // Ustawiamy wysokość pierwszych wierszy
      sheet.setRowHeight(0, 20);
      sheet.setRowHeight(1, 20);
      sheet.setRowHeight(2, 20);
      sheet.setRowHeight(3, 20);
      sheet.setRowHeight(4, 20);
      sheet.setRowHeight(5, 20);
      sheet.setRowHeight(6, 20);

      // NAGŁÓWEK - ROW 0-6
      // Dane sprzedawcy (kolumny A-C)
      sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Różycki GLASS');
      sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue('Grzegorz Różycki');
      sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue('Stare Miasto 515');
      sheet.cell(CellIndex.indexByString('A4')).value = TextCellValue('37-300 Leżajsk');
      sheet.cell(CellIndex.indexByString('A5')).value = TextCellValue('tel. 604 595 378');

      // Dane klienta (kolumny D-E)
      sheet.cell(CellIndex.indexByString('D1')).value = TextCellValue('HARTOWNIA');
      sheet.cell(CellIndex.indexByString('D2')).value = TextCellValue('SZKŁA ul.');
      sheet.cell(CellIndex.indexByString('D3')).value = TextCellValue('Budowlana 2');
      sheet.cell(CellIndex.indexByString('D4')).value = TextCellValue('08-500 Ryki');
      sheet.cell(CellIndex.indexByString('D6')).value = TextCellValue(companyData.clientName);

      // Dane dokumentu (kolumny F-I)
      sheet.cell(CellIndex.indexByString('H1')).value = TextCellValue('Numer bieżący');
      sheet.cell(CellIndex.indexByString('H2')).value = TextCellValue('Data wystawienia');
      sheet.cell(CellIndex.indexByString('I1')).value = TextCellValue(companyData.currentNumber);
      sheet.cell(CellIndex.indexByString('I2')).value = TextCellValue(companyData.issueDate);

      // WZ
      sheet.cell(CellIndex.indexByString('G1')).value = TextCellValue('WZ');
      sheet.cell(CellIndex.indexByString('G3')).value = TextCellValue('wydanie');
      sheet.cell(CellIndex.indexByString('G4')).value = TextCellValue('zewnętrzne');

      // Wiersz 8 - Opis usługi
      sheet.cell(CellIndex.indexByString('A8')).value = TextCellValue('Różycki glass - usługa ${companyData.serviceType.toLowerCase()}');

      // TABELA GŁÓWNA - zaczynamy od wiersza 10
      final int headerRow = 9; // wiersz 10 w Excelu (0-based)
      
      // Nagłówki tabeli
      sheet.cell(CellIndex.indexByString('A${headerRow + 1}')).value = TextCellValue('Lp');
      sheet.cell(CellIndex.indexByString('B${headerRow + 1}')).value = TextCellValue('Grubość');
      sheet.cell(CellIndex.indexByString('C${headerRow + 1}')).value = TextCellValue('Długość');
      sheet.cell(CellIndex.indexByString('D${headerRow + 1}')).value = TextCellValue('Szerokość');
      sheet.cell(CellIndex.indexByString('E${headerRow + 1}')).value = TextCellValue('Ilość');
      sheet.cell(CellIndex.indexByString('F${headerRow + 1}')).value = TextCellValue('m²/szt');
      sheet.cell(CellIndex.indexByString('G${headerRow + 1}')).value = TextCellValue('m²');
      sheet.cell(CellIndex.indexByString('H${headerRow + 1}')).value = TextCellValue('waga [kg]');

      // Dane tabeli
      for (int i = 0; i < items.length; i++) {
        final int row = headerRow + 2 + i; // wiersz danych
        final item = items[i];
        
        sheet.cell(CellIndex.indexByString('A$row')).value = IntCellValue(i + 1);
        sheet.cell(CellIndex.indexByString('B$row')).value = IntCellValue(item.thickness);
        sheet.cell(CellIndex.indexByString('C$row')).value = IntCellValue(item.length);
        sheet.cell(CellIndex.indexByString('D$row')).value = IntCellValue(item.width);
        sheet.cell(CellIndex.indexByString('E$row')).value = IntCellValue(item.quantity);
        // Ograniczenie do maksymalnie 3 miejsc po przecinku
        sheet.cell(CellIndex.indexByString('F$row')).value = DoubleCellValue(double.parse(item.m2PerPiece.toStringAsFixed(3)));
        sheet.cell(CellIndex.indexByString('G$row')).value = DoubleCellValue(double.parse(item.totalM2.toStringAsFixed(3)));
        sheet.cell(CellIndex.indexByString('H$row')).value = DoubleCellValue(double.parse(item.weight.toStringAsFixed(3)));
      }

      // Wiersz podsumowania
      final int summaryRow = headerRow + 2 + items.length;
      final totalQty = items.fold<int>(0, (sum, item) => sum + item.quantity);
      final totalM2 = _getTotalM2();
      final totalWeight = _getTotalWeight();

      sheet.cell(CellIndex.indexByString('D$summaryRow')).value = TextCellValue('SUMA:');
      sheet.cell(CellIndex.indexByString('E$summaryRow')).value = IntCellValue(totalQty);
      // Ograniczenie do maksymalnie 3 miejsc po przecinku w podsumowaniu
      sheet.cell(CellIndex.indexByString('G$summaryRow')).value = DoubleCellValue(double.parse(totalM2.toStringAsFixed(3)));
      sheet.cell(CellIndex.indexByString('H$summaryRow')).value = DoubleCellValue(double.parse(totalWeight.toStringAsFixed(3)));

      // Formatowanie - pogrubienia dla nagłówków
      final boldStyle = CellStyle(
        fontFamily: getFontFamily(FontFamily.Arial),
        bold: true,
      );

      // STYLIZACJA ARKUSZA
      _formatExcelSheet(sheet, headerRow, items.length, boldStyle);

      // Pogrub nagłówki tabeli
      for (int col = 0; col < 8; col++) {
        final cellAddress = String.fromCharCode(65 + col) + '${headerRow + 1}';
        sheet.cell(CellIndex.indexByString(cellAddress)).cellStyle = boldStyle;
      }

      // Pogrub wiersz podsumowania
      sheet.cell(CellIndex.indexByString('D$summaryRow')).cellStyle = boldStyle;
      sheet.cell(CellIndex.indexByString('E$summaryRow')).cellStyle = boldStyle;
      sheet.cell(CellIndex.indexByString('G$summaryRow')).cellStyle = boldStyle;
      sheet.cell(CellIndex.indexByString('H$summaryRow')).cellStyle = boldStyle;

      // Pogrub dane firmy
      sheet.cell(CellIndex.indexByString('A1')).cellStyle = boldStyle;
      sheet.cell(CellIndex.indexByString('A2')).cellStyle = boldStyle;

      // Zapisywanie pliku
      // Używamy tej samej logiki nazwy i ścieżki co w PDF
      String client = (companyData.clientName.isNotEmpty ? companyData.clientName : "Firma")
          .replaceAll(RegExp(r'[\\/:*?"<>|\r\n\t]'), '_')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      String date = companyData.issueDate
          .replaceAll(RegExp(r'[\\/:*?"<>|\r\n\t]'), '_')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      String fileName = "$client-$date-excel.xlsx";

      // Używamy tej samej ścieżki co PDF
      String savePath = pdfSavePath.isNotEmpty
          ? pdfSavePath
          : (await getDefaultSavePath());

      // Upewnij się, że ścieżka istnieje
      final dir = Directory(savePath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final file = File('$savePath/$fileName');
      
      final bytes = excel.encode();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Plik Excel zapisany: $savePath/$fileName'),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                onPressed: () {},
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd podczas tworzenia pliku Excel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _formatExcelSheet(Sheet sheet, int headerRow, int itemsCount, CellStyle boldStyle) {
    // 1. SEKCJA NAGŁÓWKA GŁÓWNEGO (Wiersze 1-4)
    
    // Dane Sprzedawcy (Lewa strona, Kolumny A-C)
    sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('C1'));
    sheet.merge(CellIndex.indexByString('A2'), CellIndex.indexByString('C2'));
    sheet.merge(CellIndex.indexByString('A3'), CellIndex.indexByString('C3'));
    sheet.merge(CellIndex.indexByString('A4'), CellIndex.indexByString('C4'));
    
    // Stylizacja danych sprzedawcy - pogrubienie
    sheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Arial),
      bold: true,
    );
    sheet.cell(CellIndex.indexByString('A2')).cellStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Arial),
      bold: true,
    );
    
    // Dane Klienta (Środek, Kolumny E-F)
    sheet.merge(CellIndex.indexByString('E2'), CellIndex.indexByString('F2'));
    sheet.merge(CellIndex.indexByString('E3'), CellIndex.indexByString('F3'));

    // 2. GŁÓWNY TYTUŁ TABELI (Wiersz 8)
    final titleRowIndex = 8; // wiersz 8 (1-based)
    sheet.merge(CellIndex.indexByString('A$titleRowIndex'), CellIndex.indexByString('H$titleRowIndex'));
    
    final titleStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Arial),
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#F2F2F2'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    
    sheet.cell(CellIndex.indexByString('A$titleRowIndex')).cellStyle = titleStyle;

    // 3. NAGŁÓWKI KOLUMN TABELI (Wiersz headerRow + 1)
    final headerStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Arial),
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#D9D9D9'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    
    // Zastosuj style do nagłówków kolumn
    for (int col = 0; col < 8; col++) {
      final cellAddress = String.fromCharCode(65 + col) + '${headerRow + 1}';
      sheet.cell(CellIndex.indexByString(cellAddress)).cellStyle = headerStyle;
    }

    // 4. WIERSZE Z DANYMI (od wiersza headerRow + 2)
    final dataCenterStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Arial),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    
    final dataRightStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Arial),
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );
    
    // Stylizacja wierszy z danymi
    for (int i = 0; i < itemsCount; i++) {
      final int row = headerRow + 2 + i;
      
      // Kolumny A-E (Lp, Grubość, Długość, Szerokość, Ilość) - na środek
      for (int col = 0; col < 5; col++) {
        final cellAddress = String.fromCharCode(65 + col) + '$row';
        sheet.cell(CellIndex.indexByString(cellAddress)).cellStyle = dataCenterStyle;
      }
      
      // Kolumny F-H (m²/szt, m², waga) - do prawej
      for (int col = 5; col < 8; col++) {
        final cellAddress = String.fromCharCode(65 + col) + '$row';
        sheet.cell(CellIndex.indexByString(cellAddress)).cellStyle = dataRightStyle;
      }
    }

    // 5. WIERSZ PODSUMOWANIA (Ostatni wiersz tabeli)
    final summaryRow = headerRow + 2 + itemsCount;
    
    // Scal komórki A-D w wierszu podsumowania
    sheet.merge(CellIndex.indexByString('A$summaryRow'), CellIndex.indexByString('D$summaryRow'));
    
    final summaryMergedStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Arial),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    
    sheet.cell(CellIndex.indexByString('A$summaryRow')).cellStyle = summaryMergedStyle;
    
    // Style dla komórek sum (E, G, H)
    final summaryStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Arial),
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#E2EFDA'),
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );
    
    sheet.cell(CellIndex.indexByString('E$summaryRow')).cellStyle = summaryStyle; // Ilość
    sheet.cell(CellIndex.indexByString('G$summaryRow')).cellStyle = summaryStyle; // m²
    sheet.cell(CellIndex.indexByString('H$summaryRow')).cellStyle = summaryStyle; // waga

    // 6. SZEROKOŚĆ KOLUMN
    sheet.setColumnWidth(0, 5);   // Kolumna A (Lp)
    sheet.setColumnWidth(1, 10);  // Kolumna B (Grubość)
    sheet.setColumnWidth(2, 12);  // Kolumna C (Długość)
    sheet.setColumnWidth(3, 12);  // Kolumna D (Szerokość)
    sheet.setColumnWidth(4, 8);   // Kolumna E (Ilość)
    sheet.setColumnWidth(5, 15);  // Kolumna F (m²/szt)
    sheet.setColumnWidth(6, 15);  // Kolumna G (m²)
    sheet.setColumnWidth(7, 15);  // Kolumna H (waga [kg])
  }

  Future<void> _generatePDF() async {
    final fontData = await rootBundle.load('assets/fonts/DejaVuSans.ttf');
    final ttf = pw.Font.ttf(fontData);

    final pdf = pw.Document();

    final totalQty = items.fold<int>(0, (sum, item) => sum + item.quantity);
    final totalM2 = _getTotalM2();
    final totalWeight = _getTotalWeight();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          // GÓRNA TABELA - pierwsza kolumna statyczna, druga dynamiczna z zakładki "Firma klienta"
          pw.Table(
            border: pw.TableBorder.all(width: 1),
            columnWidths: {
              0: pw.FlexColumnWidth(2.2),
              1: pw.FlexColumnWidth(2.2),
              2: pw.FlexColumnWidth(1.5),
              3: pw.FlexColumnWidth(1.2),
              4: pw.FlexColumnWidth(2.2),
            },
            children: [
              pw.TableRow(
                children: [
                  // Statyczne dane Różycki GLASS
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Różycki GLASS', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 11)),
                        pw.Text('Grzegorz Różycki', style: pw.TextStyle(font: ttf, fontSize: 10)),
                        pw.Text('Stare Miasto 515', style: pw.TextStyle(font: ttf, fontSize: 10)),
                        pw.Text('37-300 Leżajsk', style: pw.TextStyle(font: ttf, fontSize: 10)),
                        pw.Text('tel. 604 595 378', style: pw.TextStyle(font: ttf, fontSize: 10)),
                      ],
                    ),
                  ),
                  // Dynamiczne dane firmy klienta
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      companyData.clientName.isNotEmpty
                          ? companyData.clientName
                          : 'Firma klienta',
                      style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    alignment: pw.Alignment.center,
                    child: pw.Text('Dodatkowe Uwagi', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    alignment: pw.Alignment.center,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text('WZ', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        pw.Text('wydanie', style: pw.TextStyle(font: ttf, fontSize: 10)),
                        pw.Text('zewnętrzne', style: pw.TextStyle(font: ttf, fontSize: 10)),
                      ],
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Numer bieżący', style: pw.TextStyle(font: ttf, fontSize: 10)),
                        pw.Text(companyData.currentNumber, style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        pw.Text('Data wystawienia', style: pw.TextStyle(font: ttf, fontSize: 10)),
                        pw.Text('${companyData.issueDate}r.', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text('Różycki glass - usługa hartownia', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 11)),
          pw.SizedBox(height: 8),

          // Tabela główna
          pw.Table(
            border: pw.TableBorder.all(width: 1),
            columnWidths: {
              0: pw.FixedColumnWidth(22),
              1: pw.FixedColumnWidth(38),
              2: pw.FixedColumnWidth(50),
              3: pw.FixedColumnWidth(50),
              4: pw.FixedColumnWidth(32),
              5: pw.FixedColumnWidth(45),
              6: pw.FixedColumnWidth(45),
              7: pw.FixedColumnWidth(55),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Container(padding: const pw.EdgeInsets.all(4), child: pw.Text('Lp', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Container(padding: const pw.EdgeInsets.all(4), child: pw.Text('Grubość', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Container(padding: const pw.EdgeInsets.all(4), child: pw.Text('Długość', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Container(padding: const pw.EdgeInsets.all(4), child: pw.Text('Szerokość', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Container(padding: const pw.EdgeInsets.all(4), child: pw.Text('Ilość', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Container(padding: const pw.EdgeInsets.all(4), child: pw.Text('m²/szt', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Container(padding: const pw.EdgeInsets.all(4), child: pw.Text('m²', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Container(padding: const pw.EdgeInsets.all(4), child: pw.Text('waga [kg]', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 9))),
                ],
              ),
              ...items.asMap().entries.map((entry) {
                int index = entry.key;
                GlassItem item = entry.value;
                return pw.TableRow(
                  children: [
                    pw.Container(padding: const pw.EdgeInsets.all(3), alignment: pw.Alignment.center, child: pw.Text('${index + 1}', style: pw.TextStyle(font: ttf, fontSize: 9))),
                    pw.Container(padding: const pw.EdgeInsets.all(3), alignment: pw.Alignment.center, child: pw.Text('${item.thickness}', style: pw.TextStyle(font: ttf, fontSize: 9))),
                    pw.Container(padding: const pw.EdgeInsets.all(3), alignment: pw.Alignment.center, child: pw.Text('${item.length}', style: pw.TextStyle(font: ttf, fontSize: 9))),
                    pw.Container(padding: const pw.EdgeInsets.all(3), alignment: pw.Alignment.center, child: pw.Text('${item.width}', style: pw.TextStyle(font: ttf, fontSize: 9))),
                    pw.Container(padding: const pw.EdgeInsets.all(3), alignment: pw.Alignment.center, child: pw.Text('${item.quantity}', style: pw.TextStyle(font: ttf, fontSize: 9))),
                    pw.Container(padding: const pw.EdgeInsets.all(3), alignment: pw.Alignment.center, child: pw.Text(item.m2PerPiece.toStringAsFixed(3), style: pw.TextStyle(font: ttf, fontSize: 9))),
                    pw.Container(padding: const pw.EdgeInsets.all(3), alignment: pw.Alignment.center, child: pw.Text(item.totalM2.toStringAsFixed(3), style: pw.TextStyle(font: ttf, fontSize: 9))),
                    pw.Container(padding: const pw.EdgeInsets.all(3), alignment: pw.Alignment.center, child: pw.Text('${item.weight.toStringAsFixed(2)} kg', style: pw.TextStyle(font: ttf, fontSize: 9))),
                  ],
                );
              }).toList(),
              // Suma: tylko komórki z sumami mają zielone tło
              pw.TableRow(
                children: [
                  pw.Container(),
                  pw.Container(),
                  pw.Container(),
                  pw.Container(),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(3),
                    alignment: pw.Alignment.center,
                    decoration: pw.BoxDecoration(color: PdfColors.green100),
                    child: pw.Text('$totalQty', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ),
                  pw.Container(),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(3),
                    alignment: pw.Alignment.center,
                    decoration: pw.BoxDecoration(color: PdfColors.green100),
                    child: pw.Text(totalM2.toStringAsFixed(3), style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(3),
                    alignment: pw.Alignment.center,
                    decoration: pw.BoxDecoration(color: PdfColors.green100),
                    child: pw.Text('${totalWeight.toStringAsFixed(2)} kg', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // Podsumowanie
          pw.Table(
            border: pw.TableBorder.all(width: 1),
            columnWidths: {
              0: pw.FixedColumnWidth(22),
              1: pw.FixedColumnWidth(60),
              2: pw.FixedColumnWidth(32),
              3: pw.FixedColumnWidth(45),
              4: pw.FixedColumnWidth(45),
              5: pw.FixedColumnWidth(55),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Container(padding: const pw.EdgeInsets.all(4), child: pw.Text('Lp', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Container(padding: const pw.EdgeInsets.all(4), child: pw.Text('Szyby', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Container(padding: const pw.EdgeInsets.all(4), child: pw.Text('Ilość', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Container(padding: const pw.EdgeInsets.all(4), child: pw.Text('m²/szt', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Container(padding: const pw.EdgeInsets.all(4), child: pw.Text('m²', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Container(padding: const pw.EdgeInsets.all(4), child: pw.Text('waga [kg]', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 9))),
                ],
              ),
              ..._groupByThickness().entries.map((entry) {
                int thickness = entry.key;
                List<GlassItem> thicknessItems = entry.value;
                int totalQuantity = thicknessItems.fold(0, (sum, item) => sum + item.quantity);
                double totalM2 = thicknessItems.fold(0.0, (sum, item) => sum + item.totalM2);
                double avgM2PerPiece = totalQuantity > 0 ? totalM2 / totalQuantity : 0;
                double totalWeight = thicknessItems.fold(0.0, (sum, item) => sum + item.weight);
                return pw.TableRow(
                  children: [
                    pw.Container(padding: const pw.EdgeInsets.all(3), alignment: pw.Alignment.center, child: pw.Text('${_groupByThickness().keys.toList().indexOf(thickness) + 1}', style: pw.TextStyle(font: ttf, fontSize: 9))),
                    pw.Container(padding: const pw.EdgeInsets.all(3), alignment: pw.Alignment.center, child: pw.Text('Grubość $thickness', style: pw.TextStyle(font: ttf, fontSize: 9))),
                    pw.Container(padding: const pw.EdgeInsets.all(3), alignment: pw.Alignment.center, child: pw.Text('$totalQuantity', style: pw.TextStyle(font: ttf, fontSize: 9))),
                    pw.Container(padding: const pw.EdgeInsets.all(3), alignment: pw.Alignment.center, child: pw.Text(avgM2PerPiece.toStringAsFixed(3), style: pw.TextStyle(font: ttf, fontSize: 9))),
                    pw.Container(padding: const pw.EdgeInsets.all(3), alignment: pw.Alignment.center, child: pw.Text(totalM2.toStringAsFixed(3), style: pw.TextStyle(font: ttf, fontSize: 9))),
                    pw.Container(padding: const pw.EdgeInsets.all(3), alignment: pw.Alignment.center, child: pw.Text('${totalWeight.toStringAsFixed(2)} kg', style: pw.TextStyle(font: ttf, fontSize: 9))),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );

    // Nazwa pliku PDF: Firma klienta + data, bez niedozwolonych znaków i białych znaków
    String client = (companyData.clientName.isNotEmpty ? companyData.clientName : "Firma")
        .replaceAll(RegExp(r'[\\/:*?"<>|\r\n\t]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    String date = companyData.issueDate
        .replaceAll(RegExp(r'[\\/:*?"<>|\r\n\t]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    String fileName = "$client-$date.pdf";

    // Domyślna ścieżka
    String savePath = pdfSavePath.isNotEmpty
        ? pdfSavePath
        : (await getDefaultSavePath());

    // Upewnij się, że ścieżka istnieje
    final dir = Directory(savePath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final file = File('$savePath/$fileName');
    await file.writeAsBytes(await pdf.save());

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF zapisany: $savePath/$fileName')),
      );
    }
  }

  Future<String> getDefaultSavePath() async {
    // Domyślnie do Documents
    final directory = Directory(
      Platform.isWindows
          ? '${Platform.environment['USERPROFILE']}\\Documents'
          : (await getApplicationDocumentsDirectory()).path,
    );
    return directory.path;
  }

  Widget _buildSettingsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ustawienia zapisu PDF', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _pdfPathController,
            decoration: const InputDecoration(
              labelText: 'Ścieżka do folderu zapisu PDF (np. C:\\Users\\Kacper\\Documents\\PDFy)',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _savePdfPath(value.trim());
            },
          ),
          const SizedBox(height: 8),
          const Text('PDF będzie zapisywany w tym folderze z nazwą: [Nazwa firmy klienta]-[Data].pdf'),
        ],
      ),
    );
  }

  // Dodaj brakującą metodę _buildHistoryTab
  Widget _buildHistoryTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: projectHistory.length,
      itemBuilder: (context, index) {
        Project project = projectHistory[index];
        final isSelected = currentProject != null && project.id == currentProject!.id;
        return Card(
          color: isSelected ? Colors.lightBlue[100] : null,
          child: ListTile(
            title: Text(project.name),
            subtitle: Text('Ostatnia zmiana: ${DateFormat('dd.MM.yyyy HH:mm').format(project.updatedAt)}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${project.items.length} pozycji'),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Usuń projekt',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Usuń projekt'),
                        content: Text('Czy na pewno chcesz usunąć projekt "${project.name}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Anuluj'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Usuń'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      setState(() {
                        projectHistory.removeAt(index);
                        // Jeśli usuwany projekt jest aktualnie wybrany, przełącz na pierwszy z listy lub nowy
                        if (currentProject?.id == project.id) {
                          if (projectHistory.isNotEmpty) {
                            currentProject = projectHistory.first;
                            items = List.from(currentProject!.items);
                            costPerTon = currentProject!.costPerTon;
                            companyData = currentProject!.companyData;
                          } else {
                            currentProject = Project(name: 'Nowy projekt');
                            items = [];
                            costPerTon = 6000.0;
                            companyData = CompanyData();
                          }
                        }
                      });
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('project_history', json.encode(
                        projectHistory.map((p) => p.toJson()).toList()
                      ));
                      // Jeśli usunięto aktualny projekt, zapisz nowy stan
                      if (currentProject != null) {
                        await prefs.setString('current_project', json.encode(currentProject!.toJson()));
                      }
                    }
                  },
                ),
              ],
            ),
            onTap: () async {
              setState(() {
                currentProject = project;
                items = List.from(project.items);
                costPerTon = project.costPerTon;
                companyData = project.companyData;
              });
              await _saveCurrentProject();
              _tabController.animateTo(0);
            },
          ),
        );
      },
    );
  }
}