import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../models/food_entry.dart';

class AddFoodScreen extends ConsumerStatefulWidget {
  const AddFoodScreen({super.key});

  @override
  ConsumerState<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends ConsumerState<AddFoodScreen> {
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController(text: '100');
  List<Map<String, dynamic>> _results = [];
  Map<String, dynamic>? _selectedFood;
  bool _isSearching = false;
  String _mealType = 'lunch';

  double? _scale(dynamic value, double multiplier) {
    if (value == null) return null;
    final n = (value as num).toDouble();
    return n * multiplier;
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);

    try {
      final auth = ref.read(authServiceProvider);
      final searchService = ref.read(foodSearchServiceProvider);
      final results = await searchService.search(query, auth.currentUser!.uid);
      setState(() => _results = results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _save() async {
    if (_selectedFood == null) return;

    final auth = ref.read(authServiceProvider);
    final db = ref.read(databaseServiceProvider);
    final quantity = double.tryParse(_quantityController.text) ?? 100;
    final multiplier = quantity / 100;

    final entry = FoodEntry(
      id: const Uuid().v4(),
      userId: auth.currentUser!.uid,
      foodName: _selectedFood!['name'] as String,
      quantity: quantity,
      calories: _scale(_selectedFood!['calories'], multiplier) ?? 0,
      protein: _scale(_selectedFood!['protein'], multiplier) ?? 0,
      carbs: _scale(_selectedFood!['carbs'], multiplier) ?? 0,
      fat: _scale(_selectedFood!['fat'], multiplier) ?? 0,
      fiber: _scale(_selectedFood!['fiber'], multiplier) ?? 0,
      sugar: _scale(_selectedFood!['sugar'], multiplier) ?? 0,
      sodium: _scale(_selectedFood!['sodium'], multiplier) ?? 0,
      vitaminA: _scale(_selectedFood!['vitaminA'], multiplier) ?? 0,
      vitaminC: _scale(_selectedFood!['vitaminC'], multiplier) ?? 0,
      vitaminD: _scale(_selectedFood!['vitaminD'], multiplier) ?? 0,
      calcium: _scale(_selectedFood!['calcium'], multiplier) ?? 0,
      iron: _scale(_selectedFood!['iron'], multiplier) ?? 0,
      potassium: _scale(_selectedFood!['potassium'], multiplier) ?? 0,
      loggedAt: DateTime.now(),
      mealType: _mealType,
    );

    await db.insertEntry(entry);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Añadir comida')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Buscar alimento...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _isSearching ? null : _search,
                  icon: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                ),
              ],
            ),
          ),
          if (_selectedFood != null) ...[
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      _selectedFood!['name'] as String,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Cantidad (g): '),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: _mealType,
                      items: const [
                        DropdownMenuItem(
                            value: 'breakfast', child: Text('Desayuno')),
                        DropdownMenuItem(value: 'lunch', child: Text('Comida')),
                        DropdownMenuItem(value: 'dinner', child: Text('Cena')),
                        DropdownMenuItem(value: 'snack', child: Text('Snack')),
                      ],
                      onChanged: (v) => setState(() => _mealType = v!),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _save,
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final food = _results[index];
                return ListTile(
                  title: Text(food['name'] as String),
                  subtitle: Text(
                    '${(food['calories'] as num?)?.toStringAsFixed(0) ?? '?'} kcal · '
                    '${(food['protein'] as num?)?.toStringAsFixed(1) ?? '?'}g P · '
                    '${(food['carbs'] as num?)?.toStringAsFixed(1) ?? '?'}g C · '
                    '${(food['fat'] as num?)?.toStringAsFixed(1) ?? '?'}g G',
                  ),
                  trailing: Text(food['source'] as String? ?? ''),
                  onTap: () => setState(() => _selectedFood = food),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
