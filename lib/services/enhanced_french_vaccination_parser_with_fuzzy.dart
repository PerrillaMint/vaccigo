// lib/services/enhanced_french_vaccination_parser_with_fuzzy.dart
import 'dart:convert';
import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';
import '../models/scanned_vaccination_data.dart';
import '../models/vaccination.dart';
import 'vaccine_name_corrector.dart';

class VaccinationEntry {
  final String vaccineName;
  final String standardizedName;
  final String lot;
  final String date;
  final String ps;
  final double confidence;
  final double nameConfidence;
  final int lineNumber;
  final String rawLine;
  final List<String> alternativeNames;

  VaccinationEntry({
    required this.vaccineName,
    required this.standardizedName,
    required this.lot,
    required this.date,
    required this.ps,
    required this.confidence,
    required this.nameConfidence,
    required this.lineNumber,
    required this.rawLine,
    this.alternativeNames = const [],
  });

  bool get isReliable => confidence >= 0.8 && nameConfidence >= 0.8;
  bool get needsReview => confidence >= 0.7 || nameConfidence >= 0.7;

  @override
  String toString() {
    return 'VaccinationEntry(line: $lineNumber, date: $date, vaccine: $vaccineName → $standardizedName, confidence: ${(confidence * 100).toStringAsFixed(1)}%, name confidence: ${(nameConfidence * 100).toStringAsFixed(1)}%)';
  }
}

class EnhancedFrenchVaccinationParser {
  
  // === MAIN PROCESSING METHOD ===
  Future<List<VaccinationEntry>> processVaccinationCard(String imagePath) async {
    try {
      print('🔍 Processing French vaccination card with fuzzy matching: $imagePath');
      
      final extractedText = await _extractTextFromImage(imagePath);
      print('📝 Extracted text (${extractedText.length} characters)');
      
      if (extractedText.isEmpty) {
        print('❌ No text detected');
        return [];
      }
      
      // Print extracted text for debugging
      print('📄 Raw extracted text:');
      print(extractedText.substring(0, extractedText.length > 500 ? 500 : extractedText.length));
      print('=' * 50);
      
      // Parse the vaccination entries with fuzzy matching
      final vaccinations = _parseVaccinationEntries(extractedText);
      
      print('✅ ${vaccinations.length} vaccination(s) found with fuzzy matching');
      for (final vaccination in vaccinations) {
        print('  📋 $vaccination');
      }
      
      return vaccinations;
      
    } catch (e) {
      print('❌ Error processing vaccination card: $e');
      return [];
    }
  }

  // === TEXT EXTRACTION ===
  Future<String> _extractTextFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();
      
