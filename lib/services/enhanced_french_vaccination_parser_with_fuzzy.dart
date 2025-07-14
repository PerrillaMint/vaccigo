// lib/services/enhanced_french_vaccination_parser_with_fuzzy.dart - FIXED VERSION
// Updated to better handle French vaccination cards with improved name recognition
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

  bool get isReliable => confidence >= 0.8 && nameConfidence >= 0.7;
  bool get needsReview => confidence >= 0.6 || nameConfidence >= 0.6;

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
      final lines = extractedText.split('\n');
      for (int i = 0; i < lines.length; i++) {
        print('Line ${i + 1}: "${lines[i]}"');
      }
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
      
      if (line.isEmpty || line.length < 5) {
        print('⏭️  Line ${i + 1}: TOO SHORT - "$line"');
        continue;
      }
      
      // Skip obvious header lines
      if (_isHeaderLine(line)) {
        print('🏷️  Line ${i + 1}: HEADER - "$line"');
        continue;
      }
      
      // Look for lines with dates (key indicator of vaccination entries)
      final dateMatch = _findDateInLine(line);
      
      if (dateMatch != null) {
        print('📅 Line ${i + 1}: DATE FOUND - "$line"');
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
          print('❌ Line ${i + 1}: FAILED TO PARSE - "$line"');
        }
      } else {
        print('⏭️  Line ${i + 1}: NO DATE - "$line"');
      }
    }
    
    return _validateAndCleanVaccinations(vaccinations);
  }

  // === IMPROVED DATE DETECTION FOR FRENCH CARDS ===
  RegExpMatch? _findDateInLine(String line) {
    // Enhanced French date patterns - more flexible with separators and format
    final datePatterns = [
      // DD.MM.YY format (common in French cards like "23.10.01")
      RegExp(r'\b(\d{1,2})\.(\d{1,2})\.(\d{2,4})\b'),
      // DD/MM/YY format
      RegExp(r'\b(\d{1,2})/(\d{1,2})/(\d{2,4})\b'),
      // DD-MM-YY format
      RegExp(r'\b(\d{1,2})-(\d{1,2})-(\d{2,4})\b'),
      // DD MM YY format (with spaces)
      RegExp(r'\b(\d{1,2})\s+(\d{1,2})\s+(\d{2,4})\b'),
      // More flexible patterns
      RegExp(r'(\d{1,2})[\.\/\-\s](\d{1,2})[\.\/\-\s](\d{2,4})'),
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
          print('🎯 Date pattern matched: ${match.group(0)} (day: $day, month: $month, year: $year)');
          return match;
        }
      }
    }
    
    return null;
  }

  // === IMPROVED VACCINATION LINE PARSING WITH FUZZY MATCHING ===
  VaccinationEntry? _parseVaccinationLineWithFuzzy(String line, RegExpMatch dateMatch, int lineNumber) {
    try {
      // Extract and normalize date
      final day = dateMatch.group(1)!.padLeft(2, '0');
      final month = dateMatch.group(2)!.padLeft(2, '0');
      final yearStr = dateMatch.group(3)!;
      
      String year = yearStr;
      if (yearStr.length == 2) {
        final yr = int.parse(yearStr);
        // Assume years 00-30 are 2000s, 31-99 are 1900s
        year = yr <= 30 ? '20$yearStr' : '19$yearStr';
      }
      
      final formattedDate = '$day/$month/$year';
      
      // Remove date from line to extract other information
      String remainingLine = line.replaceAll(dateMatch.group(0)!, '').trim();
      
      // Clean up the remaining line
      remainingLine = remainingLine.replaceAll(RegExp(r'\s+'), ' ').trim();
      
      print('🔍 Parsing line with fuzzy matching: "$line"');
      print('📅 Date: $formattedDate');
      print('📝 Remaining after date removal: "$remainingLine"');
      
      // For French vaccination cards, the format is typically:
      // Date VaccineName LotNumber [Signature/Cachet]
      // So we need to split the remaining line appropriately
      
      final parts = remainingLine.split(RegExp(r'\s+'));
      print('📄 Split parts: ${parts.join(' | ')}');
      
      String vaccineName = '';
      String lot = '';
      
      // Strategy: Try to identify lot number pattern first, then everything before it is vaccine name
      int lotIndex = -1;
      for (int i = 0; i < parts.length; i++) {
        if (_looksLikeLotNumber(parts[i])) {
          lotIndex = i;
          lot = parts[i];
          break;
        }
      }
      
      if (lotIndex > 0) {
        // Everything before the lot number is the vaccine name
        vaccineName = parts.sublist(0, lotIndex).join(' ');
        print('💊 Lot found at index $lotIndex: "$lot"');
        print('💉 Vaccine name (before lot): "$vaccineName"');
      } else {
        // No clear lot pattern found, try different strategy
        // Look for common lot patterns in the entire remaining line
        lot = _extractLotNumber(remainingLine);
        if (lot.isNotEmpty) {
          // Remove lot from remaining line to get vaccine name
          vaccineName = remainingLine.replaceAll(lot, '').trim();
          vaccineName = vaccineName.replaceAll(RegExp(r'\s+'), ' ').trim();
        } else {
          // No lot found, treat most of the line as vaccine name
          // Skip obvious non-vaccine words at the end
          final filteredParts = parts.where((part) => 
            !_isSignatureWord(part) && 
            !_isCommonNonVaccineWord(part) &&
            part.length > 1
          ).toList();
          
          if (filteredParts.length >= 2) {
            vaccineName = filteredParts.take(2).join(' ');
          } else if (filteredParts.isNotEmpty) {
            vaccineName = filteredParts.first;
          } else {
            vaccineName = parts.isNotEmpty ? parts.first : 'Vaccination détectée';
          }
        }
      }
      
      print('💊 Final lot: "$lot"');
      print('💉 Final vaccine name: "$vaccineName"');
      
      // === FUZZY MATCHING FOR VACCINE NAME ===
      if (vaccineName.isEmpty) {
        vaccineName = 'Vaccination détectée';
      }
      
      // Apply fuzzy string matching correction
      final fuzzyMatch = VaccineNameCorrector.correctVaccineName(vaccineName);
      print('🎯 Fuzzy match result: $fuzzyMatch');
      
      // Use corrected name if confidence is sufficient
      String finalVaccineName;
      String standardizedName;
      double nameConfidence;
      List<String> alternatives = [];
      
      if (fuzzyMatch.confidence >= 0.5) { // Lower threshold for better detection
        finalVaccineName = fuzzyMatch.correctedName;
        standardizedName = fuzzyMatch.standardizedName;
        nameConfidence = fuzzyMatch.confidence;
        alternatives = fuzzyMatch.alternatives;
        print('✅ Using fuzzy corrected name: "$finalVaccineName" → "$standardizedName"');
      } else {
        // Keep original but clean it up
        finalVaccineName = _cleanVaccineName(vaccineName);
        standardizedName = 'Vaccination non standardisée';
        nameConfidence = fuzzyMatch.confidence;
        
        // Try to find multiple matches for manual review
        final multipleMatches = VaccineNameCorrector.findMultipleMatches(vaccineName, maxResults: 3);
        alternatives = multipleMatches.map((m) => m.standardizedName).toList();
        
        print('⚠️  Low confidence match, keeping cleaned original: "$finalVaccineName"');
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

  // === IMPROVED LOT NUMBER DETECTION ===
  bool _looksLikeLotNumber(String text) {
    if (text.length < 3) return false;
    
    // Common French vaccination lot patterns
    final lotPatterns = [
      RegExp(r'^[A-Z]{1,4}[0-9]{3,8}$'),           // LV, EW0553, etc.
      RegExp(r'^[0-9]{3,8}[A-Z]{1,3}$'),           // 12345A, 123456AB
      RegExp(r'^[A-Z0-9]{5,12}$'),                 // U0602A, H0390-2
      RegExp(r'^[A-Z]{1,3}[0-9]{2,6}[A-Z]{0,2}$'), // A12345, B123456C
      RegExp(r'^[0-9]{2,4}[A-Z]{2,4}[0-9]{0,4}$'), // 05ABC123
      RegExp(r'^D[0-9]{4,6}$'),                    // D05692 (common prefix)
      RegExp(r'^[A-Z]{2}[0-9]{2}-[0-9]{1,3}$'),    // AB12-345
      RegExp(r'^U[0-9]{4}-?[A-Z]?$'),              // U0602-A, U0602A
    ];
    
    for (final pattern in lotPatterns) {
      if (pattern.hasMatch(text)) {
        return true;
      }
    }
    
    return false;
  }

  // === IMPROVED LOT NUMBER EXTRACTION ===
  String _extractLotNumber(String text) {
    if (text.isEmpty) return '';
    
    // Split text into potential lot candidates
    final words = text.split(RegExp(r'\s+'));
    
    for (final word in words) {
      if (_looksLikeLotNumber(word)) {
        print('🎯 Lot number found: $word');
        return word;
      }
    }
    
    // Fallback: use regex patterns on the full text
    final lotPatterns = [
      RegExp(r'\b([A-Z]{1,4}[0-9]{3,8})\b'),           // LV, EW0553
      RegExp(r'\b([0-9]{3,8}[A-Z]{1,3})\b'),           // 12345A, 123456AB
      RegExp(r'\b([A-Z0-9]{5,12})\b'),                 // U0602A, H0390-2
      RegExp(r'\b(U[0-9]{4}-?[A-Z]?)\b'),              // U0602-A, U0602A
      RegExp(r'\b([A-Z]{1,3}[0-9]{2,6}[A-Z]{0,2})\b'), // A12345, B123456C
      RegExp(r'\b(D[0-9]{4,6})\b'),                    // D05692
    ];
    
    for (final pattern in lotPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final candidate = match.group(1)!;
        
        // Validate it's not a date or other common text
        if (!_isDateLike(candidate) && !_isCommonWord(candidate)) {
          print('🎯 Lot number found via regex: $candidate');
          return candidate;
        }
      }
    }
    
    return '';
  }

  // === HELPER METHODS ===
  bool _isSignatureWord(String word) {
    final signatureWords = {
      'signature', 'cachet', 'dr', 'docteur', 'médecin', 'prof', 'professeur'
    };
    return signatureWords.contains(word.toLowerCase());
  }

  bool _isCommonNonVaccineWord(String word) {
    final nonVaccineWords = {
      'et', 'ou', 'le', 'la', 'les', 'de', 'du', 'des', 'à', 'au', 'aux',
      'par', 'pour', 'avec', 'sans', 'sur', 'sous', 'dans', 'date', 'nom',
      'dose', 'mg', 'ml', 'cc', 'unité', 'unités'
    };
    return nonVaccineWords.contains(word.toLowerCase());
  }

  String _cleanVaccineName(String name) {
    return name
        .replaceAll(RegExp(r'[^\w\s\-]'), ' ')  // Remove special chars except hyphens
        .replaceAll(RegExp(r'\s+'), ' ')        // Normalize whitespace
        .trim()
        .split(' ')
        .where((word) => word.length > 1)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  // === CONFIDENCE CALCULATION ===
  double _calculateOverallConfidence(String date, String vaccineName, String lot, String originalLine, double nameConfidence) {
    double confidence = 0.2; // Base confidence
    
    // Date validation (high weight)
    if (date.isNotEmpty && _isValidDate(date)) {
      confidence += 0.3;
    }
    
    // Vaccine name quality (heavily weighted with fuzzy matching)
    confidence += nameConfidence * 0.4;
    
    // Vaccine name length
    if (vaccineName.length >= 3) {
      confidence += 0.1;
    }
    
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
    final keywordCount = headerKeywords.where((keyword) => lowerLine.contains(keyword)).length;
    final hasDate = _findDateInLine(line) != null;
    
    // More strict header detection - needs multiple keywords and no date
    return keywordCount >= 2 && !hasDate;
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
          vaccination.confidence >= 0.3) { // Lower threshold
        validVaccinations.add(vaccination);
        print('✅ Accepted vaccination: ${vaccination.vaccineName} (confidence: ${vaccination.confidence.toStringAsFixed(2)})');
      } else {
        print('❌ Rejected vaccination: ${vaccination.vaccineName} (confidence: ${vaccination.confidence.toStringAsFixed(2)})');
      }
    }
    
    // Sort by date (most recent first) or line number if dates are equal
    validVaccinations.sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      return dateCompare == 0 ? a.lineNumber.compareTo(b.lineNumber) : dateCompare;
    });
    
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
      vaccineName: entry.standardizedName.isNotEmpty && entry.standardizedName != 'Vaccination non standardisée' 
          ? entry.standardizedName 
          : entry.vaccineName,
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
    final standardizedCount = entries.where((v) => 
        v.standardizedName.isNotEmpty && 
        v.standardizedName != 'Vaccination non standardisée'
    ).length;
    
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