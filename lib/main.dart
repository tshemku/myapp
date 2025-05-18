import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'profile_screen.dart';

void main() => runApp(const WeightTrackerApp());

class WeightTrackerApp extends StatelessWidget {
  const WeightTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weight Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
        ).copyWith(secondary: Colors.teal[700]),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class WeightEntry {
  final DateTime date;
  final double weight; // in lbs
  final double? waist; // in inches
  final double? neck; // in inches
  final double? hip; // in inches

  WeightEntry({
    required this.date,
    required this.weight,
    this.waist,
    this.neck,
    this.hip,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'weight': weight,
        'waist': waist,
        'neck': neck,
        'hip': hip,
      };

  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry(
        date: DateTime.parse(json['date']),
        weight: json['weight'],
        waist: json['waist'],
        neck: json['neck'],
        hip: json['hip'],
      );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [const AddWeightScreen(), const ProgressScreen()];

    return Scaffold(
      appBar: AppBar(title: const Text('Weight Tracker')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Navigation'),
            ),
            ListTile(
              title: const Text('Profile'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
            ),
          ],
        ),
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add Weight'),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Progress',
          ),
        ],
      ),
    );
  }
}

class AddWeightScreen extends StatefulWidget {
  const AddWeightScreen({super.key});

  @override
  _AddWeightScreenState createState() => _AddWeightScreenState();
}

class _AddWeightScreenState extends State<AddWeightScreen> {
  double _selectedWeight = 150;
  final _waistController = TextEditingController();
  final _neckController = TextEditingController();
  final _hipController = TextEditingController();

  Future<void> _saveEntry() async {
    final prefs = await SharedPreferences.getInstance();
    final entry = WeightEntry(
      date: DateTime.now(),
      weight: _selectedWeight,
      waist: double.tryParse(
        _waistController.text.isEmpty ? '' : _waistController.text,
      ),
      neck: double.tryParse(
        _neckController.text.isEmpty ? '' : _neckController.text,
      ),
      hip: double.tryParse(_hipController.text),
    );
    final entries = prefs.getStringList('entries') ?? [];
    final decodedEntries =
        entries.map((e) => WeightEntry.fromJson(jsonDecode(e))).toList();

    final existingEntryIndex = decodedEntries.indexWhere(
      (e) =>
          e.date.year == entry.date.year &&
          e.date.month == entry.date.month &&
          e.date.day == entry.date.day,
    );

    if (existingEntryIndex != -1) {
      final shouldOverride = await _showOverrideConfirmationDialog();
      if (shouldOverride == true) {
        decodedEntries[existingEntryIndex] = entry;
      } else {
        return;
      }
    } else {
      decodedEntries.add(entry);
    }

    final updatedEntries =
        decodedEntries.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('entries', updatedEntries);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Entry saved!')));
  }

