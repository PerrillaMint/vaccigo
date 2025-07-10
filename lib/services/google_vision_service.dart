// lib/services/google_vision_service.dart - Service amélioré pour carnets français
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:google_ml_kit/google_ml_kit.dart';
import '../models/scanned_vaccination_data.dart';

class GoogleVisionService {
  static const String _apiKey = 'AIzaSyCaes3fAkFgeRjyUMejW710_PXhDPA8ADM';
  static const String _baseUrl = 'https://vision.googleapis.com/v1/images:annotate';

  // === MÉTHODE PRINCIPALE AMÉLIORÉE ===
  Future<ScannedVaccinationData> processVaccinationImage(String imagePath) async {
    try {
      print('🔍 Analyse du carnet de vaccination français: $imagePath');
      
      // Extraction du texte avec ML Kit
      final extractedText = await _extractTextFromImage(imagePath);
      print('📝 Texte extrait (${extractedText.length} caractères)');
      
      if (extractedText.isEmpty) {
        return _createFallbackResult('Aucun texte détecté dans l\'image');
      }
      
      // Détection des vaccinations multiples dans le format français
      final vaccinations = _extractFrenchVaccinationTable(extractedText);
      
      if (vaccinations.isEmpty) {
        // Essaie une extraction plus permissive
        return _extractSingleVaccination(extractedText);
      }
      
      // Retourne la première vaccination trouvée (pour compatibilité)
      // L'écran multi-vaccination gérera les autres
      return vaccinations.first;
      
    } catch (e) {
      print('❌ Erreur traitement image: $e');
      return _createFallbackResult('Erreur d\'analyse. Veuillez réessayer.');
    }
  }

  // === EXTRACTION DE TEXTE ROBUSTE ===
  Future<String> _extractTextFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();
      
      print('📱 ML Kit - Texte extrait:');
      print(recognizedText.text.substring(0, recognizedText.text.length > 300 ? 300 : recognizedText.text.length));
      
