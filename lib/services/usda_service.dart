import 'dart:convert';
import 'package:http/http.dart' as http;

class UsdaService {
  final String _apiKey;
  static const String _baseUrl = 'https://api.nal.usda.gov/fdc/v1';
  static const String _dataType = 'Foundation,SR Legacy,Survey (FNDDS)';

  UsdaService(this._apiKey);

  Future<List<Map<String, dynamic>>> searchFoods(String query, {int pageSize = 10}) async {
    final uri = Uri.parse('$_baseUrl/foods/search').replace(
      queryParameters: {
        'query': query,
        'dataType': _dataType,
        'pageSize': pageSize.toString(),
        'api_key': _apiKey,
      },
    );

    final response = await http.get(uri);
    
    if (response.statusCode != 200) {
      throw Exception('USDA API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final foods = data['foods'] as List<dynamic>? ?? [];

    return foods.map((food) {
      final nutrients = food['foodNutrients'] as List<dynamic>? ?? [];
      
      double? getNutrient(String nutrientName) {
        final match = nutrients.firstWhere(
          (n) => (n['nutrientName'] as String?)?.toLowerCase() == nutrientName.toLowerCase(),
          orElse: () => null,
        );
        return match != null ? (match['value'] as num?)?.toDouble() : null;
      }

      return {
        'source': 'usda',
        'fdcId': food['fdcId'],
        'name': food['description'] as String? ?? 'Unknown',
        'brand': food['brandOwner'] as String? ?? 'Generic',
        'calories': getNutrient('Energy') ?? 0.0,
        'protein': getNutrient('Protein') ?? 0.0,
        'carbs': getNutrient('Carbohydrate, by difference') ?? 0.0,
        'fat': getNutrient('Total lipid (fat)') ?? 0.0,
        'fiber': getNutrient('Fiber, total dietary') ?? 0.0,
        'sugar': getNutrient('Sugars, total including NLEA') ?? 0.0,
        'sodium': getNutrient('Sodium, Na') ?? 0.0,
        'vitaminA': getNutrient('Vitamin A, RAE'),
        'vitaminC': getNutrient('Vitamin C, total ascorbic acid'),
        'vitaminD': getNutrient('Vitamin D (D2 + D3)'),
        'calcium': getNutrient('Calcium, Ca'),
        'iron': getNutrient('Iron, Fe'),
        'potassium': getNutrient('Potassium, K'),
      };
    }).toList();
  }
}