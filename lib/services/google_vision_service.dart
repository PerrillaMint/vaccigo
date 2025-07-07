// lib/services/google_vision_service.dart - Service d'analyse d'images par IA avec extraction améliorée
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:google_ml_kit/google_ml_kit.dart';
import '../models/scanned_vaccination_data.dart';

// Service principal pour l'analyse intelligente des carnets de vaccination
// Utilise deux approches: ML Kit (local) et Google Cloud Vision API (cloud)
// Extrait automatiquement: nom du vaccin, numéro de lot, date, et infos supplémentaires
class GoogleVisionService {
  // Clé API Google Cloud Vision - remplacez par votre vraie clé
  static const String _apiKey = 'AIzaSyCaes3fAkFgeRjyUMejW710_PXhDPA8ADM';
  static const String _baseUrl = 'https://vision.googleapis.com/v1/images:annotate';

  // === MÉTHODE PRINCIPALE DE TRAITEMENT ===
  // Analyse une image de carnet de vaccination et extrait les données structurées
  Future<ScannedVaccinationData> processVaccinationImage(String imagePath) async {
    try {
      print('🔍 Démarrage de l\'analyse IA de l\'image: $imagePath');
      
      // Essaie toujours ML Kit en premier pour un traitement plus rapide
      // ML Kit fonctionne hors ligne et ne consomme pas de quota API
      final mlKitResult = await _processWithMLKit(imagePath);
      
      print('📊 Analyse ML Kit terminée - Confiance: ${mlKitResult.confidence}');
      
      // Si la confiance ML Kit est très faible, essaie Cloud Vision comme fallback
      // Cloud Vision est plus puissant mais nécessite une connexion internet
      if (mlKitResult.confidence < 0.3 && _apiKey != 'AIzaSyCaes3fAkFgeRjyUMejW710_PXhDPA8ADM') {
        print('🌐 Tentative avec Google Cloud Vision API pour de meilleurs résultats...');
        try {
          final cloudResult = await _processWithCloudVision(imagePath);
          print('📊 Analyse Cloud Vision terminée - Confiance: ${cloudResult.confidence}');
          
          // Retourne le meilleur résultat entre les deux
          if (cloudResult.confidence > mlKitResult.confidence) {
            return cloudResult;
          }
        } catch (e) {
          print('⚠️  Google Cloud Vision API a échoué, utilise le résultat ML Kit: $e');
        }
      }
      
      return mlKitResult;
    } catch (e) {
      print('❌ Le traitement IA a échoué: $e');
      
      // Retourne un résultat avec des données extraites même si le traitement a échoué
      // Permet à l'utilisateur de corriger manuellement
      return ScannedVaccinationData(
        vaccineName: 'Analyse incomplète',
        lot: '',
        date: _getCurrentDate(),
        ps: 'Veuillez vérifier et corriger les informations',
        confidence: 0.1,
      );
    }
  }

  // === TRAITEMENT AVEC ML KIT (LOCAL) ===
  // Utilise Google ML Kit pour la reconnaissance de texte hors ligne
  Future<ScannedVaccinationData> _processWithMLKit(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer();
    
    try {
      print('🤖 Traitement avec ML Kit...');
      
      // Exécute la reconnaissance de texte
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      print('📝 Texte extrait (${recognizedText.text.length} caractères):');
      print(recognizedText.text.substring(0, recognizedText.text.length > 200 ? 200 : recognizedText.text.length));
      
      // Extrait les données de vaccination du texte reconnu
      final extractedData = _extractVaccinationData(recognizedText.text);
      
      return ScannedVaccinationData(
        vaccineName: extractedData['vaccine'] ?? 'Non détecté',
        lot: extractedData['lot'] ?? '',
        date: extractedData['date'] ?? _getCurrentDate(),
        ps: extractedData['ps'] ?? '',
        confidence: extractedData['confidence'] ?? 0.5,
      );
    } catch (e) {
      print('❌ Erreur de traitement ML Kit: $e');
      rethrow;
    } finally {
      // Ferme le recognizer pour libérer les ressources
      textRecognizer.close();
    }
  }

