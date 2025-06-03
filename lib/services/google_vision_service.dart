// lib/services/google_vision_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:google_ml_kit/google_ml_kit.dart';
import '../models/scanned_vaccination_data.dart';

class GoogleVisionService {
  // Replace with your Google Cloud Vision API key
  static const String _apiKey = 'YOUR_GOOGLE_VISION_API_KEY';
  static const String _baseUrl = 'https://vision.googleapis.com/v1/images:annotate';

  Future<ScannedVaccinationData> processVaccinationImage(String imagePath) async {
    try {
      // First try with on-device ML Kit for quick processing
      final mlKitResult = await _processWithMLKit(imagePath);
      
      // If ML Kit confidence is low, fallback to Cloud Vision API
      if (mlKitResult.confidence < 0.7) {
        return await _processWithCloudVision(imagePath);
      }
      
      return mlKitResult;
    } catch (e) {
      throw Exception('Failed to process image: $e');
    }
  }

  Future<ScannedVaccinationData> _processWithMLKit(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer();
    
    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      final extractedData = _extractVaccinationData(recognizedText.text);
      
      return ScannedVaccinationData(
        vaccineName: extractedData['vaccine'] ?? '',
        lot: extractedData['lot'] ?? '',
        date: extractedData['date'] ?? '',
        ps: extractedData['ps'] ?? '',
        confidence: extractedData['confidence'] ?? 0.6,
      );
    } finally {
      textRecognizer.close();
    }
  }

  Future<ScannedVaccinationData> _processWithCloudVision(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final base64Image = base64Encode(bytes);

    final requestBody = {
      'requests': [
        {
          'image': {'content': base64Image},
          'features': [
            {'type': 'TEXT_DETECTION', 'maxResults': 1},
            {'type': 'DOCUMENT_TEXT_DETECTION', 'maxResults': 1}
          ],
          'imageContext': {
            'languageHints': ['en', 'fr']
          }
        }
      ]
    };

    final response = await http.post(
      Uri.parse('$_baseUrl?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final detectedText = _extractTextFromResponse(jsonResponse);
      final extractedData = _extractVaccinationData(detectedText);
      
      return ScannedVaccinationData(
        vaccineName: extractedData['vaccine'] ?? '',
        lot: extractedData['lot'] ?? '',
        date: extractedData['date'] ?? '',
        ps: extractedData['ps'] ?? '',
        confidence: extractedData['confidence'] ?? 0.8,
      );
    } else {
      throw Exception('Vision API error: ${response.statusCode} - ${response.body}');
    }
  }

  String _extractTextFromResponse(Map<String, dynamic> response) {
    try {
      final annotations = response['responses'][0]['textAnnotations'];
      if (annotations != null && annotations.isNotEmpty) {
        return annotations[0]['description'] ?? '';
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  Map<String, dynamic> _extractVaccinationData(String text) {
    //final lines = text.split('\n').map((line) => line.trim()).toList();
    
    String vaccine = '';
    String lot = '';
    String date = '';
    String ps = '';
    double confidence = 0.5;

    // Vaccination name patterns
    final vaccinePatterns = [
      RegExp(r'(?:vaccin|vaccine|immunization)[\s:]*([^\n\r]*)', caseSensitive: false),
      RegExp(r'(pfizer|moderna|astrazeneca|johnson|janssen|novavax|sinopharm|sinovac|sputnik)[\s\-]*([^\n\r]*)', caseSensitive: false),
      RegExp(r'(covid|corona|sars[\-\s]*cov[\-\s]*2)[\s\-]*([^\n\r]*)', caseSensitive: false),
      RegExp(r'(hepatitis|measles|mumps|rubella|mmr|dtap|tetanus|polio|influenza|flu)[\s\-]*([^\n\r]*)', caseSensitive: false),
    ];

    // Lot number patterns
    final lotPatterns = [
      RegExp(r'(?:lot|batch|série)[\s#:]*([A-Z0-9\-]+)', caseSensitive: false),
      RegExp(r'\b([A-Z]{2,3}[0-9]{4,6})\b'),
      RegExp(r'\b([0-9]{4,8}[A-Z]{1,3})\b'),
    ];

    // Date patterns
    final datePatterns = [
      RegExp(r'(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})'),
      RegExp(r'(\d{2,4}[\/\-\.]\d{1,2}[\/\-\.]\d{1,2})'),
      RegExp(r'(?:date|administered|given)[\s:]*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})', caseSensitive: false),
    ];

    // PS/Additional info patterns
    final psPatterns = [
      RegExp(r'(?:dose|rappel|booster|première|deuxième|troisième)[\s:]*([^\n\r]*)', caseSensitive: false),
      RegExp(r'(?:notes?|remarks?|observations?)[\s:]*([^\n\r]*)', caseSensitive: false),
    ];

    // Extract vaccine name
    for (final pattern in vaccinePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        vaccine = match.group(1)?.trim() ?? match.group(0)?.trim() ?? '';
        if (vaccine.isNotEmpty) {
          confidence += 0.2;
          break;
        }
      }
    }

    // Extract lot number
    for (final pattern in lotPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        lot = match.group(1)?.trim() ?? match.group(0)?.trim() ?? '';
        if (lot.isNotEmpty) {
          confidence += 0.15;
          break;
        }
      }
    }

    // Extract date
    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        date = match.group(1)?.trim() ?? match.group(0)?.trim() ?? '';
        if (date.isNotEmpty) {
          confidence += 0.15;
          break;
        }
      }
    }

    // Extract PS/additional info
    for (final pattern in psPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        ps = match.group(1)?.trim() ?? '';
        if (ps.isNotEmpty) {
          confidence += 0.1;
          break;
        }
      }
    }

    // Validate extracted data
    if (vaccine.isEmpty || lot.isEmpty || date.isEmpty) {
      confidence *= 0.5; // Reduce confidence if critical fields are missing
    }

    return {
      'vaccine': vaccine,
      'lot': lot,
      'date': date,
      'ps': ps,
      'confidence': confidence.clamp(0.0, 1.0),
    };
  }

  Future<bool> isValidVaccinationCard(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final textRecognizer = TextRecognizer();
      
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      textRecognizer.close();
      
      final text = recognizedText.text.toLowerCase();
      
      // Check for vaccination-related keywords
      final keywords = [
        'vaccin', 'vaccine', 'immunization', 'vaccination',
        'pfizer', 'moderna', 'astrazeneca', 'johnson',
        'covid', 'coronavirus', 'sars-cov-2',
        'lot', 'batch', 'dose', 'administered',
        'hepatitis', 'measles', 'mumps', 'rubella'
      ];
      
      int keywordCount = 0;
      for (final keyword in keywords) {
        if (text.contains(keyword)) {
          keywordCount++;
        }
      }
      
      // Require at least 2 vaccination-related keywords
      return keywordCount >= 2;
    } catch (e) {
      return false;
    }
  }
}