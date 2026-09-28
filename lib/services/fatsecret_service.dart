import 'dart:convert';
import 'package:http/http.dart' as http;

class FatSecretService {
  final String _clientId;
  final String _clientSecret;
  final String _tokenUrl;
  final String _apiUrl;
  
  String? _accessToken;
  DateTime? _tokenExpiry;

  FatSecretService({
    required String clientId,
    required String clientSecret,
    required String tokenUrl,
    required String apiUrl,
  })  : _clientId = clientId,
        _clientSecret = clientSecret,
        _tokenUrl = tokenUrl,
        _apiUrl = apiUrl;

  Future<String> _getToken() async {
    // Reutilizar token si aún es válido
    if (_accessToken != null && _tokenExpiry != null) {
      if (DateTime.now().isBefore(_tokenExpiry!)) {
        return _accessToken!;
      }
    }

    final credentials = base64Encode(utf8.encode('$_clientId:$_clientSecret'));
    
    final response = await http.post(
      Uri.parse(_tokenUrl),
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: 'grant_type=client_credentials&scope=basic',
    );

    if (response.statusCode != 200) {
      throw Exception('FatSecret token error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    _accessToken = data['access_token'] as String;
    final expiresIn = data['expires_in'] as int? ?? 3600;
    _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60));

    return _accessToken!;
  }

  Future<List<Map<String, dynamic>>> searchFoods(String query, {int maxResults = 10}) async {
    final token = await _getToken();
    
    final uri = Uri.parse(_apiUrl).replace(
      queryParameters: {
        'method': 'foods.search',
        'search_expression': query,
        'max_results': maxResults.toString(),
        'format': 'json',
      },
    );

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('FatSecret search error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final foods = data['foods']?['food'] as List<dynamic>? ?? [];

    return foods.map((food) {
      return {
        'source': 'fatsecret',
        'foodId': food['food_id'],
        'name': food['food_name'] as String? ?? 'Unknown',
        'brand': food['brand_name'] as String? ?? 'Generic',
        'calories': double.tryParse(food['servings']?['serving']?['calories']?.toString() ?? '0') ?? 0.0,
        'protein': double.tryParse(food['servings']?['serving']?['protein']?.toString() ?? '0') ?? 0.0,
        'carbs': double.tryParse(food['servings']?['serving']?['carbohydrate']?.toString() ?? '0') ?? 0.0,
        'fat': double.tryParse(food['servings']?['serving']?['fat']?.toString() ?? '0') ?? 0.0,
      };
    }).toList();
  }
}