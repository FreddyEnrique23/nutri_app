import 'package:firebase_ai/firebase_ai.dart';

class AiService {
  final model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-flash-latest',
  );

  Future<String> generateResponse(String prompt) async {
    try {
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Sin respuesta';
    } catch (e) {
      return 'Error: $e';
    }
  }
}
