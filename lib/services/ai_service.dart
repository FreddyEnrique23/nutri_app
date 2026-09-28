import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🧪 Aquí va la llamada de prueba a Gemini
  try {
    final model =
        FirebaseAI.googleAI().generativeModel(model: 'gemini-flash-latest');
    final response = await model.generateContent(
        [Content.text('Dime cuántas calorías tiene un huevo')]);
    print('🤖 Respuesta de Gemini: ${response.text}');
  } catch (e) {
    print('❌ Error de IA: $e');
  }

  runApp(const ProviderScope(child: NutriApp()));
}
