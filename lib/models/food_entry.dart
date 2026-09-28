class FoodEntry {
  final String id;
  final String userId;
  final String foodName;
  final double quantity; // en gramos
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double sodium;
  // Micronutrientes clave
  final double? vitaminA;
  final double? vitaminC;
  final double? vitaminD;
  final double? calcium;
  final double? iron;
  final double? potassium;
  final DateTime loggedAt;
  final String mealType; // breakfast, lunch, dinner, snack

  FoodEntry({
    required this.id,
    required this.userId,
    required this.foodName,
    required this.quantity,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.sodium,
    this.vitaminA,
    this.vitaminC,
    this.vitaminD,
    this.calcium,
    this.iron,
    this.potassium,
    required this.loggedAt,
    required this.mealType,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'food_name': foodName,
      'quantity': quantity,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'vitamin_a': vitaminA,
      'vitamin_c': vitaminC,
      'vitamin_d': vitaminD,
      'calcium': calcium,
      'iron': iron,
      'potassium': potassium,
      'logged_at': loggedAt.toIso8601String(),
      'meal_type': mealType,
    };
  }

  factory FoodEntry.fromMap(Map<String, dynamic> map) {
    return FoodEntry(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      foodName: map['food_name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      calories: (map['calories'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      fiber: (map['fiber'] as num).toDouble(),
      sugar: (map['sugar'] as num).toDouble(),
      sodium: (map['sodium'] as num).toDouble(),
      vitaminA: (map['vitamin_a'] as num?)?.toDouble(),
      vitaminC: (map['vitamin_c'] as num?)?.toDouble(),
      vitaminD: (map['vitamin_d'] as num?)?.toDouble(),
      calcium: (map['calcium'] as num?)?.toDouble(),
      iron: (map['iron'] as num?)?.toDouble(),
      potassium: (map['potassium'] as num?)?.toDouble(),
      loggedAt: DateTime.parse(map['logged_at'] as String),
      mealType: map['meal_type'] as String,
    );
  }
}