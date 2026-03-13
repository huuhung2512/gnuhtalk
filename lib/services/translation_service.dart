import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class TranslationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Translates [text] into [targetLangCode] (e.g., 'vi', 'ko', 'en').
  /// Checks Firestore first to save Groq API Quota.
  Future<String> translateMessage(
    String messageId,
    String text,
    String sourceLangCode,
    String targetLangCode,
  ) async {
    // 1. Quota Optimization: Language Check
    if (sourceLangCode == targetLangCode) {
      return text;
    }

    try {
      // 2. Quota Optimization: Check Cache in Firestore
      final cacheRef = _db
          .collection('messages')
          .doc(messageId)
          .collection('translations')
          .doc(targetLangCode);

      final docSnap = await cacheRef.get();
      if (docSnap.exists) {
        final data = docSnap.data();
        if (data != null && data.containsKey('text')) {
          print("Translation loaded from cache to save quota: ${data['text']}");
          return data['text'] as String;
        }
      }

      // 3. Call Groq API
      // Using concise prompt for quota optimization
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiKeys.groqApiKey}',
      };

      final body = jsonEncode({
        "model": "llama-3.3-70b-versatile", // Updated model per user request
        "messages": [
          {
            "role": "system",
            "content":
                "Translate the user message strictly entirely into the target language code '$targetLangCode'. Do not provide any conversational text, explanations, or notes. ONLY output the translated text.",
          },
          {"role": "user", "content": text},
        ],
        "temperature": 0.3,
        "max_tokens": 1024,
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final translatedText = responseData['choices'][0]['message']['content']
            .toString()
            .trim();

        // Save to cache for future use
        await cacheRef.set({
          'text': translatedText,
          'timestamp': FieldValue.serverTimestamp(),
        });

        return translatedText;
      } else {
        print('Groq API Error: ${response.statusCode} - ${response.body}');
        return "(Translation failed)";
      }
    } catch (e) {
      print('=== TRANSLATION EXCEPTION: $e ===');
      return "(Translation error)";
    }
  }
}
