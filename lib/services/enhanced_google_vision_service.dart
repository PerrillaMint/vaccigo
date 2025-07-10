// lib/services/enhanced_google_vision_service.dart - Service optimisé pour carnets français multiples
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
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

  VaccinationEntry({
    required this.vaccineName,
    required this.lot,
    required this.date,
    required this.ps,
    required this.confidence,
    required this.lineNumber,
  });
}

class EnhancedGoogleVisionService {
  static const String _apiKey = 'AIzaSyCaes3fAkFgeRjyUMejW710_PXhDPA8ADM';

  // === MÉTHODE PRINCIPALE POUR CARNETS MULTIPLES ===
  Future<List<VaccinationEntry>> processVaccinationCard(String imagePath) async {
    try {
      print('🔍 Analyse du carnet de vaccination: $imagePath');
      
      final extractedText = await _extractTextFromImage(imagePath);
      print('📝 Texte extrait (${extractedText.length} caractères)');
      
      if (extractedText.isEmpty) {
        print('❌ Aucun texte détecté');
        return [];
      }
      
      // Détecte le format du carnet
      final cardFormat = _detectCardFormat(extractedText);
      print('📋 Format détecté: $cardFormat');
      
      // Extraction selon le format
      List<VaccinationEntry> vaccinations;
      switch (cardFormat) {
        case CardFormat.frenchTable:
          vaccinations = _extractFromFrenchTable(extractedText);
          break;
        case CardFormat.frenchList:
          vaccinations = _extractFromFrenchList(extractedText);
          break;
        default:
          vaccinations = _extractGeneric(extractedText);
      }
      
      // Validation et nettoyage
      vaccinations = _validateVaccinations(vaccinations);
      
      print('✅ ${vaccinations.length} vaccination(s) valide(s) extraite(s)');
      return vaccinations;
      
    } catch (e) {
      print('❌ Erreur traitement carnet: $e');
      return [];
    }
  }

  // === EXTRACTION DE TEXTE ===
  Future<String> _extractTextFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();
      
