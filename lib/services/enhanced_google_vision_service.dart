// lib/services/enhanced_google_vision_service.dart - UNIFIED VERSION with all benefits
import 'dart:io';
import 'dart:typed_data';
import '../models/scanned_vaccination_data.dart';
import '../services/enhanced_french_vaccination_parser_with_fuzzy.dart';
import '../services/vaccine_name_corrector.dart';

/// Unified Enhanced Google Vision Service
/// Consolidates all vision processing capabilities with fuzzy matching and multi-vaccination support
class EnhancedGoogleVisionService {
  static const String _apiKey = 'YOUR_GOOGLE_VISION_API_KEY';
  static const String _visionApiUrl = 'https://vision.googleapis.com/v1/images:annotate';
  
  final EnhancedFrenchVaccinationParser _parser = EnhancedFrenchVaccinationParser();
  
  /// Process a vaccination card image and extract vaccination data
  /// Supports both single and multi-vaccination detection
  Future<List<VaccinationEntry>> processVaccinationCard(String imagePath) async {
    try {
      print('🔍 Processing vaccination card: $imagePath');
      
      // Validate image file
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Image file not found: $imagePath');
      }
      
      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('Empty image file');
      }
      
      if (fileSize > 50 * 1024 * 1024) { // 50MB limit
        throw Exception('Image file too large (max 50MB)');
      }
      
      print('📄 Image validated: ${(fileSize / 1024).toStringAsFixed(1)}KB');
      
      // Extract text using Google Vision API
      final extractedText = await _extractTextFromImage(imagePath);
      
      if (extractedText.isEmpty) {
        print('⚠️ No text extracted from image');
        return [_createFallbackEntry()];
      }
      
      print('📝 Extracted text length: ${extractedText.length} characters');
      
      // Process with enhanced parser
      final vaccinations = await _parser.processVaccinationCard(imagePath);
      
      if (vaccinations.isEmpty) {
        print('⚠️ No vaccinations detected, creating fallback');
        return [_createFallbackEntry()];
      }
      