  // === TRAITEMENT AVEC GOOGLE CLOUD VISION ===
  // Utilise l'API Cloud Vision pour une reconnaissance plus avancée
  Future<ScannedVaccinationData> _processWithCloudVision(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final base64Image = base64Encode(bytes);

    // Prépare la requête pour l'API Cloud Vision
    final requestBody = {
      'requests': [
        {
          'image': {'content': base64Image},
          'features': [
            {'type': 'TEXT_DETECTION', 'maxResults': 1},           // Détection de texte simple
            {'type': 'DOCUMENT_TEXT_DETECTION', 'maxResults': 1}   // Détection de texte documentaire
          ],
          'imageContext': {
            'languageHints': ['en', 'fr', 'es', 'de'] // Support de plusieurs langues
          }
        }
      ]
    };

    print('🌐 Envoi de la requête à Cloud Vision API...');
    
    final response = await http.post(
      Uri.parse('$_baseUrl?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final detectedText = _extractTextFromResponse(jsonResponse);
      
      print('📝 Texte extrait par Cloud Vision (${detectedText.length} caractères):');
      print(detectedText.substring(0, detectedText.length > 200 ? 200 : detectedText.length));
      
      final extractedData = _extractVaccinationData(detectedText);
      
      return ScannedVaccinationData(
        vaccineName: extractedData['vaccine'] ?? 'Non détecté',
        lot: extractedData['lot'] ?? '',
        date: extractedData['date'] ?? _getCurrentDate(),
        ps: extractedData['ps'] ?? '',
        confidence: (extractedData['confidence'] ?? 0.6) + 0.2, // Bonus de confiance pour Cloud Vision
      );
    } else {
      throw Exception('Erreur API Vision: ${response.statusCode} - ${response.body}');
    }
  }

  // Extrait le texte de la réponse JSON de Cloud Vision
  String _extractTextFromResponse(Map<String, dynamic> response) {
    try {
      final annotations = response['responses'][0]['textAnnotations'];
      if (annotations != null && annotations.isNotEmpty) {
        return annotations[0]['description'] ?? '';
      }
      return '';
    } catch (e) {
      print('Erreur lors de l\'extraction de texte de la réponse: $e');
      return '';
    }
  }

  // === EXTRACTION INTELLIGENTE DES DONNÉES ===
  // Analyse le texte extrait et identifie les informations de vaccination
  Map<String, dynamic> _extractVaccinationData(String text) {
    print('🔍 Analyse du texte extrait pour les données de vaccination...');
    
    // Divise le texte en lignes propres pour l'analyse
    final lines = text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
    
    String vaccine = '';
    String lot = '';
    String date = '';
    String ps = '';
    double confidence = 0.2; // Confiance de base

    // === PATTERNS POUR LES NOMS DE VACCINS ===
    // Expressions régulières pour identifier différents types de vaccins
    final vaccinePatterns = [
      // Vaccins COVID-19
      RegExp(r'(pfizer|biontech|comirnaty)', caseSensitive: false),
      RegExp(r'(moderna|spikevax)', caseSensitive: false),
      RegExp(r'(astrazeneca|vaxzevria|covishield)', caseSensitive: false),
      RegExp(r'(johnson|janssen|j&j)', caseSensitive: false),
      RegExp(r'(novavax|nuvaxovid)', caseSensitive: false),
      RegExp(r'(sinopharm|sinovac|coronavac)', caseSensitive: false),
      RegExp(r'(sputnik)', caseSensitive: false),
      
      // Vaccins traditionnels
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
      
      // Patterns génériques
      RegExp(r'(?:vaccin|vaccine|immunization)[\s:]*([^\n\r]{1,50})', caseSensitive: false),
      RegExp(r'(?:covid|corona|sars[\-\s]*cov[\-\s]*2)[\s\-]*([^\n\r]{0,30})', caseSensitive: false),
    ];

    // === PATTERNS POUR LES NUMÉROS DE LOT ===
    final lotPatterns = [
      // Patterns standards de lot
      RegExp(r'(?:lot|batch|série|serial)[\s#:]*([A-Z0-9\-]{3,15})', caseSensitive: false),
      RegExp(r'\b([A-Z]{2,4}[0-9]{3,8})\b'),
      RegExp(r'\b([0-9]{4,8}[A-Z]{1,4})\b'),
      RegExp(r'\b([A-Z0-9]{6,12})\b'), // Alphanumériques génériques
      
      // Patterns spécifiques COVID
      RegExp(r'\b(EW[0-9]{4})\b'), // Pattern Pfizer
      RegExp(r'\b(FF[0-9]{4})\b'), // Pattern Pfizer
      RegExp(r'\b([0-9]{6}[A-Z])\b'), // Pattern Moderna
      RegExp(r'\b(ABW[0-9]{3})\b'), // Pattern AstraZeneca
    ];

    // === PATTERNS POUR LES DATES ===
    final datePatterns = [
      // Format européen DD/MM/YYYY
      RegExp(r'(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})'),
      // Format américain MM/DD/YYYY
      RegExp(r'(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})'),
      // Format ISO YYYY-MM-DD
      RegExp(r'(\d{4}[\/\-\.]\d{1,2}[\/\-\.]\d{1,2})'),
      // Date avec texte
      RegExp(r'(?:date|administered|given|injection|dose)[\s:]*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})', caseSensitive: false),
      // Noms de mois
      RegExp(r'(\d{1,2}\s+(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+\d{2,4})', caseSensitive: false),
      RegExp(r'(\d{1,2}\s+(?:janvier|février|mars|avril|mai|juin|juillet|août|septembre|octobre|novembre|décembre)\s+\d{2,4})', caseSensitive: false),
    ];

    // === PATTERNS POUR INFORMATIONS SUPPLÉMENTAIRES ===
    final psPatterns = [
      RegExp(r'(?:dose|rappel|booster|première|deuxième|troisième|1ère|2ème|3ème)[\s:]*([^\n\r]{0,50})', caseSensitive: false),
      RegExp(r'(?:notes?|remarks?|observations?|commentaire)[\s:]*([^\n\r]{0,100})', caseSensitive: false),
      RegExp(r'(?:médecin|doctor|dr\.?|pharmacien|infirmier)[\s:]*([^\n\r]{0,50})', caseSensitive: false),
      RegExp(r'(?:site|lieu|location|center|centre)[\s:]*([^\n\r]{0,50})', caseSensitive: false),
    ];

    // === EXTRACTION DU NOM DE VACCIN ===
    // Essaie plusieurs approches pour identifier le vaccin
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
          print('✅ Vaccin trouvé: $vaccine');
        }
      }
    }

    // Si aucun vaccin spécifique trouvé, cherche une ligne qui pourrait être un nom de vaccin
    if (vaccine.isEmpty) {
      for (final line in lines) {
        if (line.length > 3 && line.length < 50 && 
            !RegExp(r'^\d+$').hasMatch(line) && // Pas seulement des chiffres
            !RegExp(r'^[\/\-\.]+$').hasMatch(line)) { // Pas seulement de la ponctuation
          vaccine = line;
          confidence += 0.1;
          print('📝 Vaccin deviné à partir de la ligne: $vaccine');
          break;
        }
      }
    }

    // === EXTRACTION DU NUMÉRO DE LOT ===
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
          print('✅ Lot trouvé: $lot');
          break;
        }
      }
    }

    // === EXTRACTION DE LA DATE ===
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
          print('✅ Date trouvée: $date');
          break;
        }
      }
    }

    // Si aucune date trouvée, utilise la date actuelle comme fallback
    if (date.isEmpty) {
      date = _getCurrentDate();
      print('📅 Utilise la date actuelle comme fallback: $date');
    }

    // === EXTRACTION DES INFORMATIONS SUPPLÉMENTAIRES ===
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
          print('✅ Info PS trouvée: $ps');
        }
      }
    }

    // === CALCUL DE LA CONFIANCE FINALE ===
    // Bonus de confiance si plusieurs champs ont été trouvés
    int fieldsFound = 0;
    if (vaccine.isNotEmpty) fieldsFound++;
    if (lot.isNotEmpty) fieldsFound++;
    if (date.isNotEmpty) fieldsFound++;
    if (ps.isNotEmpty) fieldsFound++;

    confidence += fieldsFound * 0.05;

    // S'assure d'une confiance minimale pour tout résultat
    confidence = confidence.clamp(0.3, 1.0);

    print('📊 Extraction terminée:');
    print('  Vaccin: "$vaccine"');
    print('  Lot: "$lot"');
    print('  Date: "$date"');
    print('  PS: "$ps"');
    print('  Confiance: ${(confidence * 100).toStringAsFixed(1)}%');

    return {
      'vaccine': vaccine,
      'lot': lot,
      'date': date,
      'ps': ps,
      'confidence': confidence,
    };
  }

  // === MÉTHODES UTILITAIRES ===
  
  // Valide qu'une chaîne ressemble à un format de date
  bool _isValidDateFormat(String dateStr) {
    // Vérifie différents formats de date
    final patterns = [
      RegExp(r'^\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4}$'),
      RegExp(r'^\d{4}[\/\-\.]\d{1,2}[\/\-\.]\d{1,2}$'),
      RegExp(r'^\d{1,2}\s+\w+\s+\d{2,4}$'),
    ];

    return patterns.any((pattern) => pattern.hasMatch(dateStr));
  }

  // Normalise une date vers le format DD/MM/YYYY
  String _normalizeDate(String dateStr) {
    try {
      // Essaie de parser et normaliser vers DD/MM/YYYY
      // Implémentation simple - vous pourriez vouloir un parsing plus sophistiqué
      
      // Gère DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY
      if (RegExp(r'^\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4}$').hasMatch(dateStr)) {
        final parts = dateStr.split(RegExp(r'[\/\-\.]'));
        if (parts.length == 3) {
          final day = parts[0].padLeft(2, '0');
          final month = parts[1].padLeft(2, '0');
          String year = parts[2];
          
          // Convertit l'année à 2 chiffres en 4 chiffres
          if (year.length == 2) {
            final currentYear = DateTime.now().year;
            final currentCentury = (currentYear ~/ 100) * 100;
            final twoDigitYear = int.parse(year);
            
            // Assume que les années 00-30 sont 20xx, 31-99 sont 19xx
            if (twoDigitYear <= 30) {
              year = (currentCentury + twoDigitYear).toString();
            } else {
              year = (currentCentury - 100 + twoDigitYear).toString();
            }
          }
          
          return '$day/$month/$year';
        }
      }
      
      // Retourne tel quel si impossible de normaliser
      return dateStr;
    } catch (e) {
      return dateStr;
    }
  }

  // Retourne la date actuelle au format DD/MM/YYYY
  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }
}