      return recognizedText.text;
    } catch (e) {
      print('❌ Erreur extraction texte: $e');
      return '';
    }
  }

  // === DÉTECTION DU FORMAT ===
  CardFormat _detectCardFormat(String text) {
    final lowerText = text.toLowerCase();
    
    // Indicateurs de format tableau français (comme votre image)
    final tableIndicators = [
      'vaccin', 'dose', 'lot', 'signature', 'cachet',
      'antipoliomyélitique', 'antidiphtérique', 'antitétanique'
    ];
    
    int tableScore = 0;
    for (final indicator in tableIndicators) {
      if (lowerText.contains(indicator)) tableScore++;
    }
    
    // Compte les dates (plusieurs dates = format tableau)
    final dateMatches = RegExp(r'\d{1,2}[\.\/\-]\d{1,2}[\.\/\-]\d{1,4}').allMatches(text);
    if (dateMatches.length >= 2) tableScore += 2;
    
    if (tableScore >= 4) {
      return CardFormat.frenchTable;
    } else if (lowerText.contains('carnet') && lowerText.contains('vaccination')) {
      return CardFormat.frenchList;
    }
    
    return CardFormat.generic;
  }

  // === EXTRACTION TABLEAU FRANÇAIS ===
  List<VaccinationEntry> _extractFromFrenchTable(String text) {
    print('📊 Extraction format tableau français...');
    
    final lines = text.split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    
    final vaccinations = <VaccinationEntry>[];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      // Ignore les en-têtes
      if (_isHeaderLine(line)) continue;
      
      // Cherche les lignes avec dates
      final datePattern = RegExp(r'\b(\d{1,2})[\.\/\-](\d{1,2})[\.\/\-](\d{1,4})\b');
      final dateMatch = datePattern.firstMatch(line);
      
      if (dateMatch != null) {
        final vaccination = _parseTableLine(line, dateMatch, i);
        if (vaccination != null) {
          vaccinations.add(vaccination);
        }
      }
    }
    
    return vaccinations;
  }

  // === ANALYSE D'UNE LIGNE DE TABLEAU ===
  VaccinationEntry? _parseTableLine(String line, RegExpMatch dateMatch, int lineNumber) {
    try {
      // === EXTRACTION DATE ===
      final day = dateMatch.group(1)!.padLeft(2, '0');
      final month = dateMatch.group(2)!.padLeft(2, '0');
      final yearStr = dateMatch.group(3)!;
      
      String year = yearStr;
      if (yearStr.length == 2) {
        final yr = int.parse(yearStr);
        year = yr <= 30 ? '20$yearStr' : '19$yearStr';
      }
      
      final date = '$day/$month/$year';
      
      // === NETTOYAGE DE LA LIGNE ===
      String cleanLine = line.replaceAll(dateMatch.group(0)!, '').trim();
      
      // === EXTRACTION LOT (OPTIONNEL) ===
      String lot = '';
      final lotPatterns = [
        RegExp(r'\b([A-Z]{2,4}[0-9]{3,8})\b'),           // EW0553
        RegExp(r'\b([0-9]{4,8}[A-Z]{1,3})\b'),           // 12345A
        RegExp(r'\b([A-Z0-9\-]{5,15})\b'),               // U0602-A
        RegExp(r'\b([A-Z]{1,3}[0-9]{2,6}[A-Z]{0,2})\b'), // A12345B
      ];
      
      for (final pattern in lotPatterns) {
        final match = pattern.firstMatch(cleanLine);
        if (match != null && !_isDate(match.group(1)!)) {
          lot = match.group(1)!;
          cleanLine = cleanLine.replaceAll(lot, '').trim();
          break;
        }
      }
      
      // === EXTRACTION NOM VACCIN ===
      final vaccineName = _extractVaccineName(cleanLine);
      
      // === CALCUL CONFIANCE ===
      double confidence = 0.6; // Base pour détection de date
      if (vaccineName.isNotEmpty && vaccineName != 'Vaccination') confidence += 0.2;
      if (lot.isNotEmpty) confidence += 0.1;
      if (cleanLine.length > 5) confidence += 0.1;
      
      print('📋 Ligne $lineNumber: $vaccineName | $date | Lot: $lot');
      
      return VaccinationEntry(
        vaccineName: vaccineName.isNotEmpty ? vaccineName : 'Vaccination détectée',
        lot: lot, // Peut être vide
        date: date,
        ps: 'Extrait du carnet',
        confidence: confidence.clamp(0.3, 1.0),
        lineNumber: lineNumber,
      );
      
    } catch (e) {
      print('❌ Erreur parsing ligne $lineNumber: $e');
      return null;
    }
  }

  // === EXTRACTION NOM VACCIN ===
  String _extractVaccineName(String text) {
    if (text.isEmpty) return '';
    
    // Dictionnaire vaccins français
    final frenchVaccines = {
      'pentalog': 'Pentalog',
      'infanrix': 'Infanrix',
      'prevenar': 'Prevenar',
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
    };
    
    final lowerText = text.toLowerCase();
    
    // Cherche dans le dictionnaire
    for (final entry in frenchVaccines.entries) {
      if (lowerText.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Patterns COVID-19
    if (RegExp(r'(pfizer|comirnaty)', caseSensitive: false).hasMatch(text)) {
      return 'COVID-19 Pfizer';
    }
    if (RegExp(r'(moderna)', caseSensitive: false).hasMatch(text)) {
      return 'COVID-19 Moderna';
    }
    if (RegExp(r'(astra)', caseSensitive: false).hasMatch(text)) {
      return 'COVID-19 AstraZeneca';
    }
    
    // Patterns génériques
    final patterns = [
      (RegExp(r'dtp|dt\s*polio', caseSensitive: false), 'DTP'),
      (RegExp(r'ror|mmr', caseSensitive: false), 'ROR'),
      (RegExp(r'hépatite|hepatitis', caseSensitive: false), 'Hépatite'),
      (RegExp(r'grippe|flu', caseSensitive: false), 'Grippe'),
      (RegExp(r'pneumo', caseSensitive: false), 'Pneumocoque'),
      (RegExp(r'meningo', caseSensitive: false), 'Méningocoque'),
    ];
    
    for (final (pattern, name) in patterns) {
      if (pattern.hasMatch(text)) {
        return name;
      }
    }
    
    // Nettoyage et capitalisation
    final words = text
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2)
        .take(3)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1).toLowerCase() : w)
        .toList();
    
    return words.isNotEmpty ? words.join(' ') : '';
  }

  // === EXTRACTION LISTE FRANÇAISE ===
  List<VaccinationEntry> _extractFromFrenchList(String text) {
    print('📝 Extraction format liste français...');
    return _extractGeneric(text);
  }

  // === EXTRACTION GÉNÉRIQUE ===
  List<VaccinationEntry> _extractGeneric(String text) {
    print('🔄 Extraction générique...');
    
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final vaccinations = <VaccinationEntry>[];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.length < 5) continue;
      
      final hasDate = RegExp(r'\d{1,2}[\.\/\-]\d{1,2}[\.\/\-]\d{1,4}').hasMatch(line);
      final hasVaccineWord = RegExp(r'(vaccin|vaccine|injection)', caseSensitive: false).hasMatch(line);
      
      if (hasDate || hasVaccineWord) {
        final dateMatch = RegExp(r'\b(\d{1,2})[\.\/\-](\d{1,2})[\.\/\-](\d{1,4})\b').firstMatch(line);
        if (dateMatch != null) {
          final vaccination = _parseTableLine(line, dateMatch, i);
          if (vaccination != null) {
            vaccinations.add(vaccination);
          }
        }
      }
    }
    
    return vaccinations;
  }

  // === VALIDATION ===
  List<VaccinationEntry> _validateVaccinations(List<VaccinationEntry> vaccinations) {
    final valid = <VaccinationEntry>[];
    
    for (final vaccination in vaccinations) {
      // Critères de validation assouplis
      if (vaccination.vaccineName.isNotEmpty && 
          vaccination.date.isNotEmpty &&
          vaccination.vaccineName.length > 2) {
        valid.add(vaccination);
      }
    }
    
    // Trie par numéro de ligne
    valid.sort((a, b) => a.lineNumber.compareTo(b.lineNumber));
    
    return valid;
  }

  // === MÉTHODES UTILITAIRES ===
  
  bool _isHeaderLine(String line) {
    final headers = [
      'nom', 'prénom', 'né(e)', 'naissance',
      'vaccin', 'dose', 'lot', 'signature', 'cachet',
      'antipoliomyélitique', 'antidiphtérique', 'antitétanique',
    ];
    
    final lowerLine = line.toLowerCase();
    final hasHeader = headers.any((h) => lowerLine.contains(h));
    final hasDate = RegExp(r'\d{1,2}[\.\/\-]\d{1,2}[\.\/\-]\d{1,4}').hasMatch(line);
    
    return hasHeader && !hasDate;
  }

  bool _isDate(String text) {
    return RegExp(r'^\d{1,2}[\.\/\-]\d{1,2}[\.\/\-]\d{1,4}$').hasMatch(text);
  }

  // === CONVERSION VERS OBJETS VACCINATION ===
  List<Vaccination> convertToVaccinations(List<VaccinationEntry> entries, String userId) {
    return entries.map((entry) => Vaccination(
      vaccineName: entry.vaccineName,
      lot: entry.lot.isNotEmpty ? entry.lot : null, // Lot optionnel
      date: entry.date,
      ps: entry.ps,
      userId: userId,
    )).toList();
  }

  // === COMPATIBILITÉ AVEC L'ANCIEN CODE ===
  Future<ScannedVaccinationData> processVaccinationImage(String imagePath) async {
    final entries = await processVaccinationCard(imagePath);
    
    if (entries.isNotEmpty) {
      final first = entries.first;
      return ScannedVaccinationData(
        vaccineName: first.vaccineName,
        lot: first.lot, // Peut être vide
        date: first.date,
        ps: first.ps,
        confidence: first.confidence,
      );
    }
    
    // Fallback plus permissif
    return ScannedVaccinationData(
      vaccineName: 'Vaccination détectée',
      lot: '', // Lot optionnel
      date: _getCurrentDate(),
      ps: 'Veuillez vérifier les informations',
      confidence: 0.4,
    );
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }
}

enum CardFormat {
  frenchTable,
  frenchList,
  international,
  generic,
}