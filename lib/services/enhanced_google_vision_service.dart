// lib/services/enhanced_google_vision_service.dart - Service amélioré pour scanner multiple vaccinations
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:google_ml_kit/google_ml_kit.dart';
import '../models/scanned_vaccination_data.dart';
import '../models/vaccination.dart';

// Structure pour représenter une ligne de vaccination dans un carnet
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

// Service principal amélioré pour l'analyse de carnets de vaccination
class EnhancedGoogleVisionService {
  static const String _apiKey = 'AIzaSyCaes3fAkFgeRjyUMejW710_PXhDPA8ADM';
  static const String _baseUrl = 'https://vision.googleapis.com/v1/images:annotate';

  // === MÉTHODE PRINCIPALE POUR TRAITEMENT MULTIPLE ===
  Future<List<VaccinationEntry>> processVaccinationCard(String imagePath) async {
    try {
      print('🔍 Démarrage de l\'analyse IA du carnet de vaccination: $imagePath');
      
      // Étape 1: Extraction du texte
      final extractedText = await _extractTextFromImage(imagePath);
      print('📝 Texte extrait (${extractedText.length} caractères)');
      
      // Étape 2: Détection du format de carnet
      final cardFormat = _detectCardFormat(extractedText);
      print('📋 Format de carnet détecté: $cardFormat');
      
      // Étape 3: Extraction des vaccinations selon le format
      List<VaccinationEntry> vaccinations;
      switch (cardFormat) {
        case CardFormat.frenchTable:
          vaccinations = _extractFromFrenchTableFormat(extractedText);
          break;
        case CardFormat.frenchList:
          vaccinations = _extractFromFrenchListFormat(extractedText);
          break;
        case CardFormat.international:
          vaccinations = _extractFromInternationalFormat(extractedText);
          break;
        default:
          vaccinations = _extractFromGenericFormat(extractedText);
      }
      
      print('✅ ${vaccinations.length} vaccination(s) extraite(s) du carnet');
      
      // Étape 4: Validation et amélioration des données
      vaccinations = _validateAndEnhanceVaccinations(vaccinations);
      
      return vaccinations;
    } catch (e) {
      print('❌ Erreur lors du traitement du carnet: $e');
      return [];
    }
  }

  // === EXTRACTION DE TEXTE AMÉLIORÉE ===
  Future<String> _extractTextFromImage(String imagePath) async {
    try {
      // Essaie ML Kit en premier
      final mlKitText = await _extractWithMLKit(imagePath);
      
      // Si ML Kit donne peu de résultats, essaie Cloud Vision
      if (mlKitText.length < 100 && _apiKey != 'AIzaSyCaes3fAkFgeRjyUMejW710_PXhDPA8ADM') {
        print('🌐 Tentative avec Cloud Vision pour plus de texte...');
        final cloudText = await _extractWithCloudVision(imagePath);
        return cloudText.isNotEmpty ? cloudText : mlKitText;
      }
      
      return mlKitText;
    } catch (e) {
      print('❌ Erreur extraction texte: $e');
      return '';
    }
  }

