// lib/services/google_vision_service.dart - IMPROVED AI processing with better extraction
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
      print('🔍 Starting AI analysis of image: $imagePath');
      
      // Always try ML Kit first for faster processing
      final mlKitResult = await _processWithMLKit(imagePath);
      
      print('📊 ML Kit analysis complete - Confidence: ${mlKitResult.confidence}');
      
      // If ML Kit confidence is very low, try Cloud Vision API as fallback
      if (mlKitResult.confidence < 0.3 && _apiKey != 'YOUR_GOOGLE_VISION_API_KEY') {
        print('🌐 Trying Cloud Vision API for better results...');
        try {
          final cloudResult = await _processWithCloudVision(imagePath);
          print('📊 Cloud Vision analysis complete - Confidence: ${cloudResult.confidence}');
          
          // Return the better result
          if (cloudResult.confidence > mlKitResult.confidence) {
            return cloudResult;
          }
        } catch (e) {
          print('⚠️  Cloud Vision API failed, using ML Kit result: $e');
        }
      }
      
      return mlKitResult;
    } catch (e) {
      print('❌ AI processing failed: $e');
      
      // Return a result with extracted data even if processing failed
      return ScannedVaccinationData(
        vaccineName: 'Analyse incomplète',
        lot: '',
        date: _getCurrentDate(),
        ps: 'Veuillez vérifier et corriger les informations',
        confidence: 0.1,
      );
    }
  }

  Future<ScannedVaccinationData> _processWithMLKit(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer();
    
    try {
      print('🤖 Processing with ML Kit...');
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      print('📝 Extracted text (${recognizedText.text.length} chars):');
      print(recognizedText.text.substring(0, recognizedText.text.length > 200 ? 200 : recognizedText.text.length));
      
      final extractedData = _extractVaccinationData(recognizedText.text);
      
      return ScannedVaccinationData(
        vaccineName: extractedData['vaccine'] ?? 'Non détecté',
        lot: extractedData['lot'] ?? '',
        date: extractedData['date'] ?? _getCurrentDate(),
        ps: extractedData['ps'] ?? '',
        confidence: extractedData['confidence'] ?? 0.5,
      );
    } catch (e) {
      print('❌ ML Kit processing error: $e');
      rethrow;
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
            'languageHints': ['en', 'fr', 'es', 'de'] // Support multiple languages
          }
        }
      ]
    };

    print('🌐 Sending request to Cloud Vision API...');
    
    final response = await http.post(
      Uri.parse('$_baseUrl?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final detectedText = _extractTextFromResponse(jsonResponse);
      
      print('📝 Cloud Vision extracted text (${detectedText.length} chars):');
      print(detectedText.substring(0, detectedText.length > 200 ? 200 : detectedText.length));
      
      final extractedData = _extractVaccinationData(detectedText);
      
      return ScannedVaccinationData(
        vaccineName: extractedData['vaccine'] ?? 'Non détecté',
        lot: extractedData['lot'] ?? '',
        date: extractedData['date'] ?? _getCurrentDate(),
        ps: extractedData['ps'] ?? '',
        confidence: (extractedData['confidence'] ?? 0.6) + 0.2, // Boost confidence for Cloud Vision
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
      print('Error extracting text from response: $e');
      return '';
    }
  }

  // IMPROVED: Enhanced data extraction with more patterns and better logic
  Map<String, dynamic> _extractVaccinationData(String text) {
    print('🔍 Analyzing extracted text for vaccination data...');
    
    final lines = text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
    
    String vaccine = '';
    String lot = '';
    String date = '';
    String ps = '';
    double confidence = 0.2; // Start with base confidence

    // IMPROVED: More comprehensive vaccine name patterns
    final vaccinePatterns = [
      // COVID vaccines
      RegExp(r'(pfizer|biontech|comirnaty)', caseSensitive: false),
      RegExp(r'(moderna|spikevax)', caseSensitive: false),
      RegExp(r'(astrazeneca|vaxzevria|covishield)', caseSensitive: false),
      RegExp(r'(johnson|janssen|j&j)', caseSensitive: false),
      RegExp(r'(novavax|nuvaxovid)', caseSensitive: false),
      RegExp(r'(sinopharm|sinovac|coronavac)', caseSensitive: false),
      RegExp(r'(sputnik)', caseSensitive: false),
      
      // Traditional vaccines
      RegExp(r'(hepatitis|hepatite)\s*[ab]?', caseSensitive: false),
      RegExp(r'(measles|rougeole|mmr|ror)', caseSensitive: false),
      RegExp(r'(mumps|oreillons)', caseSensitive: false),
      RegExp(r'(rubella|rubéole)', caseSensitive: false),
      RegExp(r'(dtap|dtp|tétracoq)', caseSensitive: false),
      RegExp(r'(tetanus|tétanos)', caseSensitive: false),
      RegExp(r'(polio|poliomyélite)', caseSensitive: false),
      RegExp(r'(influenza|grippe|flu)', caseSensitive: false),
      RegExp(r'(pneumococcal|pneumocoque)', caseSensitive: false),
      RegExp(r'(meningococcal|méningocoque)', caseSensitive: false),
      RegExp(r'(yellow\s*fever|fièvre\s*jaune)', caseSensitive: false),
      RegExp(r'(typhoid|typhoïde)', caseSensitive: false),
      
      // Generic patterns
      RegExp(r'(?:vaccin|vaccine|immunization)[\s:]*([^\n\r]{1,50})', caseSensitive: false),
      RegExp(r'(?:covid|corona|sars[\-\s]*cov[\-\s]*2)[\s\-]*([^\n\r]{0,30})', caseSensitive: false),
    ];

    // IMPROVED: More lot number patterns
    final lotPatterns = [
      // Standard lot patterns
      RegExp(r'(?:lot|batch|série|serial)[\s#:]*([A-Z0-9\-]{3,15})', caseSensitive: false),
      RegExp(r'\b([A-Z]{2,4}[0-9]{3,8})\b'),
      RegExp(r'\b([0-9]{4,8}[A-Z]{1,4})\b'),
      RegExp(r'\b([A-Z0-9]{6,12})\b'), // Generic alphanumeric
      
      // COVID-specific lot patterns
      RegExp(r'\b(EW[0-9]{4})\b'), // Pfizer pattern
      RegExp(r'\b(FF[0-9]{4})\b'), // Pfizer pattern
      RegExp(r'\b([0-9]{6}[A-Z])\b'), // Moderna pattern
      RegExp(r'\b(ABW[0-9]{3})\b'), // AstraZeneca pattern
    ];

    // IMPROVED: Better date patterns
    final datePatterns = [
      // European format DD/MM/YYYY
      RegExp(r'(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})'),
      // American format MM/DD/YYYY
      RegExp(r'(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})'),
      // ISO format YYYY-MM-DD
      RegExp(r'(\d{4}[\/\-\.]\d{1,2}[\/\-\.]\d{1,2})'),
      // Date with text
      RegExp(r'(?:date|administered|given|injection|dose)[\s:]*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})', caseSensitive: false),
      // Month names
      RegExp(r'(\d{1,2}\s+(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+\d{2,4})', caseSensitive: false),
      RegExp(r'(\d{1,2}\s+(?:janvier|février|mars|avril|mai|juin|juillet|août|septembre|octobre|novembre|décembre)\s+\d{2,4})', caseSensitive: false),
    ];

    // IMPROVED: More comprehensive PS/additional info patterns
    final psPatterns = [
      RegExp(r'(?:dose|rappel|booster|première|deuxième|troisième|1ère|2ème|3ème)[\s:]*([^\n\r]{0,50})', caseSensitive: false),
      RegExp(r'(?:notes?|remarks?|observations?|commentaire)[\s:]*([^\n\r]{0,100})', caseSensitive: false),
      RegExp(r'(?:médecin|doctor|dr\.?|pharmacien|infirmier)[\s:]*([^\n\r]{0,50})', caseSensitive: false),
      RegExp(r'(?:site|lieu|location|center|centre)[\s:]*([^\n\r]{0,50})', caseSensitive: false),
    ];

    // Extract vaccine name - try multiple approaches
    for (final pattern in vaccinePatterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        String candidate = '';
        if (match.groupCount > 0 && match.group(1) != null) {
          candidate = match.group(1)!.trim();
        } else {
          candidate = match.group(0)!.trim();
        }
        
        if (candidate.isNotEmpty && candidate.length > vaccine.length) {
          vaccine = candidate;
          confidence += 0.25;
          print('✅ Found vaccine: $vaccine');
        }
      }
    }

    // If no specific vaccine found, look for any line that might be a vaccine name
    if (vaccine.isEmpty) {
      for (final line in lines) {
        if (line.length > 3 && line.length < 50 && 
            !RegExp(r'^\d+$').hasMatch(line) && // Not just numbers
            !RegExp(r'^[\/\-\.]+$').hasMatch(line)) { // Not just punctuation
          vaccine = line;
          confidence += 0.1;
          print('📝 Guessed vaccine from line: $vaccine');
          break;
        }
      }
    }

    // Extract lot number
    for (final pattern in lotPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        String candidate = '';
        if (match.groupCount > 0 && match.group(1) != null) {
          candidate = match.group(1)!.trim();
        } else {
          candidate = match.group(0)!.trim();
        }
        
        if (candidate.isNotEmpty && candidate.length > 2) {
          lot = candidate;
          confidence += 0.2;
          print('✅ Found lot: $lot');
          break;
        }
      }
    }

    // Extract date
    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        String candidate = '';
        if (match.groupCount > 0 && match.group(1) != null) {
          candidate = match.group(1)!.trim();
        } else {
          candidate = match.group(0)!.trim();
        }
        
        if (candidate.isNotEmpty && _isValidDateFormat(candidate)) {
          date = _normalizeDate(candidate);
          confidence += 0.2;
          print('✅ Found date: $date');
          break;
        }
      }
    }

    // If no date found, use current date as fallback
    if (date.isEmpty) {
      date = _getCurrentDate();
      print('📅 Using current date as fallback: $date');
    }

    // Extract PS/additional info
    for (final pattern in psPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        String candidate = '';
        if (match.groupCount > 0 && match.group(1) != null) {
          candidate = match.group(1)!.trim();
        } else {
          candidate = match.group(0)!.trim();
        }
        
        if (candidate.isNotEmpty && candidate.length > ps.length) {
          ps = candidate;
          confidence += 0.1;
          print('✅ Found PS info: $ps');
        }
      }
    }

    // Boost confidence if we found multiple fields
    int fieldsFound = 0;
    if (vaccine.isNotEmpty) fieldsFound++;
    if (lot.isNotEmpty) fieldsFound++;
    if (date.isNotEmpty) fieldsFound++;
    if (ps.isNotEmpty) fieldsFound++;

    confidence += fieldsFound * 0.05;

    // Ensure minimum confidence for any result
    confidence = confidence.clamp(0.3, 1.0);

    print('📊 Extraction complete:');
    print('  Vaccine: "$vaccine"');
    print('  Lot: "$lot"');
    print('  Date: "$date"');
    print('  PS: "$ps"');
    print('  Confidence: ${(confidence * 100).toStringAsFixed(1)}%');

    return {
      'vaccine': vaccine,
      'lot': lot,
      'date': date,
      'ps': ps,
      'confidence': confidence,
    };
  }

  bool _isValidDateFormat(String dateStr) {
    // Check various date formats
    final patterns = [
      RegExp(r'^\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4}$'),
      RegExp(r'^\d{4}[\/\-\.]\d{1,2}[\/\-\.]\d{1,2}$'),
      RegExp(r'^\d{1,2}\s+\w+\s+\d{2,4}$'),
    ];

    return patterns.any((pattern) => pattern.hasMatch(dateStr));
  }

  String _normalizeDate(String dateStr) {
    try {
      // Try to parse and normalize to DD/MM/YYYY format
      // This is a simple implementation - you might want more sophisticated parsing
      
      // Handle DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY
      if (RegExp(r'^\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4}$').hasMatch(dateStr)) {
        final parts = dateStr.split(RegExp(r'[\/\-\.]'));
        if (parts.length == 3) {
          final day = parts[0].padLeft(2, '0');
          final month = parts[1].padLeft(2, '0');
          String year = parts[2];
          
          // Convert 2-digit year to 4-digit
          if (year.length == 2) {
            final currentYear = DateTime.now().year;
            final currentCentury = (currentYear ~/ 100) * 100;
            final twoDigitYear = int.parse(year);
            
            // Assume years 00-30 are 20xx, 31-99 are 19xx
            if (twoDigitYear <= 30) {
              year = (currentCentury + twoDigitYear).toString();
            } else {
              year = (currentCentury - 100 + twoDigitYear).toString();
            }
          }
          
          return '$day/$month/$year';
        }
      }
      
      // Return as-is if can't normalize
      return dateStr;
    } catch (e) {
      return dateStr;
    }
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  // REMOVED: isValidVaccinationCard method since we're skipping validation
}