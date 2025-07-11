// lib/services/french_vaccination_parser.dart - Optimized for French vaccination cards
import 'dart:convert';
import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';
import '../models/scanned_vaccination_data.dart';
import '../models/vaccination.dart';

class VaccinationEntry {
  final String vaccineName;
  final String lot;
  final String date;
  final String ps;
  final double confidence;
  final int lineNumber;
  final String rawLine; // Keep original line for debugging

  VaccinationEntry({
    required this.vaccineName,
    required this.lot,
    required this.date,
    required this.ps,
    required this.confidence,
    required this.lineNumber,
    required this.rawLine,
  });

  @override
  String toString() {
    return 'VaccinationEntry(line: $lineNumber, date: $date, vaccine: $vaccineName, lot: $lot, confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
  }
}

class FrenchVaccinationParser {
  
  // === MAIN PROCESSING METHOD ===
  Future<List<VaccinationEntry>> processVaccinationCard(String imagePath) async {
    try {
      print('🔍 Processing French vaccination card: $imagePath');
      
      final extractedText = await _extractTextFromImage(imagePath);
      print('📝 Extracted text (${extractedText.length} characters)');
      
      if (extractedText.isEmpty) {
        print('❌ No text detected');
        return [];
      }
      
      // Print extracted text for debugging
      print('📄 Raw extracted text:');
      print(extractedText);
      print('=' * 50);
      
      // Parse the vaccination entries
      final vaccinations = _parseVaccinationEntries(extractedText);
      
      print('✅ ${vaccinations.length} vaccination(s) found');
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

  // === VACCINATION ENTRIES PARSING ===
  List<VaccinationEntry> _parseVaccinationEntries(String text) {
    final lines = text.split('\n');
    final vaccinations = <VaccinationEntry>[];
    
    print('📋 Analyzing ${lines.length} lines for vaccination entries...');
    
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
        final vaccination = _parseVaccinationLine(line, dateMatch, i + 1);
        
        if (vaccination != null) {
          vaccinations.add(vaccination);
          print('✅ Line ${i + 1}: VACCINATION PARSED - ${vaccination.vaccineName}');
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

  // === VACCINATION LINE PARSING ===
  VaccinationEntry? _parseVaccinationLine(String line, RegExpMatch dateMatch, int lineNumber) {
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
      
      print('🔍 Parsing line: "$line"');
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
      
      // Extract vaccine name from remaining text
      String vaccineName = _extractVaccineName(remainingLine);
      
      print('💉 Vaccine: "$vaccineName"');
      
      // Calculate confidence based on data quality
      double confidence = _calculateConfidence(vaccineName, lot, formattedDate, line);
      
      return VaccinationEntry(
        vaccineName: vaccineName.isNotEmpty ? vaccineName : 'Vaccination détectée',
        lot: lot,
        date: formattedDate,
        ps: 'Extrait du carnet de vaccination',
        confidence: confidence,
        lineNumber: lineNumber,
        rawLine: line,
      );
      
    } catch (e) {
      print('❌ Error parsing vaccination line $lineNumber: $e');
      return null;
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

  // === VACCINE NAME EXTRACTION ===
  String _extractVaccineName(String text) {
    if (text.isEmpty) return '';
    
    // French vaccine name mappings
    final frenchVaccines = {
      // Brand names
      'pentalog': 'Pentalog',
      'infanrix': 'Infanrix',
      'prevenar': 'Prevenar',
      'pneumo': 'Pneumo',
      'meningitec': 'Méningitec',
      'priorix': 'Priorix',
      'havrix': 'Havrix',
      'engerix': 'Engerix',
      'repevax': 'Repevax',
      'revaxis': 'Revaxis',
      'tetravac': 'Tetravac',
      'hexyon': 'Hexyon',
      'vaxelis': 'Vaxelis',
      'gardasil': 'Gardasil',
      'cervarix': 'Cervarix',
      'influvac': 'Influvac',
      'fluarix': 'Fluarix',
      'vaxigrip': 'Vaxigrip',
      
      // Generic names
      'ror': 'ROR (Rougeole-Oreillons-Rubéole)',
      'dtp': 'DTP (Diphtérie-Tétanos-Poliomyélite)',
      'dtpolio': 'DT-Polio',
      'coqueluche': 'Coqueluche',
      'tetanos': 'Tétanos',
      'polio': 'Poliomyélite',
      'hepatite': 'Hépatite',
      'grippe': 'Grippe',
      'pneumocoque': 'Pneumocoque',
      'meningocoque': 'Méningocoque',
      'haemophilus': 'Haemophilus',
      'hib': 'Haemophilus influenzae b',
      
      // COVID vaccines
      'pfizer': 'COVID-19 Pfizer',
      'moderna': 'COVID-19 Moderna',
      'astrazeneca': 'COVID-19 AstraZeneca',
      'janssen': 'COVID-19 Janssen',
      'comirnaty': 'COVID-19 Comirnaty (Pfizer)',
      'spikevax': 'COVID-19 Spikevax (Moderna)',
    };
    
    final lowerText = text.toLowerCase();
    
    // Check for exact matches first
    for (final entry in frenchVaccines.entries) {
      if (lowerText.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Check for pattern matches
    if (RegExp(r'(r\.?o\.?r|mmr)', caseSensitive: false).hasMatch(text)) {
      return 'ROR (Rougeole-Oreillons-Rubéole)';
    }
    
    if (RegExp(r'(d\.?t\.?p|dtp)', caseSensitive: false).hasMatch(text)) {
      return 'DTP (Diphtérie-Tétanos-Poliomyélite)';
    }
    
    if (RegExp(r'(pen|pent)', caseSensitive: false).hasMatch(text)) {
      return 'Vaccin pentavalent';
    }
    
    // If no specific match, clean and return the text
    String cleanedText = text
        .replaceAll(RegExp(r'[^\w\s\-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    
    if (cleanedText.isEmpty) return '';
    
    // Capitalize first letter of each word
    final words = cleanedText.split(' ')
        .where((word) => word.length > 1)
        .take(3)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .toList();
    
    return words.isNotEmpty ? words.join(' ') : '';
  }

  // === CONFIDENCE CALCULATION ===
  double _calculateConfidence(String vaccineName, String lot, String date, String originalLine) {
    double confidence = 0.4; // Base confidence
    
    // Date validation
    if (date.isNotEmpty && _isValidDate(date)) {
      confidence += 0.3;
    }
    
    // Vaccine name quality
    if (vaccineName.isNotEmpty) {
      confidence += 0.2;
      if (vaccineName.length > 3) {
        confidence += 0.1;
      }
    }
    
    // Lot number presence
    if (lot.isNotEmpty) {
      confidence += 0.1;
      if (lot.length >= 4) {
        confidence += 0.1;
      }
    }
    
    // Line quality
    if (originalLine.length > 10) {
      confidence += 0.1;
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
      // Basic validation
      if (vaccination.vaccineName.isNotEmpty && 
          vaccination.date.isNotEmpty &&
          _isValidDate(vaccination.date) &&
          vaccination.confidence >= 0.3) {
        validVaccinations.add(vaccination);
      } else {
        print('❌ Rejected vaccination: ${vaccination.vaccineName} (confidence: ${vaccination.confidence})');
      }
    }
    
    // Sort by line number to maintain original order
    validVaccinations.sort((a, b) => a.lineNumber.compareTo(b.lineNumber));
    
    return validVaccinations;
  }

  // === CONVERSION TO VACCINATION OBJECTS ===
  List<Vaccination> convertToVaccinations(List<VaccinationEntry> entries, String userId) {
    return entries.map((entry) => Vaccination(
      vaccineName: entry.vaccineName,
      lot: entry.lot.isNotEmpty ? entry.lot : null,
      date: entry.date,
      ps: entry.ps,
      userId: userId,
    )).toList();
  }

  // === COMPATIBILITY METHOD ===
  Future<ScannedVaccinationData> processVaccinationImage(String imagePath) async {
    final entries = await processVaccinationCard(imagePath);
    
    if (entries.isNotEmpty) {
      final first = entries.first;
      return ScannedVaccinationData(
        vaccineName: first.vaccineName,
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
}