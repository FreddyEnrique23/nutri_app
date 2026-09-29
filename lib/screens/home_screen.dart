import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../models/food_entry.dart';
import 'auth_screen.dart';
import 'add_food_screen.dart';

final dailyLogProvider =
    FutureProvider.family<List<FoodEntry>, String>((ref, userId) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getEntriesForDay(userId, DateTime.now());
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authServiceProvider);
    final userId = auth.currentUser?.uid ?? '';
    final entriesAsync = ref.watch(dailyLogProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hoy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => AuthScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entries) {
          final totals = _calculateTotals(entries);

          return Column(
            children: [
              // Resumen de macros
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MacroCircle(
                          label: 'kcal',
                          value: totals['calories']!,
                          color: Colors.orange),
                      _MacroCircle(
                          label: 'Proteína',
                          value: totals['protein']!,
                          color: Colors.red),
                      _MacroCircle(
                          label: 'Carbos',
                          value: totals['carbs']!,
                          color: Colors.blue),
                      _MacroCircle(
                          label: 'Grasa',
                          value: totals['fat']!,
                          color: Colors.yellow[700]!),
                    ],
                  ),
                ),
              ),
              // Lista de entradas
              Expanded(
                child: entries.isEmpty
                    ? const Center(
                        child: Text(
                            'No hay registros hoy.\n¡Añade tu primera comida!'))
                    : ListView.builder(
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return ListTile(
                            title: Text(entry.foodName),
                            subtitle: Text(
                              '${entry.quantity.toStringAsFixed(0)}g · ${entry.calories.toStringAsFixed(0)} kcal',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                final db = ref.read(databaseServiceProvider);
                                await db.deleteEntry(entry.id);
                                ref.invalidate(dailyLogProvider(userId));
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddFoodScreen()),
          );
          if (result == true) {
            ref.invalidate(dailyLogProvider(userId));
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Añadir comida'),
      ),
    );
  }

  Map<String, double> _calculateTotals(List<FoodEntry> entries) {
    double calories = 0, protein = 0, carbs = 0, fat = 0;
    for (final e in entries) {
      calories += e.calories;
      protein += e.protein;
      carbs += e.carbs;
      fat += e.fat;
    }
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
}

class _MacroCircle extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MacroCircle({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 4),
          ),
          child: Center(
            child: Text(
              value.toStringAsFixed(0),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
