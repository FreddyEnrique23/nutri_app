import 'usda_service.dart';
import 'fatsecret_service.dart';
import 'database_service.dart';

class FoodSearchService {
  final UsdaService _usda;
  final FatSecretService _fatSecret;
  final DatabaseService _db;

  FoodSearchService({
    required UsdaService usda,
    required FatSecretService fatSecret,
    required DatabaseService db,
  })  : _usda = usda,
        _fatSecret = fatSecret,
        _db = db;

  Future<List<Map<String, dynamic>>> search(String query, String userId) async {
    // 1. Buscar primero en base local (instantáneo)
    final localResults = await _db.searchLocalFoods(userId, query);
    
    // 2. Buscar en APIs externas en paralelo
    final results = await Future.wait([
      _searchUsdaSafe(query),
      _searchFatSecretSafe(query),
    ]);

    final usdaResults = results[0];
    final fatSecretResults = results[1];

    // 3. Combinar: local primero, luego APIs
    // Deduplicar por nombre (case-insensitive)
    final seenNames = <String>{};
    final combined = <Map<String, dynamic>>[];

    for (final entry in localResults) {
      final key = entry.foodName.toLowerCase();
      if (!seenNames.contains(key)) {
        seenNames.add(key);
        combined.add({
          'source': 'local',
          'name': entry.foodName,
          'calories': entry.calories,
          'protein': entry.protein,
          'carbs': entry.carbs,
          'fat': entry.fat,
          'fiber': entry.fiber,
          'sugar': entry.sugar,
          'sodium': entry.sodium,
          'vitaminA': entry.vitaminA,
          'vitaminC': entry.vitaminC,
          'vitaminD': entry.vitaminD,
          'calcium': entry.calcium,
          'iron': entry.iron,
          'potassium': entry.potassium,
        });
      }
    }

    for (final item in [...usdaResults, ...fatSecretResults]) {
      final key = (item['name'] as String).toLowerCase();
      if (!seenNames.contains(key)) {
        seenNames.add(key);
        combined.add(item);
      }
    }

    return combined.take(25).toList();
  }

  Future<List<Map<String, dynamic>>> _searchUsdaSafe(String query) async {
    try {
      return await _usda.searchFoods(query);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _searchFatSecretSafe(String query) async {
    try {
      return await _fatSecret.searchFoods(query);
    } catch (e) {
      return [];
    }
  }
}