      return recognizedText.text;
    } catch (e) {
      print('❌ Error extracting text: $e');
      return '';
    }
  }

  // === VACCINATION ENTRIES PARSING WITH FUZZY MATCHING ===
  List<VaccinationEntry> _parseVaccinationEntries(String text) {
    final lines = text.split('\n');
    final vaccinations = <VaccinationEntry>[];
    
    print('📋 Analyzing ${lines.length} lines for vaccination entries with fuzzy matching...');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (line.isEmpty || line.length < 5) continue;
      
      // Skip obvious header lines
      if (_isHeaderLine(line)) {
        print('🏷️  Line ${i + 1}: HEADER - $line');
        continue;
      }
      
      // Look for lines with dates (key indicator of vaccination entries)
      final dateMatch = _findDateInLine(line);
      
      if (dateMatch != null) {
        print('📅 Line ${i + 1}: DATE FOUND - $line');
        final vaccination = _parseVaccinationLineWithFuzzy(line, dateMatch, i + 1);
        
        if (vaccination != null) {
          vaccinations.add(vaccination);
          print('✅ Line ${i + 1}: VACCINATION PARSED WITH FUZZY MATCHING');
          print('   Original: "${vaccination.vaccineName}"');
          print('   Standardized: "${vaccination.standardizedName}"');
          print('   Name Confidence: ${(vaccination.nameConfidence * 100).toStringAsFixed(1)}%');
          if (vaccination.alternativeNames.isNotEmpty) {
            print('   Alternatives: ${vaccination.alternativeNames.join(', ')}');
          }
        } else {
          print('❌ Line ${i + 1}: FAILED TO PARSE - $line');
        }
      } else {
        print('⏭️  Line ${i + 1}: NO DATE - $line');
      }
    }
    
    return _validateAndCleanVaccinations(vaccinations);
  }

  // === DATE DETECTION ===
  RegExpMatch? _findDateInLine(String line) {
    // French date patterns - be flexible with separators
    final datePatterns = [
      RegExp(r'\b(\d{1,2})[\/\.\-\s](\d{1,2})[\/\.\-\s](\d{2,4})\b'),  // DD/MM/YY or DD/MM/YYYY
      RegExp(r'\b(\d{1,2})\s+(\d{1,2})\s+(\d{2,4})\b'),                // DD MM YY
      RegExp(r'(\d{1,2})[\/\.\-](\d{1,2})[\/\.\-](\d{2,4})'),          // More flexible
    ];
    
    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(line);
      if (match != null) {
        // Validate date components
        final day = int.tryParse(match.group(1)!);
        final month = int.tryParse(match.group(2)!);
        final year = int.tryParse(match.group(3)!);
        
        if (day != null && month != null && year != null &&
            day >= 1 && day <= 31 && month >= 1 && month <= 12) {
          return match;
        }
      }
    }
    
    return null;
  }

  // === VACCINATION LINE PARSING WITH FUZZY MATCHING ===
  VaccinationEntry? _parseVaccinationLineWithFuzzy(String line, RegExpMatch dateMatch, int lineNumber) {
    try {
      // Extract and normalize date
      final day = dateMatch.group(1)!.padLeft(2, '0');
      final month = dateMatch.group(2)!.padLeft(2, '0');
      final yearStr = dateMatch.group(3)!;
      
      String year = yearStr;
      if (yearStr.length == 2) {
        final yr = int.parse(yearStr);
        year = yr <= 30 ? '20$yearStr' : '19$yearStr';
      }
      
      final formattedDate = '$day/$month/$year';
      
      // Remove date from line to extract other information
      String remainingLine = line.replaceAll(dateMatch.group(0)!, '').trim();
      
      // Clean up the remaining line
      remainingLine = remainingLine.replaceAll(RegExp(r'\s+'), ' ').trim();
      
      print('🔍 Parsing line with fuzzy matching: "$line"');
      print('📅 Date: $formattedDate');
      print('📝 Remaining: "$remainingLine"');
      
      // Extract lot number (usually alphanumeric codes)
      String lot = _extractLotNumber(remainingLine);
      if (lot.isNotEmpty) {
        remainingLine = remainingLine.replaceAll(lot, '').trim();
        remainingLine = remainingLine.replaceAll(RegExp(r'\s+'), ' ').trim();
      }
      
      print('💊 Lot: "$lot"');
      print('🩹 After lot removal: "$remainingLine"');
      
      // === FUZZY MATCHING FOR VACCINE NAME ===
      String originalVaccineName = _extractRawVaccineName(remainingLine);
      print('🔍 Raw vaccine name extracted: "$originalVaccineName"');
      
      // Apply fuzzy string matching correction
      MatchResult fuzzyMatch;
      if (originalVaccineName.isNotEmpty) {
        fuzzyMatch = VaccineNameCorrector.correctVaccineName(originalVaccineName);
        print('🎯 Fuzzy match result: $fuzzyMatch');
      } else {
        // Try to match the entire remaining line if no clear vaccine name
        fuzzyMatch = VaccineNameCorrector.correctVaccineName(remainingLine);
        originalVaccineName = remainingLine.isNotEmpty ? remainingLine : 'Vaccination détectée';
        print('🎯 Fuzzy match on full line: $fuzzyMatch');
      }
      
      // Use corrected name if confidence is high enough
      String finalVaccineName;
      String standardizedName;
      double nameConfidence;
      List<String> alternatives = [];
      
      if (fuzzyMatch.confidence >= 0.7) {
        finalVaccineName = fuzzyMatch.correctedName;
        standardizedName = fuzzyMatch.standardizedName;
        nameConfidence = fuzzyMatch.confidence;
        alternatives = fuzzyMatch.alternatives;
        print('✅ Using fuzzy corrected name: "$finalVaccineName" → "$standardizedName"');
      } else {
        // Keep original but try to clean it up
        finalVaccineName = originalVaccineName.isNotEmpty ? originalVaccineName : 'Vaccination détectée';
        standardizedName = 'Vaccination non standardisée';
        nameConfidence = fuzzyMatch.confidence;
        
        // Try to find multiple matches for manual review
        final multipleMatches = VaccineNameCorrector.findMultipleMatches(originalVaccineName, maxResults: 3);
        alternatives = multipleMatches.map((m) => m.standardizedName).toList();
        
        print('⚠️  Low confidence match, keeping original: "$finalVaccineName"');
        if (alternatives.isNotEmpty) {
          print('📋 Suggested alternatives: ${alternatives.join(', ')}');
        }
      }
      
      // Calculate overall confidence based on extraction quality and name matching
      double overallConfidence = _calculateOverallConfidence(
        formattedDate, 
        finalVaccineName, 
        lot, 
        line, 
        nameConfidence
      );
      
      return VaccinationEntry(
        vaccineName: finalVaccineName,
        standardizedName: standardizedName,
        lot: lot,
        date: formattedDate,
        ps: 'Extrait du carnet avec correction automatique',
        confidence: overallConfidence,
        nameConfidence: nameConfidence,
        lineNumber: lineNumber,
        rawLine: line,
        alternativeNames: alternatives,
      );
      
    } catch (e) {
      print('❌ Error parsing vaccination line $lineNumber: $e');
      return null;
    }
  }

  // === RAW VACCINE NAME EXTRACTION ===
  String _extractRawVaccineName(String text) {
    if (text.isEmpty) return '';
    
    // Remove common non-vaccine words
    final excludeWords = {
      'date', 'nom', 'lot', 'dose', 'signature', 'cachet', 'médecin', 
      'dr', 'docteur', 'prof', 'centre', 'hôpital', 'pharmacie'
    };
    
    // Split into words and filter
    final words = text.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\-]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 2 && !excludeWords.contains(word))
        .toList();
    
    if (words.isEmpty) return text.trim();
    
    // Take the longest sequence of words that could be a vaccine name
    if (words.length == 1) {
      return words.first;
    } else if (words.length <= 3) {
      return words.join(' ');
    } else {
      // For longer sequences, try to identify the vaccine name portion
      return words.take(3).join(' ');
    }
  }

  // === LOT NUMBER EXTRACTION ===
  String _extractLotNumber(String text) {
    if (text.isEmpty) return '';
    
    // Common lot number patterns for French vaccines
    final lotPatterns = [
      RegExp(r'\b([A-Z]{2,4}[0-9]{3,8})\b'),           // EW0553, FF1234
      RegExp(r'\b([0-9]{4,8}[A-Z]{1,3})\b'),           // 12345A, 123456AB
      RegExp(r'\b([A-Z0-9]{5,12})\b'),                 // U0602A, H0390-2
      RegExp(r'\b([A-Z]{1,3}[0-9]{2,6}[A-Z]{0,2})\b'), // A12345, B123456C
      RegExp(r'\b([0-9]{2,4}[A-Z]{2,4}[0-9]{0,4})\b'), // 05ABC123
      RegExp(r'\b(D[0-9]{4,6})\b'),                    // D05692 (common prefix)
      RegExp(r'\b([A-Z]{2}[0-9]{2}-[0-9]{1,3})\b'),    // AB12-345
    ];
    
    for (final pattern in lotPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final candidate = match.group(1)!;
        
        // Validate it's not a date or other common text
        if (!_isDateLike(candidate) && !_isCommonWord(candidate)) {
          print('🎯 Lot number found: $candidate');
          return candidate;
        }
      }
    }
    
    return '';
  }

  // === CONFIDENCE CALCULATION ===
  double _calculateOverallConfidence(String date, String vaccineName, String lot, String originalLine, double nameConfidence) {
    double confidence = 0.3; // Base confidence
    
    // Date validation
    if (date.isNotEmpty && _isValidDate(date)) {
      confidence += 0.3;
    }
    
    // Vaccine name quality (heavily weighted)
    confidence += nameConfidence * 0.3;
    
    // Lot number presence
    if (lot.isNotEmpty) {
      confidence += 0.1;
      if (lot.length >= 4) {
        confidence += 0.05;
      }
    }
    
    // Line quality
    if (originalLine.length > 10) {
      confidence += 0.05;
    }
    
    return confidence.clamp(0.0, 1.0);
  }

  // === VALIDATION METHODS ===
  bool _isHeaderLine(String line) {
    final headerKeywords = [
      'nom', 'prénom', 'prénoms', 'né', 'née', 'naissance',
      'vaccin', 'vaccination', 'dose', 'lot', 'signature', 'cachet',
      'médecin', 'professionnel', 'santé',
      'antipoliomyélitique', 'antidiphtérique', 'antitétanique',
      'anticoquelucheuse', 'antihaemophilus', 'antihépatite',
      'autres', 'vaccinations', 'date',
    ];
    
    final lowerLine = line.toLowerCase();
    final hasKeywords = headerKeywords.where((keyword) => lowerLine.contains(keyword)).length >= 2;
    final hasDate = _findDateInLine(line) != null;
    
    return hasKeywords && !hasDate;
  }

  bool _isValidDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length != 3) return false;
      
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      return day >= 1 && day <= 31 && 
             month >= 1 && month <= 12 && 
             year >= 1900 && year <= DateTime.now().year + 1;
    } catch (e) {
      return false;
    }
  }

  bool _isDateLike(String text) {
    return RegExp(r'^\d{1,2}[\/\.\-]\d{1,2}[\/\.\-]\d{2,4}$').hasMatch(text);
  }

  bool _isCommonWord(String text) {
    final commonWords = [
      'date', 'nom', 'lot', 'dose', 'vaccin', 'signature', 'cachet',
      'médecin', 'dr', 'docteur', 'prof', 'centre', 'hôpital'
    ];
    
    return commonWords.contains(text.toLowerCase());
  }

  // === FINAL VALIDATION AND CLEANUP ===
  List<VaccinationEntry> _validateAndCleanVaccinations(List<VaccinationEntry> vaccinations) {
    final validVaccinations = <VaccinationEntry>[];
    
    for (final vaccination in vaccinations) {
      // More lenient validation with fuzzy matching
      if (vaccination.vaccineName.isNotEmpty && 
          vaccination.date.isNotEmpty &&
          _isValidDate(vaccination.date) &&
          vaccination.confidence >= 0.4) { // Lower threshold due to fuzzy matching
        validVaccinations.add(vaccination);
      } else {
        print('❌ Rejected vaccination: ${vaccination.vaccineName} (confidence: ${vaccination.confidence})');
      }
    }
    
    // Sort by line number to maintain original order
    validVaccinations.sort((a, b) => a.lineNumber.compareTo(b.lineNumber));
    
    // Log summary
    final highConfidence = validVaccinations.where((v) => v.isReliable).length;
    final needsReview = validVaccinations.where((v) => v.needsReview && !v.isReliable).length;
    final lowConfidence = validVaccinations.length - highConfidence - needsReview;
    
    print('📊 Validation summary:');
    print('   ✅ High confidence: $highConfidence');
    print('   ⚠️  Needs review: $needsReview');
    print('   ❓ Low confidence: $lowConfidence');
    
    return validVaccinations;
  }

  // === CONVERSION TO VACCINATION OBJECTS ===
  List<Vaccination> convertToVaccinations(List<VaccinationEntry> entries, String userId) {
    return entries.map((entry) => Vaccination(
      vaccineName: entry.standardizedName.isNotEmpty ? entry.standardizedName : entry.vaccineName,
      lot: entry.lot.isNotEmpty ? entry.lot : null,
      date: entry.date,
      ps: entry.ps + (entry.needsReview ? ' (À vérifier)' : ''),
      userId: userId,
    )).toList();
  }

  // === COMPATIBILITY METHOD ===
  Future<ScannedVaccinationData> processVaccinationImage(String imagePath) async {
    final entries = await processVaccinationCard(imagePath);
    
    if (entries.isNotEmpty) {
      final first = entries.first;
      return ScannedVaccinationData(
        vaccineName: first.standardizedName.isNotEmpty ? first.standardizedName : first.vaccineName,
        lot: first.lot,
        date: first.date,
        ps: first.ps,
        confidence: first.confidence,
      );
    }
    
    return ScannedVaccinationData(
      vaccineName: 'Aucune vaccination détectée',
      lot: '',
      date: _getCurrentDate(),
      ps: 'Veuillez vérifier l\'image et réessayer',
      confidence: 0.0,
    );
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  // === UTILITY METHODS FOR UI ===
  
  /// Gets statistics about the parsing results
  Map<String, dynamic> getParsingStats(List<VaccinationEntry> entries) {
    if (entries.isEmpty) {
      return {
        'total': 0,
        'highConfidence': 0,
        'needsReview': 0,
        'lowConfidence': 0,
        'averageConfidence': 0.0,
        'averageNameConfidence': 0.0,
        'standardizedCount': 0,
      };
    }
    
    final highConfidence = entries.where((v) => v.isReliable).length;
    final needsReview = entries.where((v) => v.needsReview && !v.isReliable).length;
    final lowConfidence = entries.length - highConfidence - needsReview;
    final standardizedCount = entries.where((v) => v.standardizedName != 'Vaccination non standardisée').length;
    
    final avgConfidence = entries.map((v) => v.confidence).reduce((a, b) => a + b) / entries.length;
    final avgNameConfidence = entries.map((v) => v.nameConfidence).reduce((a, b) => a + b) / entries.length;
    
    return {
      'total': entries.length,
      'highConfidence': highConfidence,
      'needsReview': needsReview,
      'lowConfidence': lowConfidence,
      'averageConfidence': avgConfidence,
      'averageNameConfidence': avgNameConfidence,
      'standardizedCount': standardizedCount,
    };
  }
}