  Future<bool?> _showOverrideConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Override Entry?'),
          content: const Text(
            'You have already added a weight entry for today. Do you wish to override it?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Override'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Current Weight: ${_selectedWeight.toStringAsFixed(1)} lbs',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onPanUpdate: (details) {
                final RenderBox renderBox =
                    context.findRenderObject() as RenderBox;
                final position = renderBox.globalToLocal(
                  details.globalPosition,
                );
                final center = renderBox.size.center(Offset.zero);
                final vector = position - center;
                double angle = vector.direction;

                if (angle < 0) {
                  angle += 2 * 3.14159;
                }

                double weight = 0;
                if (angle >= 0 && angle <= 3.14159) {
                  weight = 400 - (angle / 3.14159) * 400;
                } else {
                  weight = 0;
                }

                weight = weight.clamp(0.0, 400.0);

                setState(() {
                  _selectedWeight = weight;
                });
              },
              child: SizedBox(
                height: 175.0,
                child: SfRadialGauge(
                  axes: <RadialAxis>[
                    RadialAxis(
                      minimum: 0,
                      maximum: 400,
                      ranges: <GaugeRange>[
                        GaugeRange(
                          startValue: 0,
                          endValue: 150,
                          color: Colors.green,
                        ),
                        GaugeRange(
                          startValue: 150,
                          endValue: 250,
                          color: Colors.orange,
                        ),
                        GaugeRange(
                          startValue: 250,
                          endValue: 400,
                          color: Colors.red,
                        ),
                      ],
                      pointers: <GaugePointer>[
                        NeedlePointer(value: _selectedWeight),
                      ],
                      annotations: <GaugeAnnotation>[
                        GaugeAnnotation(
                          widget: Text(
                            '${_selectedWeight.toStringAsFixed(1)} lbs',
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          angle: 90,
                          positionFactor: 0.5,
                        ),
                      ],
                      onAxisTapped:
                          (value) => setState(() => _selectedWeight = value),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _waistController,
              decoration: const InputDecoration(labelText: 'Waist (in)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _neckController,
              decoration: const InputDecoration(labelText: 'Neck (in)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _hipController,
              decoration: const InputDecoration(labelText: 'Hip (in)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveEntry,
              child: const Text('Save Entry'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  _ProgressScreenState createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _showGraph = false;
  List<WeightEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final entries = prefs.getStringList('entries') ?? [];
    setState(() {
      _entries =
          entries.map((e) => WeightEntry.fromJson(jsonDecode(e))).toList()
            ..sort((a, b) => b.date.compareTo(a.date));
    });
  }

  Future<void> _clearEntries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('entries');
    _loadEntries();
  }

  Widget _buildList() {
    return ListView.builder(
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entry = _entries[index];
        return ListTile(
          title: Text(
            '${entry.date.toString().split(' ')[0]}: ${entry.weight.toStringAsFixed(1)} lbs',
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailsScreen(entry: entry)),
          ),
        );
      },
    );
  }

  Widget _buildGraph() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        height: 300,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: true),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() < 0 || value.toInt() >= _entries.length) {
                      return Container();
                    }
                    final date = _entries[value.toInt()].date;
                    return Text('${date.day}/${date.month}');
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (LineBarSpot spot) => Colors.blueAccent,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((touchedSpot) {
                    final entryIndex = touchedSpot.x.toInt();
                    if (entryIndex < 0 || entryIndex >= _entries.length) {
                      return null;
                    }
                    final entry = _entries[entryIndex];
                    return LineTooltipItem(
                      '${entry.weight.toStringAsFixed(1)} lbs',
                      const TextStyle(color: Colors.white),
                    );
                  }).toList();
                },
              ),
              touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                if (response?.lineBarSpots != null && event is FlTapUpEvent) {
                  for (final spot in response!.lineBarSpots!) {
                    final entry = _entries[spot.spotIndex];
                    print('Tapped on entry: ${entry.date}, Weight: ${entry.weight} lbs');
                  }
                }
              },
            ),
            lineBarsData: [
              LineChartBarData(
                spots: _entries.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.weight)).toList(),
                isCurved: true,
                dotData: const FlDotData(show: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          title: const Text('Show Graph'),
          value: _showGraph,
          onChanged: (value) => setState(() => _showGraph = value),
        ),
        Expanded(child: _showGraph ? _buildGraph() : _buildList()),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _clearEntries,
            child: const Text('Clear All Data'),
          ),
        ),
      ],
    );
  }
}

class WeightChart extends StatelessWidget {
  final List<WeightEntry> entries;

  const WeightChart({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    entries.sort((a, b) => a.date.compareTo(b.date));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < 0 || value.toInt() >= entries.length) {
                    return Container();
                  }
                  final date = entries[value.toInt()].date;
                  return Text('${date.day}/${date.month}');
                },
                interval: (entries.length / 5).ceil().toDouble(),
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots:
                  entries
                      .asMap()
                      .entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value.weight))
                      .toList(),
              isCurved: true,
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailsScreen extends StatelessWidget {
  final WeightEntry entry;

  const DetailsScreen({super.key, required this.entry});

  double calculateBMI(double height) {
    final weightKg = entry.weight * 0.453592;
    return weightKg / (height * height);
  }

  double calculateBMR(double heightCm, double age) {
    final weightKg = entry.weight * 0.453592;
    return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5; // Men’s formula
  }

  double estimateVisceralFat() {
    return 0; // Placeholder for actual visceral fat calculation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entry Details')),
      body: FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final prefs = snapshot.data!;
          final height =
              prefs.getDouble('height') ??
                  1.75; // Default height in meters (~5'9")
          final age =
              prefs.getInt('age')?.toDouble() ?? 30.0; // Convert int to double

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date: ${entry.date.toLocal().toString().split(' ')[0]}'),
                Text('Weight: ${entry.weight.toStringAsFixed(1)} lbs'),
                Text('BMI: ${calculateBMI(height).toStringAsFixed(1)}'),
                Text(
                  'BMR: ${calculateBMR(height * 100, age).toStringAsFixed(0)} kcal/day',
                ),
                Text('Visceral Fat: ${estimateVisceralFat()}'),
                if (entry.waist != null)
                  Text('Waist: ${entry.waist!.toStringAsFixed(1)} in'),
                if (entry.neck != null)
                  Text('Neck: ${entry.neck!.toStringAsFixed(1)} in'),
                if (entry.hip != null)
                  Text('Hip: ${entry.hip!.toStringAsFixed(1)} in'),
              ],
            ),
          );
        },
      ),
    );
  }
}