import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Holds every piece of information the AI returns about a detected vegetable.
class VegetableResult {
  final bool isVegetable;
  final String vegetableNameBengali;
  final String vegetableNameEnglish;
  final String confidence;
  final String detailsBengali;

  // ── Rich-info fields ────────────────────────────────────────────────────────
  /// Scientific / Latin name, e.g. "Solanum tuberosum"
  final String scientificName;

  /// Nutritional highlights in Bengali
  final String nutritionBengali;

  /// Bangladesh growing season in Bengali, e.g. "নভেম্বর – ফেব্রুয়ারি (রবি মৌসুম)"
  final String growingSeasonBengali;

  /// Best month(s) for Bangladeshi farmers in Bengali
  final String bestMonthBengali;

  /// Culinary, dietary, and medicinal uses of the vegetable in Bengali
  final String usesBengali;

  /// Regional / alternative names in different markets of Bangladesh (e.g. "কদু", "মিঠা কদু", "গোল/তাল বেগুন")
  final String regionalNamesBengali;

  const VegetableResult({
    required this.isVegetable,
    required this.vegetableNameBengali,
    required this.vegetableNameEnglish,
    required this.confidence,
    required this.detailsBengali,
    this.scientificName = '',
    this.nutritionBengali = '',
    this.growingSeasonBengali = '',
    this.bestMonthBengali = '',
    this.usesBengali = '',
    this.regionalNamesBengali = '',
  });

