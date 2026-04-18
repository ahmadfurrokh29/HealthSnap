import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _geminiApiKey = 'AIzaSyCatVJ3S1QoNDL9KBZsq9y9Bh78Vu1jygY';
  static const String _grokApiKey = 'xai-LC8lOZyZJ0JzHeb8nlZ8PFuqtPBiLnT7AxDsHYvi2ZbczO530rYzEW8A6dWPgvBCdv8L7JsYjANXNPB3'; // <-- Replace with your xAI API key
  static const String _grokEndpoint = 'https://api.x.ai/v1/chat/completions';

  static final GenerativeModel _model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: _geminiApiKey,
  );

  // ─── History prompts ───
  static const String _historyPrompt =
      'Extract medical history from this image. Return ONLY valid JSON, no markdown.\n'
      'Format:\n'
      '{"date":"","doctorName":"","clinicName":"","specialty":"","diagnosis":"","fullDiagnosis":"","symptoms":[""],"medicines":[{"name":"","dosage":"","duration":"","frequency":""}],"clinicalNotes":""}\n'
      'Use empty string "" for missing text fields, empty array [] for missing lists. Do not guess or invent data.';

  // ─── Report prompts ───
  static const String _reportPrompt =
      'Extract lab/medical report from this image. Return ONLY valid JSON, no markdown.\n'
      'Format:\n'
      '{"testName":"","labName":"","testDate":"","generalStatus":"","generalStatusNote":"","parameters":[{"name":"","value":"","unit":"","range":""}]}\n'
      'generalStatus: short label (e.g. Normal, Borderline, Abnormal). generalStatusNote: 1-line AI summary of overall results.\n'
      'Use empty string "" for missing fields, empty array [] for missing parameters. Do not guess or invent data.';

  /// Extract medical history data from an image
  static Future<Map<String, dynamic>> extractMedicalHistory(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final mimeType = _getMimeType(imageFile.path);

    try {
      return await _geminiExtract(bytes, mimeType, _historyPrompt);
    } catch (e) {
      if (_isServerError(e)) {
        // Fallback to Grok
        return await _grokExtract(bytes, mimeType, _historyPrompt);
      }
      rethrow;
    }
  }

  /// Extract medical report data from an image
  static Future<Map<String, dynamic>> extractMedicalReport(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final mimeType = _getMimeType(imageFile.path);

    try {
      return await _geminiExtract(bytes, mimeType, _reportPrompt);
    } catch (e) {
      if (_isServerError(e)) {
        // Fallback to Grok
        return await _grokExtract(bytes, mimeType, _reportPrompt);
      }
      rethrow;
    }
  }

  /// Check if error is a server/overload error worth retrying with fallback
  static bool _isServerError(dynamic e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('503') ||
        msg.contains('500') ||
        msg.contains('unavailable') ||
        msg.contains('overloaded') ||
        msg.contains('high demand') ||
        msg.contains('server error');
  }

  // ─── Gemini extraction ───
  static Future<Map<String, dynamic>> _geminiExtract(
      Uint8List bytes, String mimeType, String promptText) async {
    final prompt = Content.multi([
      TextPart(promptText),
      DataPart(mimeType, bytes),
    ]);

    try {
      final response = await _model.generateContent([prompt]);
      final text = response.text ?? '';
      return _parseJson(text);
    } catch (e) {
      throw Exception('Gemini: $e');
    }
  }

  // ─── Grok fallback extraction ───
  static Future<Map<String, dynamic>> _grokExtract(
      Uint8List bytes, String mimeType, String promptText) async {
    final base64Image = base64Encode(bytes);

    final body = jsonEncode({
      'model': 'grok-4',
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': promptText},
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:$mimeType;base64,$base64Image',
              },
            },
          ],
        },
      ],
      'temperature': 0.1,
    });

    try {
      final response = await http.post(
        Uri.parse(_grokEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_grokApiKey',
        },
        body: body,
      );

      if (response.statusCode != 200) {
        throw Exception('Grok API error: ${response.statusCode} ${response.body}');
      }

      final json = jsonDecode(response.body);
      final text = json['choices'][0]['message']['content'] as String;
      return _parseJson(text);
    } catch (e) {
      throw Exception('Failed to process image: $e');
    }
  }

  static String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  static Map<String, dynamic> _parseJson(String raw) {
    String cleaned = raw.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '');
      cleaned = cleaned.replaceFirst(RegExp(r'\n?```$'), '');
      cleaned = cleaned.trim();
    }
    try {
      final decoded = jsonDecode(cleaned);
      if (decoded is Map<String, dynamic>) return decoded;
      throw const FormatException('Response is not a JSON object');
    } catch (_) {
      throw Exception('Could not extract data from this image. Please try a clearer medical document.');
    }
  }
}
