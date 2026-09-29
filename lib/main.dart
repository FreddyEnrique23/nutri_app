mport 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'services/database_service.dart';
import 'services/auth_service.dart';
import 'services/usda_service.dart';
import 'services/fatsecret_service.dart';
import 'services/food_search_service.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService.instance;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final usdaServiceProvider = Provider<UsdaService>((ref) {
  return UsdaService(dotenv.env['USDA_API_KEY'] ?? '');
});

final fatSecretServiceProvider = Provider<FatSecretService>((ref) {
  return FatSecretService(
    clientId: dotenv.env['FATSECRET_CLIENT_ID'] ?? '',
    clientSecret: dotenv.env['FATSECRET_CLIENT_SECRET'] ?? '',
    tokenUrl: dotenv.env['FATSECRET_TOKEN_URL'] ?? '',
    apiUrl: dotenv.env['FATSECRET_API_URL'] ?? '',
  );
});

final foodSearchServiceProvider = Provider<FoodSearchService>((ref) {
  return FoodSearchService(
    usda: ref.watch(usdaServiceProvider),
    fatSecret: ref.watch(fatSecretServiceProvider),
    db: ref.watch(databaseServiceProvider),
  );
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: NutriApp()));
}

class NutriApp extends ConsumerWidget {
  const NutriApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);

    return MaterialApp(
      title: 'NutriApp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: authService.isLoggedIn ? const HomeScreen() : const AuthScreen(),
    );
  }
}