  factory VegetableResult.fromMap(Map<String, dynamic> map) {
    return VegetableResult(
      isVegetable: map['isVegetable'] ?? true,
      vegetableNameBengali: (map['vegetableNameBengali'] ?? 'অজানা সবজি').toString().trim(),
      vegetableNameEnglish: (map['vegetableNameEnglish'] ?? 'Unknown Vegetable').toString().trim(),
      confidence: (map['confidence'] ?? 'মাঝারি').toString().trim(),
      detailsBengali: (map['detailsBengali'] ?? '').toString().trim(),
      scientificName: (map['scientificName'] ?? '').toString().trim(),
      nutritionBengali: (map['nutritionBengali'] ?? '').toString().trim(),
      growingSeasonBengali: (map['growingSeasonBengali'] ?? '').toString().trim(),
      bestMonthBengali: (map['bestMonthBengali'] ?? '').toString().trim(),
      usesBengali: (map['usesBengali'] ?? '').toString().trim(),
      regionalNamesBengali: (map['regionalNamesBengali'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isVegetable': isVegetable,
      'vegetableNameBengali': vegetableNameBengali,
      'vegetableNameEnglish': vegetableNameEnglish,
      'confidence': confidence,
      'detailsBengali': detailsBengali,
      'scientificName': scientificName,
      'nutritionBengali': nutritionBengali,
      'growingSeasonBengali': growingSeasonBengali,
      'bestMonthBengali': bestMonthBengali,
      'usesBengali': usesBengali,
      'regionalNamesBengali': regionalNamesBengali,
    };
  }
}

class AiService {
  /// Dynamic user/admin provided API Key stored in memory
  static String? _customApiKey;

  /// Cached key fetched from Firestore
  static String? _firestoreCachedApiKey;

  /// Inject with --dart-define-from-file; never commit the key with app source.
  static const String _envApiKey = String.fromEnvironment('GEMINI_API_KEY');

  /// Sets the custom API key at runtime
  static void setApiKey(String key) {
    _customApiKey = key.trim();
  }

  /// Returns the current active API key synchronously
  static String get apiKey {
    if (_customApiKey != null && _customApiKey!.isNotEmpty) {
      return _customApiKey!;
    }
    if (_envApiKey.isNotEmpty) return _envApiKey;
    if (_firestoreCachedApiKey != null && _firestoreCachedApiKey!.isNotEmpty) {
      return _firestoreCachedApiKey!;
    }
    return '';
  }

  /// Checks if a valid-looking API key is present
  static bool get hasValidApiKey {
    final key = apiKey;
    return key.trim().isNotEmpty && key.trim().length > 15;
  }

  /// Asynchronously resolves the API key (including Firestore fetch if needed)
  static Future<String> getApiKeyAsync() async {
    if (_customApiKey != null && _customApiKey!.isNotEmpty) {
      return _customApiKey!;
    }
    if (_envApiKey.isNotEmpty) return _envApiKey;
    if (_firestoreCachedApiKey != null && _firestoreCachedApiKey!.isNotEmpty) {
      return _firestoreCachedApiKey!;
    }
    // Attempt to load from Firestore app_config/gemini
    try {
      final doc = await FirebaseFirestore.instance.collection('app_config').doc('gemini').get();
      if (doc.exists && doc.data() != null) {
        final keyFromDb = doc.data()?['apiKey']?.toString().trim();
        if (keyFromDb != null && keyFromDb.isNotEmpty) {
          _firestoreCachedApiKey = keyFromDb;
          return keyFromDb;
        }
      }
    } catch (_) {}

    return '';
  }

  /// Saves the Gemini API key to Firestore so it persists across all devices
  static Future<void> saveApiKeyToFirestore(String newKey) async {
    final cleanKey = newKey.trim();
    _customApiKey = cleanKey;
    _firestoreCachedApiKey = cleanKey;
    try {
      await FirebaseFirestore.instance.collection('app_config').doc('gemini').set({
        'apiKey': cleanKey,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore saveApiKey error: $e');
    }
  }

  /// Saves scanned vegetable picture and extracted information into Firebase Firestore
  static Future<String?> saveVegetableScanToFirebase({
    required VegetableResult result,
    required Uint8List imageBytes,
  }) async {
    try {
      final db = FirebaseFirestore.instance;
      final base64Img = base64Encode(imageBytes);
      final data = result.toMap();
      data['imageBase64'] = base64Img;
      data['scannedAt'] = DateTime.now().toIso8601String();
      data['timestamp'] = FieldValue.serverTimestamp();

      final docRef = await db.collection('scanned_vegetables').add(data);
      return docRef.id;
    } catch (e) {
      debugPrint('Firebase saveVegetableScan error: $e');
      return null;
    }
  }

  /// Stream of all saved scanned vegetables from Firestore
  static Stream<List<Map<String, dynamic>>> watchSavedVegetables() {
    try {
      return FirebaseFirestore.instance
          .collection('scanned_vegetables')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((d) {
                final m = Map<String, dynamic>.from(d.data());
                m['id'] = d.id;
                return m;
              }).toList());
    } catch (_) {
      return Stream.value([]);
    }
  }

  /// Detect MIME type based on byte magic numbers
  static String detectMimeType(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  Future<VegetableResult> analyzeVegetableImageBytes(
    Uint8List imageBytes, {
    String? apiKeyOverride,
  }) async {
    final key = apiKeyOverride ?? await getApiKeyAsync();

    if (key.trim().isEmpty || key.trim().length < 15) {
      throw StateError(
        'Gemini API কী সেট করা নেই বা সঠিক নয়।\n'
        'দয়া করে উপরে 🔑 বাটনে চাপ দিয়ে আপনার Google AI Studio Gemini API Key যুক্ত করুন।',
      );
    }

    const promptText = '''
আপনি একজন বিশেষজ্ঞ কৃষি ও সবজি বিশেষজ্ঞ। এই ছবির সবজিটি পুঙ্খানুপুঙ্খভাবে শনাক্ত ও বিশ্লেষণ করুন।
উত্তরটি শুধুমাত্র নিচের খাঁটি JSON ফরম্যাটে দিন (কোনো অতিরিক্ত টেক্সট বা markdown কোড ব্লক ব্যবহার করবেন না):
{
  "isVegetable": true,
  "vegetableNameBengali": "শুধুমাত্র সবজির বাংলা নাম (যেমন: আলু, টমেটো, বেগুন, পেঁয়াজ, গাজর, ফুলকপি, বাঁধাকপি, শসা, পটল, করলা, কাঁচামরিচ, রসুন, আদা, লাউ, মিষ্টি কুমড়া, ঢ্যাঁড়শ)",
  "vegetableNameEnglish": "English Name",
  "scientificName": "Scientific / Latin botanical name, e.g. Solanum lycopersicum",
  "confidence": "উচ্চ",
  "detailsBengali": "সবজিটির সংক্ষিপ্ত পরিচয়, জাত ও সাধারণ কৃষি টিপস (২-৩ বাক্য)",
  "nutritionBengali": "পুষ্টিগুণ: ভিটামিন, খনিজ লবণ, ক্যালোরি ও স্বাস্থ্যগত উপকারিতা (২-৩ বাক্যে বাংলায় লিখুন)",
  "growingSeasonBengali": "বাংলাদেশে চাষের সবচেয়ে উপযোগী মৌসুম: উদাহরণ: রবি মৌসুম (কার্তিক-ফাল্গুন / অক্টোবর-মার্চ) অথবা খরিফ মৌসুম",
  "bestMonthBengali": "বাংলাদেশে কৃষকদের জন্য বীজ বপন বা চারা রোপণের সবচেয়ে উপযুক্ত মাস, উদাহরণ: অক্টোবর – নভেম্বর",
  "usesBengali": "সবজিটির ব্যবহার: রান্নায় ব্যবহার (তরকারি, ভর্তা, ভাজি, স্যুপ বা সালাদ), ঔষধি ব্যবহার ও সংরক্ষণ পদ্ধতি সম্পর্কে ২-৩ বাক্যে বাংলায় লিখুন",
  "regionalNamesBengali": "বাংলাদেশে বিভিন্ন বাজার বা অঞ্চলে এই সবজির আঞ্চলিক নাম ও বিভিন্ন জাতের নাম (যেমন: লাউ-এর আঞ্চলিক নাম কদু; মিষ্টি কুমড়াকে বলে মিঠা কদু; বিভিন্ন জাত যেমন গোল বেগুন, তাল বেগুন ইত্যাদি)"
}
যদি ছবিতে কোনো সবজি না থাকে, তবে "isVegetable": false দিন এবং "detailsBengali"-তে পরিষ্কার বাংলায় লিখুন যে এটি সবজির ছবি নয়। অন্যান্য ঘরগুলো খালি স্ট্রিং রাখুন।
''';

    final base64Image = base64Encode(imageBytes);
    final mimeType = detectMimeType(imageBytes);

    final modelsToTry = [
      'gemini-3.6-flash',
      'gemini-3.5-flash-lite',
      'gemini-3.1-flash-lite',
    ];

    String? responseText;
    final errorsEncountered = <String>[];

    // 1. Try GoogleGenerativeAI Official SDK first
    for (final modelName in modelsToTry) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: key,
        );
        final content = [
          Content.multi([
            TextPart(promptText),
            DataPart(mimeType, imageBytes),
          ])
        ];
        final resp = await model.generateContent(content).timeout(
          const Duration(seconds: 25),
        );
        if (resp.text != null && resp.text!.trim().isNotEmpty) {
          responseText = resp.text;
          break;
        }
      } catch (e) {
        errorsEncountered.add('SDK $modelName: $e');
      }
    }

    // 2. Fallback to Direct REST API (Without Authorization: Bearer, using x-goog-api-key)
    if (responseText == null || responseText.trim().isEmpty) {
      for (final modelName in modelsToTry) {
        try {
          final url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$key',
          );

          final headers = <String, String>{
            'Content-Type': 'application/json',
            'x-goog-api-key': key,
          };

          final body = jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': promptText},
                  {
                    'inline_data': {
                      'mime_type': mimeType,
                      'data': base64Image,
                    }
                  }
                ]
              }
            ]
          });

          final res = await http.post(url, headers: headers, body: body).timeout(
            const Duration(seconds: 25),
          );

          if (res.statusCode == 200) {
            final jsonRes = jsonDecode(res.body) as Map<String, dynamic>;
            final candidates = jsonRes['candidates'] as List?;
            if (candidates != null && candidates.isNotEmpty) {
              final parts = candidates[0]['content']?['parts'] as List?;
              if (parts != null && parts.isNotEmpty) {
                final text = parts[0]['text']?.toString();
                if (text != null && text.trim().isNotEmpty) {
                  responseText = text;
                  break;
                }
              }
            }
          } else {
            try {
              final errorJson = jsonDecode(res.body) as Map<String, dynamic>;
              final message = errorJson['error']?['message'] ?? 'HTTP ${res.statusCode}';
              errorsEncountered.add('$modelName: $message');
            } catch (_) {
              errorsEncountered.add('$modelName: HTTP ${res.statusCode}');
            }
          }
        } catch (e) {
          errorsEncountered.add('$modelName: $e');
        }
      }
    }

    // 3. Error verification: Never return a fake static vegetable!
    if (responseText == null || responseText.trim().isEmpty) {
      final joinedErrors = errorsEncountered.join(', ');
      if (joinedErrors.contains('API_KEY_INVALID') ||
          joinedErrors.contains('API key not valid') ||
          joinedErrors.contains('403') ||
          joinedErrors.contains('400')) {
        throw StateError(
          'Gemini API Key টি সঠিক নয় বা মেয়াদোত্তীর্ণ।\nদয়া করে সঠিক Gemini API Key প্রদান করুন।',
        );
      }
      if (joinedErrors.contains('RESOURCE_EXHAUSTED') || joinedErrors.contains('quota')) {
        throw StateError('Gemini API কোটা সীমা শেষ হয়ে গেছে। কিছুক্ষণ পরে চেষ্টা করুন।');
      }
      if (joinedErrors.contains('SocketException') || joinedErrors.contains('ClientException') || joinedErrors.contains('Failed host lookup')) {
        throw StateError('ইন্টারনেট সংযোগ সমস্যা। আপনার ইন্টারনেট সংযোগ পরীক্ষা করুন।');
      }
      throw StateError(
        'AI ছবিটি বিশ্লেষণ করতে পারেনি।\nত্রুটি: ${errorsEncountered.isNotEmpty ? errorsEncountered.first : 'কোনো তথ্য পাওয়া যায়নি'}',
      );
    }

    final rawText = responseText.trim();

    // Robust JSON extraction using regex to find JSON object {...}
    String cleanJson = rawText;
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(rawText);
    if (jsonMatch != null) {
      cleanJson = jsonMatch.group(0)!;
    } else {
      // Basic markdown removal fallback
      if (cleanJson.startsWith('```json')) cleanJson = cleanJson.substring(7);
      if (cleanJson.startsWith('```')) cleanJson = cleanJson.substring(3);
      if (cleanJson.endsWith('```')) cleanJson = cleanJson.substring(0, cleanJson.length - 3);
      cleanJson = cleanJson.trim();
    }

    try {
      final map = jsonDecode(cleanJson) as Map<String, dynamic>;
      return VegetableResult.fromMap(map);
    } catch (_) {
      // If JSON parsing fails, check if text has recognizable content
      return VegetableResult(
        isVegetable: true,
        vegetableNameBengali: rawText.split('\n').first.replaceAll(RegExp(r'[^\w\s\u0980-\u09FF]'), '').trim(),
        vegetableNameEnglish: 'Vegetable',
        confidence: 'মাঝারি',
        detailsBengali: rawText,
      );
    }
  }

  Future<VegetableResult> analyzeVegetableImage(
    dynamic imageInput, {
    String? apiKeyOverride,
  }) async {
    if (imageInput is Uint8List) {
      return analyzeVegetableImageBytes(imageInput, apiKeyOverride: apiKeyOverride);
    } else if (imageInput is XFile) {
      final bytes = await imageInput.readAsBytes();
      return analyzeVegetableImageBytes(bytes, apiKeyOverride: apiKeyOverride);
    } else if (imageInput != null) {
      final bytes = await (imageInput as dynamic).readAsBytes() as Uint8List;
      return analyzeVegetableImageBytes(bytes, apiKeyOverride: apiKeyOverride);
    } else {
      throw ArgumentError('অকার্যকর ছবি ইনপুট।');
    }
  }
}