      return recognizedText.text;
    } catch (e) {
      print('❌ Erreur ML Kit: $e');
      return '';
    }
  }

  // === EXTRACTION SPÉCIALISÉE POUR CARNETS FRANÇAIS ===
  List<ScannedVaccinationData> _extractFrenchVaccinationTable(String text) {
    print('🇫🇷 Analyse du format carnet français...');
    
    final vaccinations = <ScannedVaccinationData>[];
    final lines = text.split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      // Ignore les lignes d'en-tête
      if (_isHeaderLine(line)) continue;
      
      // Cherche les lignes avec des dates (format français)
      final dateMatch = RegExp(r'\b(\d{1,2})[\.\/\-](\d{1,2})[\.\/\-](\d{1,4})\b').firstMatch(line);
      
      if (dateMatch != null) {
        final vaccination = _parseVaccinationLine(line, dateMatch);
        if (vaccination != null) {
          vaccinations.add(vaccination);
        }
      }
    }
    
    print('✅ ${vaccinations.length} vaccination(s) détectée(s)');
    return vaccinations;
  }

  // === ANALYSE D'UNE LIGNE DE VACCINATION ===
  ScannedVaccinationData? _parseVaccinationLine(String line, RegExpMatch dateMatch) {
    try {
      // Extraction de la date
      final day = dateMatch.group(1)!.padLeft(2, '0');
      final month = dateMatch.group(2)!.padLeft(2, '0');
      final yearStr = dateMatch.group(3)!;
      
      // Normalisation de l'année
      String year = yearStr;
      if (yearStr.length == 2) {
        final yr = int.parse(yearStr);
        year = yr <= 30 ? '20$yearStr' : '19$yearStr';
      }
      
      final normalizedDate = '$day/$month/$year';
      
      // Nettoyage de la ligne pour extraire le vaccin
      String cleanLine = line.replaceAll(dateMatch.group(0)!, '').trim();
      
      // Extraction du lot (optionnel)
      String lot = '';
      final lotPatterns = [
        RegExp(r'\b([A-Z]{2,4}[0-9]{3,8})\b'),     // EW0553, FF1234
        RegExp(r'\b([0-9]{4,8}[A-Z]{1,3})\b'),     // 12345A
        RegExp(r'\b([A-Z0-9\-]{5,12})\b'),         // U0602-A
      ];
      
      for (final pattern in lotPatterns) {
        final match = pattern.firstMatch(cleanLine);
        if (match != null) {
          lot = match.group(1)!;
          cleanLine = cleanLine.replaceAll(lot, '').trim();
          break;
        }
      }
      
      // Extraction du nom de vaccin
      String vaccineName = _extractVaccineName(cleanLine);
      
      // Validation minimale
      if (vaccineName.isEmpty) {
        vaccineName = 'Vaccination détectée';
      }
      
      double confidence = 0.7;
      if (lot.isNotEmpty) confidence += 0.1;
      if (vaccineName.length > 3) confidence += 0.1;
      
      print('📊 Vaccination extraite: $vaccineName, $normalizedDate, lot: $lot');
      
      return ScannedVaccinationData(
        vaccineName: vaccineName,
        lot: lot,
        date: normalizedDate,
        ps: 'Extrait automatiquement du carnet',
        confidence: confidence,
      );
      
    } catch (e) {
      print('❌ Erreur parsing ligne: $e');
      return null;
    }
  }

  // === EXTRACTION DU NOM DE VACCIN ===
  String _extractVaccineName(String text) {
    // Dictionnaire des vaccins français courants
    final frenchVaccines = {
      'pentalog': 'Pentalog (DTP-Coqueluche-Hib)',
      'infanrix': 'Infanrix (DTP-Coqueluche-Hib-Hépatite B)',
      'prevenar': 'Prevenar (Pneumocoque)',
      'meningitec': 'Méningitec (Méningocoque C)',
      'priorix': 'Priorix (ROR)',
      'havrix': 'Havrix (Hépatite A)',
      'engerix': 'Engerix (Hépatite B)',
      'repevax': 'Repevax (DTP-Coqueluche)',
      'revaxis': 'Revaxis (DTP)',
      'tetravac': 'Tetravac (DTP-Coqueluche)',
      'hexyon': 'Hexyon (DTP-Coqueluche-Hib-Hépatite B)',
      'vaxelis': 'Vaxelis (DTP-Coqueluche-Hib-Hépatite B)',
    };
    
    String cleanText = text.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    
    // Cherche dans le dictionnaire
    for (final entry in frenchVaccines.entries) {
      if (cleanText.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Patterns pour vaccins COVID
    if (RegExp(r'(pfizer|comirnaty|biontech)', caseSensitive: false).hasMatch(cleanText)) {
      return 'Vaccin COVID-19 Pfizer-BioNTech';
    }
    if (RegExp(r'(moderna|spikevax)', caseSensitive: false).hasMatch(cleanText)) {
      return 'Vaccin COVID-19 Moderna';
    }
    if (RegExp(r'(astrazeneca|vaxzevria)', caseSensitive: false).hasMatch(cleanText)) {
      return 'Vaccin COVID-19 AstraZeneca';
    }
    
    // Patterns génériques
    final genericPatterns = [
      RegExp(r'(dtp|dt|dtpolio)', caseSensitive: false),
      RegExp(r'(ror|mmr)', caseSensitive: false),
      RegExp(r'(hépatite|hepatitis)', caseSensitive: false),
      RegExp(r'(grippe|flu|influenza)', caseSensitive: false),
      RegExp(r'(pneumo|pneumocoque)', caseSensitive: false),
      RegExp(r'(meningo|méningocoque)', caseSensitive: false),
    ];
    
    for (final pattern in genericPatterns) {
      if (pattern.hasMatch(cleanText)) {
        return _capitalizeFirst(pattern.firstMatch(cleanText)!.group(0)!);
      }
    }
    
    // Fallback: prend les premiers mots significatifs
    final words = cleanText.split(' ')
        .where((word) => word.length > 2)
        .take(3)
        .toList();
    
    if (words.isNotEmpty) {
      return _capitalizeFirst(words.join(' '));
    }
    
    return 'Vaccination';
  }

  // === EXTRACTION SIMPLE (FALLBACK) ===
  ScannedVaccinationData _extractSingleVaccination(String text) {
    print('🔄 Extraction simple (fallback)...');
    
    // Cherche au moins une date
    final dateMatch = RegExp(r'\b(\d{1,2})[\.\/\-](\d{1,2})[\.\/\-](\d{1,4})\b').firstMatch(text);
    String date = _getCurrentDate();
    
    if (dateMatch != null) {
      final day = dateMatch.group(1)!.padLeft(2, '0');
      final month = dateMatch.group(2)!.padLeft(2, '0');
      final yearStr = dateMatch.group(3)!;
      String year = yearStr.length == 2 ? 
          (int.parse(yearStr) <= 30 ? '20$yearStr' : '19$yearStr') : 
          yearStr;
      date = '$day/$month/$year';
    }
    
    // Cherche un nom de vaccin plausible
    String vaccineName = 'Vaccination détectée';
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    
    for (final line in lines) {
      final extractedName = _extractVaccineName(line);
      if (extractedName != 'Vaccination' && extractedName.length > vaccineName.length) {
        vaccineName = extractedName;
        break;
      }
    }
    
    return ScannedVaccinationData(
      vaccineName: vaccineName,
      lot: '', // Lot optionnel
      date: date,
      ps: 'Données partielles extraites',
      confidence: 0.5,
    );
  }

  // === MÉTHODES UTILITAIRES ===
  
  bool _isHeaderLine(String line) {
    final headerKeywords = [
      'nom', 'prénom', 'prénoms', 'né(e)', 'date de naissance',
      'vaccin', 'dose', 'lot', 'signature', 'cachet', 'médecin',
      'vaccination', 'antipoliomyélitique', 'antidiphtérique',
      'antitétanique', 'anticoquelucheuse', 'antihaemophilus',
    ];
    
    final lowerLine = line.toLowerCase();
    final hasKeyword = headerKeywords.any((keyword) => lowerLine.contains(keyword));
    final hasDate = RegExp(r'\d{1,2}[\.\/\-]\d{1,2}[\.\/\-]\d{1,4}').hasMatch(line);
    
    return hasKeyword && !hasDate;
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  ScannedVaccinationData _createFallbackResult(String message) {
    return ScannedVaccinationData(
      vaccineName: 'Analyse incomplète',
      lot: '', // Lot optionnel
      date: _getCurrentDate(),
      ps: message,
      confidence: 0.2,
    );
  }
}