      print('✅ Detected ${vaccinations.length} vaccination(s)');
      return vaccinations;
      
    } catch (e) {
      print('❌ Error processing vaccination card: $e');
      return [_createFallbackEntry(error: e.toString())];
    }
  }
  
  /// Process a single vaccination image (legacy support)
  /// Returns a single ScannedVaccinationData for backward compatibility
  Future<ScannedVaccinationData> processVaccinationImage(String imagePath) async {
    try {
      final vaccinations = await processVaccinationCard(imagePath);
      
      if (vaccinations.isEmpty) {
        return ScannedVaccinationData.fallback(
          errorMessage: 'No vaccinations detected',
        );
      }
      
      // Convert first vaccination to ScannedVaccinationData
      final first = vaccinations.first;
      return ScannedVaccinationData(
        vaccineName: first.vaccineName,
        lot: first.lot,
        date: first.date,
        ps: first.ps,
        confidence: first.confidence,
      );
      
    } catch (e) {
      print('❌ Error in processVaccinationImage: $e');
      return ScannedVaccinationData.fallback(
        errorMessage: e.toString(),
      );
    }
  }
  
  /// Extract text from image using Google Vision API with preprocessing
  Future<String> _extractTextFromImage(String imagePath) async {
    try {
      // Preprocess image for better OCR results
      final preprocessedPath = await _preprocessImage(imagePath);
      
      // Read and encode image
      final imageBytes = await File(preprocessedPath).readAsBytes();
      final base64Image = _encodeImageToBase64(imageBytes);
      
      // Call Google Vision API
      final response = await _callGoogleVisionAPI(base64Image);
      
      // Extract text from response
      final extractedText = _parseVisionResponse(response);
      
      // Clean up preprocessed file if different
      if (preprocessedPath != imagePath) {
        try {
          await File(preprocessedPath).delete();
        } catch (e) {
          print('⚠️ Could not delete preprocessed file: $e');
        }
      }
      
      return extractedText;
      
    } catch (e) {
      print('❌ Error extracting text: $e');
      rethrow;
    }
  }
  
  /// Preprocess image for better OCR results
  Future<String> _preprocessImage(String imagePath) async {
    // For now, return original path
    // In a real implementation, you would:
    // 1. Adjust brightness/contrast
    // 2. Sharpen image
    // 3. Remove noise
    // 4. Correct perspective
    // 5. Resize if needed
    
    print('🔧 Image preprocessing (placeholder)');
    return imagePath;
  }
  
  /// Encode image to base64 for API call
  String _encodeImageToBase64(Uint8List imageBytes) {
    try {
      // In a real implementation, use:
      // import 'dart:convert';
      // return base64Encode(imageBytes);
      
      print('🔧 Encoding image to base64 (${imageBytes.length} bytes)');
      return 'base64_encoded_image_placeholder';
    } catch (e) {
      print('❌ Error encoding image: $e');
      rethrow;
    }
  }
  
  /// Call Google Vision API with retry logic
  Future<Map<String, dynamic>> _callGoogleVisionAPI(String base64Image) async {
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('🌐 Calling Google Vision API (attempt $attempt/$maxRetries)');
        
        // In a real implementation:
        // 1. Create HTTP request to Google Vision API
        // 2. Include authentication
        // 3. Set proper headers
        // 4. Handle rate limiting
        // 5. Parse JSON response
        
        // Simulate API call delay
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Mock successful response
        return {
          'responses': [
            {
              'textAnnotations': [
                {
                  'description': _generateMockOCRText(),
                }
              ]
            }
          ]
        };
        
      } catch (e) {
        print('❌ Vision API attempt $attempt failed: $e');
        
        if (attempt == maxRetries) {
          rethrow;
        }
        
        await Future.delayed(retryDelay);
      }
    }
    
    throw Exception('All Vision API attempts failed');
  }
  
  /// Parse Google Vision API response
  String _parseVisionResponse(Map<String, dynamic> response) {
    try {
      final responses = response['responses'] as List?;
      if (responses == null || responses.isEmpty) {
        throw Exception('No responses in Vision API result');
      }
      
      final firstResponse = responses.first as Map<String, dynamic>;
      final textAnnotations = firstResponse['textAnnotations'] as List?;
      
      if (textAnnotations == null || textAnnotations.isEmpty) {
        throw Exception('No text annotations found');
      }
      
      final fullText = textAnnotations.first['description'] as String? ?? '';
      
      print('📝 Extracted ${fullText.length} characters of text');
      return fullText;
      
    } catch (e) {
      print('❌ Error parsing Vision response: $e');
      return '';
    }
  }
  
  /// Generate mock OCR text for testing
  String _generateMockOCRText() {
    return '''
CARNET DE VACCINATION INTERNATIONAL
Nom: DUPONT Jean
Date de naissance: 15/03/1985

VACCINATIONS:
COVID-19 - Pfizer-BioNTech - 12/03/2021 - Lot: EW0150 - Dr. Martin
COVID-19 - Pfizer-BioNTech - 05/05/2021 - Lot: EW0553 - Dr. Martin
Grippe - Vaxigrip Tetra - 15/10/2021 - Lot: U602A - Pharmacie Centrale
Tétanos - Revaxis - 20/01/2020 - Lot: L7B34 - Dr. Dubois
''';
  }
  
  /// Create fallback vaccination entry when detection fails
  VaccinationEntry _createFallbackEntry({String? error}) {
    final currentDate = DateTime.now();
    final formattedDate = '${currentDate.day.toString().padLeft(2, '0')}/${currentDate.month.toString().padLeft(2, '0')}/${currentDate.year}';
    
    return VaccinationEntry(
      vaccineName: 'Vaccination détectée',
      standardizedName: '',
      date: formattedDate,
      lot: '',
      ps: error != null ? 'Erreur: $error' : 'Données à vérifier',
      confidence: 0.3,
      nameConfidence: 0.0,
      lineNumber: 1,
      rawLine: 'Données extraites automatiquement',
      alternativeNames: [],
    );
  }
  
  /// Enhanced text preprocessing with multiple techniques
  String enhanceTextForProcessing(String rawText) {
    try {
      String enhanced = rawText;
      
      // 1. Normalize whitespace
      enhanced = enhanced.replaceAll(RegExp(r'\s+'), ' ');
      
      // 2. Fix common OCR errors
      enhanced = _fixCommonOCRErrors(enhanced);
      
      // 3. Standardize date formats
      enhanced = _standardizeDateFormats(enhanced);
      
      // 4. Clean up lot numbers
      enhanced = _cleanupLotNumbers(enhanced);
      
      // 5. Correct vaccine names using fuzzy matching
      enhanced = _correctVaccineNames(enhanced);
      
      print('🔧 Text enhancement complete');
      return enhanced;
      
    } catch (e) {
      print('⚠️ Text enhancement failed: $e');
      return rawText;
    }
  }
  
  /// Fix common OCR character recognition errors
  String _fixCommonOCRErrors(String text) {
    return text
        .replaceAll('0', 'O') // In vaccine names, 0 is often O
        .replaceAll('5', 'S') // In some contexts
        .replaceAll('1', 'I') // In some vaccine names
        .replaceAll('8', 'B') // Common confusion
        .replaceAll(RegExp(r'[|]'), 'I'); // Pipes as I
  }
  
  /// Standardize various date formats to DD/MM/YYYY
  String _standardizeDateFormats(String text) {
    // Convert DD-MM-YYYY to DD/MM/YYYY
    text = text.replaceAll(RegExp(r'(\d{2})-(\d{2})-(\d{4})'), r'$1/$2/$3');
    
    // Convert DD.MM.YYYY to DD/MM/YYYY  
    text = text.replaceAll(RegExp(r'(\d{2})\.(\d{2})\.(\d{4})'), r'$1/$2/$3');
    
    // Convert YYYY-MM-DD to DD/MM/YYYY
    text = text.replaceAll(RegExp(r'(\d{4})-(\d{2})-(\d{2})'), r'$3/$2/$1');
    
    return text;
  }
  
  /// Clean up lot number formats
  String _cleanupLotNumbers(String text) {
    // Remove common prefixes/suffixes that OCR adds
    text = text.replaceAll(RegExp(r'Lot[:\s]*([A-Z0-9]+)', caseSensitive: false), 'Lot: \$1');
    text = text.replaceAll(RegExp(r'Série[:\s]*([A-Z0-9]+)', caseSensitive: false), 'Lot: \$1');
    
    return text;
  }
  
  /// Correct vaccine names using fuzzy matching
  String _correctVaccineNames(String text) {
    // Split text into lines and check each for vaccine names
    final lines = text.split('\n');
    final correctedLines = <String>[];
    
    for (final line in lines) {
      String correctedLine = line;
      
      // Try to find vaccine names in the line
      final words = line.split(RegExp(r'\s+'));
      for (int i = 0; i < words.length - 1; i++) {
        final potential = '${words[i]} ${words[i + 1]}';
        final correction = VaccineNameCorrector.correctVaccineName(potential);
        
        if (correction.confidence > 0.7) {
          correctedLine = correctedLine.replaceAll(potential, correction.standardizedName);
          print('🔧 Corrected "$potential" → "${correction.standardizedName}"');
        }
      }
      
      correctedLines.add(correctedLine);
    }
    
    return correctedLines.join('\n');
  }
  
  /// Advanced multi-vaccination detection
  Future<List<VaccinationEntry>> detectMultipleVaccinations(String text) async {
    try {
      print('🔍 Detecting multiple vaccinations in text');
      
      // Enhance text first
      final enhancedText = enhanceTextForProcessing(text);
      
      // Use the enhanced parser for multi-vaccination detection
      final parser = EnhancedFrenchVaccinationParser();
      
      // Create a temporary file for the parser (it expects a file path)
      final tempFile = File('${Directory.systemTemp.path}/temp_ocr_text.txt');
      await tempFile.writeAsString(enhancedText);
      
      try {
        // Process with enhanced parser
        final vaccinations = await parser.processVaccinationCard(tempFile.path);
        
        print('✅ Detected ${vaccinations.length} vaccinations');
        return vaccinations;
        
      } finally {
        // Clean up temp file
        try {
          await tempFile.delete();
        } catch (e) {
          print('⚠️ Could not delete temp file: $e');
        }
      }
      
    } catch (e) {
      print('❌ Error in multi-vaccination detection: $e');
      return [_createFallbackEntry(error: e.toString())];
    }
  }
  
  /// Get processing statistics
  Map<String, dynamic> getProcessingStats(List<VaccinationEntry> vaccinations) {
    if (vaccinations.isEmpty) {
      return {
        'total': 0,
        'reliable': 0,
        'needsReview': 0,
        'averageConfidence': 0.0,
        'standardizedCount': 0,
      };
    }
    
    final reliable = vaccinations.where((v) => v.isReliable).length;
    final needsReview = vaccinations.where((v) => v.needsReview).length;
    final avgConfidence = vaccinations.map((v) => v.confidence).reduce((a, b) => a + b) / vaccinations.length;
    final standardized = vaccinations.where((v) => v.standardizedName.isNotEmpty).length;
    
    return {
      'total': vaccinations.length,
      'reliable': reliable,
      'needsReview': needsReview,
      'averageConfidence': avgConfidence,
      'standardizedCount': standardized,
    };
  }
  
  /// Batch process multiple images
  Future<List<List<VaccinationEntry>>> processBatchImages(List<String> imagePaths) async {
    final results = <List<VaccinationEntry>>[];
    
    print('📷 Processing batch of ${imagePaths.length} images');
    
    for (int i = 0; i < imagePaths.length; i++) {
      try {
        print('📷 Processing image ${i + 1}/${imagePaths.length}: ${imagePaths[i]}');
        final vaccinations = await processVaccinationCard(imagePaths[i]);
        results.add(vaccinations);
        
        // Add small delay to avoid overwhelming the API
        if (i < imagePaths.length - 1) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
        
      } catch (e) {
        print('❌ Error processing image ${i + 1}: $e');
        results.add([_createFallbackEntry(error: e.toString())]);
      }
    }
    
    print('✅ Batch processing complete: ${results.length} results');
    return results;
  }
  
  /// Validate image before processing
  static Future<bool> validateImage(String imagePath) async {
    try {
      final file = File(imagePath);
      
      if (!await file.exists()) {
        print('❌ Image file does not exist: $imagePath');
        return false;
      }
      
      final size = await file.length();
      if (size == 0) {
        print('❌ Image file is empty');
        return false;
      }
      
      if (size > 50 * 1024 * 1024) {
        print('❌ Image file too large: ${(size / 1024 / 1024).toStringAsFixed(1)}MB');
        return false;
      }
      
      // Check file extension
      final extension = imagePath.toLowerCase().split('.').last;
      final supportedExtensions = ['jpg', 'jpeg', 'png', 'webp', 'bmp'];
      
      if (!supportedExtensions.contains(extension)) {
        print('❌ Unsupported image format: $extension');
        return false;
      }
      
      print('✅ Image validation passed: ${(size / 1024).toStringAsFixed(1)}KB');
      return true;
      
    } catch (e) {
      print('❌ Image validation error: $e');
      return false;
    }
  }
  
  /// Dispose resources and cleanup
  void dispose() {
    print('🧹 Disposing EnhancedGoogleVisionService');
    // Clean up any resources, temp files, etc.
  }
}