  Future<String> _extractWithMLKit(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer();
    
    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } finally {
      textRecognizer.close();
    }
  }

  Future<String> _extractWithCloudVision(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final base64Image = base64Encode(bytes);

    final requestBody = {
      'requests': [
        {
          'image': {'content': base64Image},
          'features': [
            {'type': 'DOCUMENT_TEXT_DETECTION', 'maxResults': 1}
          ],
          'imageContext': {
            'languageHints': ['fr', 'en', 'es', 'de']
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
      return _extractTextFromCloudResponse(jsonResponse);
    }
    
    throw Exception('Cloud Vision API error: ${response.statusCode}');
  }

  String _extractTextFromCloudResponse(Map<String, dynamic> response) {
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

  // === DÉTECTION DU FORMAT DE CARNET ===
  CardFormat _detectCardFormat(String text) {
    final lowerText = text.toLowerCase();
    
    // Détecte le format tableau français (comme dans l'image)
    if (_isFrenchTableFormat(lowerText)) {
      return CardFormat.frenchTable;
    }
    
    // Détecte le format liste français
    if (_isFrenchListFormat(lowerText)) {
      return CardFormat.frenchList;
    }
    
    // Détecte le format international
    if (_isInternationalFormat(lowerText)) {
      return CardFormat.international;
    }
    
    return CardFormat.generic;
  }

  bool _isFrenchTableFormat(String text) {
    // Caractéristiques du format tableau français visible dans l'image
    final indicators = [
      'vaccin',
      'dose',
      'lot',
      'signature',
      'médecin',
      'cachet',
      'date',
    ];
    
    int score = 0;
    for (final indicator in indicators) {
      if (text.contains(indicator)) score++;
    }
    
    // Vérifie aussi la présence de plusieurs dates
    final dateMatches = RegExp(r'\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4}').allMatches(text);
    if (dateMatches.length >= 2) score += 2;
    
    return score >= 4;
  }

  bool _isFrenchListFormat(String text) {
    return text.contains('carnet') && text.contains('vaccination') && 
           !_isFrenchTableFormat(text);
  }

  bool _isInternationalFormat(String text) {
    final englishIndicators = ['vaccine', 'immunization', 'vaccination record'];
    return englishIndicators.any((indicator) => text.contains(indicator));
  }

  // === EXTRACTION SPÉCIALISÉE PAR FORMAT ===
  
  // Extraction pour format tableau français (comme dans l'image)
  List<VaccinationEntry> _extractFromFrenchTableFormat(String text) {
    print('📊 Extraction format tableau français...');
    
    final lines = text.split('\n').map((line) => line.trim()).toList();
    final vaccinations = <VaccinationEntry>[];
    
    // Trouve les lignes contenant des données de vaccination
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      // Ignore les lignes d'en-tête et vides
      if (_isHeaderLine(line) || line.length < 5) continue;
      
      // Détecte si la ligne contient une date (indicateur de vaccination)
      final dateMatch = RegExp(r'\b(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})\b').firstMatch(line);
      
      if (dateMatch != null) {
        final vaccination = _extractVaccinationFromLine(line, i);
        if (vaccination != null) {
          vaccinations.add(vaccination);
        }
      }
    }
    
    print('✅ ${vaccinations.length} vaccinations extraites du tableau');
    return vaccinations;
  }

  // Extraction d'une vaccination à partir d'une ligne de tableau
  VaccinationEntry? _extractVaccinationFromLine(String line, int lineNumber) {
    try {
      String vaccineName = '';
      String lot = '';
      String date = '';
      String ps = '';
      double confidence = 0.3;
      
      // === EXTRACTION DE LA DATE ===
      final datePattern = RegExp(r'\b(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})\b');
      final dateMatch = datePattern.firstMatch(line);
      if (dateMatch != null) {
        date = _normalizeDate(dateMatch.group(1)!);
        confidence += 0.3;
      }
      
      // === EXTRACTION DU LOT ===
      // Patterns pour numéros de lot dans les carnets français
      final lotPatterns = [
        RegExp(r'\b([A-Z]{2,4}[0-9]{3,8})\b'), // Format type EW0553
        RegExp(r'\b([0-9]{4,8}[A-Z]{1,4})\b'), // Format type 12345A
        RegExp(r'\b([A-Z0-9]{6,12})\b'),       // Alphanumériques
      ];
      
      for (final pattern in lotPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final candidate = match.group(1)!;
          // Vérifie que ce n'est pas une date
          if (!RegExp(r'^\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4}$').hasMatch(candidate)) {
            lot = candidate;
            confidence += 0.2;
            break;
          }
        }
      }
      
      // === EXTRACTION DU NOM DE VACCIN ===
      // Enlève la date et le lot pour isoler le nom du vaccin
      String cleanedLine = line;
      if (dateMatch != null) {
        cleanedLine = cleanedLine.replaceAll(dateMatch.group(0)!, '');
      }
      if (lot.isNotEmpty) {
        cleanedLine = cleanedLine.replaceAll(lot, '');
      }
      
      // Nettoie et extrait le nom du vaccin
      cleanedLine = cleanedLine.replaceAll(RegExp(r'[^\w\s\-]'), ' ').trim();
      final words = cleanedLine.split(RegExp(r'\s+')).where((w) => w.length > 2).toList();
      
      if (words.isNotEmpty) {
        // Prend les premiers mots comme nom de vaccin
        vaccineName = words.take(3).join(' ');
        confidence += 0.3;
      }
      
      // === EXTRACTION DES INFOS PS ===
      // Cherche des indices de professionnel de santé
      final psIndicators = ['dr', 'med', 'pharm', 'inf'];
      for (final indicator in psIndicators) {
        if (line.toLowerCase().contains(indicator)) {
          ps = 'Professionnel de santé mentionné';
          confidence += 0.1;
          break;
        }
      }
      
      // Retourne seulement si on a au moins un nom de vaccin et une date
      if (vaccineName.isNotEmpty && date.isNotEmpty) {
        return VaccinationEntry(
          vaccineName: vaccineName,
          lot: lot,
          date: date,
          ps: ps,
          confidence: confidence.clamp(0.3, 1.0),
          lineNumber: lineNumber,
        );
      }
      
      return null;
    } catch (e) {
      print('Erreur extraction ligne: $e');
      return null;
    }
  }

  // Extraction pour format liste français
  List<VaccinationEntry> _extractFromFrenchListFormat(String text) {
    print('📝 Extraction format liste français...');
    return _extractFromGenericFormat(text);
  }

  // Extraction pour format international
  List<VaccinationEntry> _extractFromInternationalFormat(String text) {
    print('🌍 Extraction format international...');
    return _extractFromGenericFormat(text);
  }

  // Extraction générique (fallback)
  List<VaccinationEntry> _extractFromGenericFormat(String text) {
    print('🔄 Extraction format générique...');
    
    final lines = text.split('\n').map((line) => line.trim()).toList();
    final vaccinations = <VaccinationEntry>[];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.length < 10) continue;
      
      // Cherche des patterns de vaccination dans chaque ligne
      final hasDate = RegExp(r'\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4}').hasMatch(line);
      final hasVaccineKeyword = RegExp(r'(vaccin|vaccine|immuniz|inject)', caseSensitive: false).hasMatch(line);
      
      if (hasDate || hasVaccineKeyword) {
        final vaccination = _extractVaccinationFromLine(line, i);
        if (vaccination != null) {
          vaccinations.add(vaccination);
        }
      }
    }
    
    return vaccinations;
  }

  // === MÉTHODES UTILITAIRES ===
  
  bool _isHeaderLine(String line) {
    final headerKeywords = [
      'nom',
      'prénom', 
      'date de naissance',
      'vaccin',
      'dose',
      'lot',
      'signature',
      'médecin',
      'cachet',
      'prénoms',
      'né(e) le',
    ];
    
    final lowerLine = line.toLowerCase();
    return headerKeywords.any((keyword) => lowerLine.contains(keyword)) &&
           !RegExp(r'\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4}').hasMatch(line);
  }

  String _normalizeDate(String dateStr) {
    try {
      // Convertit différents formats vers DD/MM/YYYY
      if (RegExp(r'^\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4}$').hasMatch(dateStr)) {
        final parts = dateStr.split(RegExp(r'[\/\-\.]'));
        if (parts.length == 3) {
          final day = parts[0].padLeft(2, '0');
          final month = parts[1].padLeft(2, '0');
          String year = parts[2];
          
          // Convertit années 2 chiffres
          if (year.length == 2) {
            final twoDigitYear = int.parse(year);
            if (twoDigitYear <= 30) {
              year = (2000 + twoDigitYear).toString();
            } else {
              year = (1900 + twoDigitYear).toString();
            }
          }
          
          return '$day/$month/$year';
        }
      }
      return dateStr;
    } catch (e) {
      return dateStr;
    }
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  // === VALIDATION ET AMÉLIORATION DES DONNÉES ===
  List<VaccinationEntry> _validateAndEnhanceVaccinations(List<VaccinationEntry> vaccinations) {
    final enhanced = <VaccinationEntry>[];
    
    for (final vaccination in vaccinations) {
      // Valide que les données minimales sont présentes
      if (vaccination.vaccineName.isNotEmpty && vaccination.date.isNotEmpty) {
        // Améliore le nom du vaccin avec des synonymes connus
        final enhancedName = _enhanceVaccineName(vaccination.vaccineName);
        
        final enhancedVaccination = VaccinationEntry(
          vaccineName: enhancedName,
          lot: vaccination.lot,
          date: vaccination.date,
          ps: vaccination.ps,
          confidence: vaccination.confidence,
          lineNumber: vaccination.lineNumber,
        );
        
        enhanced.add(enhancedVaccination);
      }
    }
    
    // Trie par ligne pour conserver l'ordre du carnet
    enhanced.sort((a, b) => a.lineNumber.compareTo(b.lineNumber));
    
    return enhanced;
  }

  String _enhanceVaccineName(String rawName) {
    final lowerName = rawName.toLowerCase();
    
    // Dictionnaire d'amélioration des noms de vaccins
    final enhancements = {
      // Vaccins COVID
      'pfizer': 'Pfizer-BioNTech COVID-19',
      'biontech': 'Pfizer-BioNTech COVID-19',
      'moderna': 'Moderna COVID-19',
      'astrazeneca': 'AstraZeneca COVID-19',
      'janssen': 'Johnson & Johnson COVID-19',
      
      // Vaccins classiques
      'dtp': 'Diphtérie-Tétanos-Poliomyélite',
      'ror': 'Rougeole-Oreillons-Rubéole',
      'mmr': 'Rougeole-Oreillons-Rubéole',
      'hep': 'Hépatite',
      'grippe': 'Grippe saisonnière',
      'pneumo': 'Pneumocoque',
      'meningo': 'Méningocoque',
    };
    
    for (final entry in enhancements.entries) {
      if (lowerName.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Capitalise la première lettre de chaque mot
    return rawName.split(' ')
        .map((word) => word.isNotEmpty ? 
             word[0].toUpperCase() + word.substring(1).toLowerCase() : word)
        .join(' ');
  }

  // === CONVERSION VERS OBJETS VACCINATION ===
  List<Vaccination> convertToVaccinations(List<VaccinationEntry> entries, String userId) {
    return entries.map((entry) => Vaccination(
      vaccineName: entry.vaccineName,
      lot: entry.lot.isNotEmpty ? entry.lot : null,
      date: entry.date,
      ps: entry.ps.isNotEmpty ? entry.ps : 'Scanné automatiquement',
      userId: userId,
    )).toList();
  }

  // === MÉTHODE DE COMPATIBILITÉ ===
  // Pour maintenir la compatibilité avec l'ancien code
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
      confidence: 0.1,
    );
  }
}

// Énumération pour les formats de carnet
enum CardFormat {
  frenchTable,    // Format tableau français (comme dans l'image)
  frenchList,     // Format liste français
  international,  // Format international
  generic,        // Format générique/inconnu
}