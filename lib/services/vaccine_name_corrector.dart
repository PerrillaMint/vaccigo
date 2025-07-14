// lib/services/vaccine_name_corrector.dart - Updated with French vaccination card brands
import 'dart:math';

class MatchResult {
  final String originalText;
  final String correctedName;
  final String standardizedName;
  final double similarity;
  final double confidence;
  final String matchType;
  final List<String> alternatives;

  MatchResult({
    required this.originalText,
    required this.correctedName,
    required this.standardizedName,
    required this.similarity,
    required this.confidence,
    required this.matchType,
    this.alternatives = const [],
  });

  bool get isReliable => confidence >= 0.85;
  bool get needsReview => confidence >= 0.60 && confidence < 0.85;
  bool get shouldReject => confidence < 0.60;

  @override
  String toString() {
    return 'MatchResult(original: "$originalText" → corrected: "$correctedName", confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
  }
}

class VaccineNameCorrector {
  // === ENHANCED FRENCH VACCINE DATABASE ===
  // Updated with brands commonly found in French vaccination cards
  static const Map<String, List<String>> _frenchVaccineDatabase = {
    // === HEXAVALENT VACCINES (6-in-1) ===
    'Infanrix Hexa (DTP-Coqueluche-Hib-Hépatite B)': [
      'infanrix', 'infanrix hexa', 'infanrix-hexa', 'infanri', 'infanr',
      'hexavalent', 'hexa', 'dtp-coqueluche-hib-hepatite b', 'infanrix6'
    ],
    'Hexyon (DTP-Coqueluche-Hib-Hépatite B)': [
      'hexyon', 'hexyonb', 'hexyo', 'sanofi hexa', 'hexavalent sanofi'
    ],
    'Vaxelis (DTP-Coqueluche-Hib-Hépatite B)': [
      'vaxelis', 'vaxeli', 'vaxel', 'hexavalent mcv'
    ],

    // === PENTAVALENT VACCINES (5-in-1) ===
    'Pentalog (DTP-Coqueluche-Hib)': [
      'pentalog', 'pental', 'pentalo', 'pentalogue', 'pentavac',
      'pentavalent', 'penta', 'dtp-coqueluche-hib'
    ],
    'Infanrix Penta (DTP-Coqueluche-Hib)': [
      'infanrix penta', 'infanrix-penta', 'infanrix5', 'pentavalent infanrix'
    ],
    'Pentavac (DTP-Coqueluche-Hib)': [
      'pentavac', 'pentava', 'pentav', 'sanofi penta'
    ],

    // === DTP COMBINATIONS ===
    'Tétravac (DTP-Coqueluche)': [
      'tetravac', 'tetra', 'tétravac', 'tetrava', 'tetrav',
      'dtp-coqueluche', 'tetravalent'
    ],
    'Repevax (DTP-Coqueluche rappel adolescent/adulte)': [
      'repevax', 'repeva', 'repev', 'rep', 'rappel dtp', 'dtp rappel',
      'coqueluche rappel', 'rappel adolescent'
    ],
    'Revaxis (DT-Polio rappel)': [
      'revaxis', 'revaxi', 'revax', 'dt-polio', 'dtpolio', 'dtp sans coqueluche',
      'rappel dt', 'diphterie tetanos polio'
    ],
    'Boostrix (DTP-Coqueluche rappel)': [
      'boostrix', 'boostr', 'boost', 'gsk rappel'
    ],

    // === ROR (MMR) VACCINES ===
    'Priorix (ROR - Rougeole-Oreillons-Rubéole)': [
      'priorix', 'priori', 'prior', 'ror', 'mmr', 'rougeole oreillons rubeole',
      'rougeole-oreillons-rubéole', 'ror priorix', 'gsk ror'
    ],
    'ROR-Vax (Rougeole-Oreillons-Rubéole)': [
      'ror-vax', 'rorvax', 'ror vax', 'sanofi ror'
    ],

    // === PNEUMOCOCCAL VACCINES ===
    'Prevenar 13 (Pneumocoque conjugué)': [
      'prevenar', 'prevenar 13', 'prevena', 'preven', 'pneumo prevenar',
      'pneumocoque prevenar', 'prevnar', 'prevnar 13', 'pfizer pneumo'
    ],
    'Pneumovax 23 (Pneumocoque polysaccharidique)': [
      'pneumovax', 'pneumovax 23', 'pneumova', 'pneumov', 'pneumo 23',
      'pneumocoque 23', 'msd pneumo'
    ],
    'Synflorix (Pneumocoque 10-valent)': [
      'synflorix', 'synflori', 'synflor', 'pneumo 10', 'gsk pneumo'
    ],

    // === MENINGOCOCCAL VACCINES ===
    'Méningitec (Méningocoque C)': [
      'meningitec', 'meningo', 'meningite', 'meningocoque c',
      'meningo c', 'pfizer meningo'
    ],
    'Menveo (Méningocoque ACWY)': [
      'menveo', 'menve', 'meningocoque acwy', 'meningo acwy',
      'gsk meningo', 'tetravalent meningo'
    ],
    'Nimenrix (Méningocoque ACWY)': [
      'nimenrix', 'nimen', 'meningocoque acwy', 'pfizer acwy'
    ],
    'Bexsero (Méningocoque B)': [
      'bexsero', 'bexser', 'bexs', 'meningocoque b', 'meningo b',
      'gsk meningo b'
    ],

    // === HEPATITIS VACCINES ===
    'Engerix B (Hépatite B)': [
      'engerix', 'engerix b', 'engerix-b', 'enger', 'engeri',
      'hepatite b', 'hep b', 'hbv', 'gsk hepatite'
    ],
    'Havrix (Hépatite A)': [
      'havrix', 'havri', 'havr', 'hepatite a', 'hep a', 'hav',
      'gsk hepatite a'
    ],
    'Twinrix (Hépatite A+B)': [
      'twinrix', 'twinri', 'twin', 'hepatite a+b', 'hep a+b',
      'hepatite ab', 'twinrix adulte'
    ],
    'HBVaxPro (Hépatite B)': [
      'hbvaxpro', 'hbvax', 'hbv', 'msd hepatite b'
    ],

    // === INFLUENZA VACCINES ===
    'Influvac (Grippe)': [
      'influvac', 'influ', 'grippe influvac', 'mylan grippe', 'abbott grippe'
    ],
    'Vaxigrip (Grippe)': [
      'vaxigrip', 'vaxigr', 'vaxi', 'grippe vaxigrip', 'sanofi grippe'
    ],
    'Fluarix (Grippe)': [
      'fluarix', 'fluari', 'fluar', 'grippe fluarix', 'gsk grippe'
    ],
    'Immugrip (Grippe)': [
      'immugrip', 'immugr', 'immu', 'pierre fabre grippe'
    ],

    // === HPV VACCINES ===
    'Gardasil 9 (Papillomavirus HPV)': [
      'gardasil', 'gardas', 'garda', 'gardasil 9', 'hpv gardasil',
      'papillomavirus gardasil', 'msd hpv'
    ],
    'Cervarix (Papillomavirus HPV)': [
      'cervarix', 'cervari', 'cerva', 'hpv cervarix', 'gsk hpv',
      'papillomavirus cervarix'
    ],

    // === VARICELLA/ZOSTER ===
    'Varilrix (Varicelle)': [
      'varilrix', 'varilri', 'varil', 'varicelle', 'chickenpox',
      'gsk varicelle'
    ],
    'Varivax (Varicelle)': [
      'varivax', 'variva', 'variv', 'msd varicelle'
    ],
    'Zostavax (Zona)': [
      'zostavax', 'zostava', 'zostav', 'zona', 'zoster', 'shingles',
      'msd zona'
    ],

    // === HAEMOPHILUS ===
    'Act-Hib (Haemophilus influenzae b)': [
      'act-hib', 'acthib', 'act hib', 'hib', 'haemophilus',
      'haemophilus b', 'sanofi hib'
    ],
    'Hiberix (Haemophilus influenzae b)': [
      'hiberix', 'hiberi', 'hiber', 'gsk hib'
    ],

    // === COVID-19 VACCINES ===
    'COVID-19 Pfizer-BioNTech (Comirnaty)': [
      'pfizer', 'biontech', 'comirnaty', 'pfizer-biontech', 'covid-19 pfizer',
      'covid pfizer', 'pfizer covid', 'comiraty', 'tozinameran'
    ],
    'COVID-19 Moderna (Spikevax)': [
      'moderna', 'spikevax', 'covid-19 moderna', 'covid moderna',
      'moderna covid', 'elasomeran'
    ],
    'COVID-19 AstraZeneca (Vaxzevria)': [
      'astrazeneca', 'vaxzevria', 'astra zeneca', 'covid-19 astrazeneca',
      'covid astrazeneca', 'astrazeneca covid', 'vaxevria', 'astra'
    ],
    'COVID-19 Janssen (Johnson & Johnson)': [
      'janssen', 'johnson', 'j&j', 'covid-19 janssen', 'covid janssen',
      'janssen covid', 'johnson johnson', 'jansen'
    ],

    // === TRAVEL VACCINES ===
    'Stamaril (Fièvre jaune)': [
      'stamaril', 'stamar', 'stama', 'fievre jaune', 'yellow fever',
      'sanofi fievre jaune'
    ],
    'Typhim Vi (Typhoïde)': [
      'typhim', 'typhim vi', 'typhi', 'typhoide', 'typhoid',
      'sanofi typhoid'
    ],
    'Ixiaro (Encéphalite japonaise)': [
      'ixiaro', 'ixiar', 'ixi', 'encephalite japonaise', 'japanese encephalitis'
    ],
    'Ticovac (Encéphalite à tiques)': [
      'ticovac', 'ticova', 'tico', 'encephalite tiques', 'tick borne encephalitis',
      'pfizer tbe'
    ],
    'Rabipur (Rage)': [
      'rabipur', 'rabipu', 'rabip', 'rage', 'rabies', 'gsk rage'
    ],
    'Verorab (Rage)': [
      'verorab', 'verora', 'veror', 'sanofi rage'
    ],

    // === OTHER COMMON VACCINES ===
    'BCG (Tuberculose)': [
      'bcg', 'tuberculose', 'tuberculosis', 'calmette guerin',
      'ssi bcg', 'biomed bcg'
    ],
    'Rotarix (Rotavirus)': [
      'rotarix', 'rotari', 'rotar', 'rotavirus', 'gsk rotavirus'
    ],
    'RotaTeq (Rotavirus)': [
      'rotateq', 'rotat', 'msd rotavirus'
    ],

    // === GENERIC TERMS ===
    'DTP (Diphtérie-Tétanos-Poliomyélite)': [
      'dtp', 'dt-polio', 'dtpolio', 'diphterie tetanos polio',
      'diphtérie tétanos poliomyélite'
    ],
    'Coqueluche (Pertussis)': [
      'coqueluche', 'pertussis', 'whooping cough', 'bordetella'
    ],
    'Pneumocoque': [
      'pneumocoque', 'pneumo', 'pneumococcal', 'pneumococcus'
    ],
    'Méningocoque': [
      'meningocoque', 'meningo', 'meningococcus', 'meningite'
    ],
    'Grippe saisonnière': [
      'grippe', 'influenza', 'flu', 'grippe saisonniere',
      'vaccin grippe', 'grippe annuelle'
    ],
  };

  // === SIMILARITY ALGORITHMS ===

  /// Calculates Levenshtein distance between two strings
  static int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final matrix = List.generate(
      s1.length + 1,
      (i) => List.filled(s2.length + 1, 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,     // deletion
          matrix[i][j - 1] + 1,     // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce(min);
      }
    }

    return matrix[s1.length][s2.length];
  }

  /// Calculates Jaro-Winkler similarity
  static double _jaroWinklerSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final jaro = _jaroSimilarity(s1, s2);
    if (jaro < 0.7) return jaro;

    // Calculate common prefix (up to 4 characters)
    int prefix = 0;
    final maxPrefix = min(min(s1.length, s2.length), 4);
    for (int i = 0; i < maxPrefix; i++) {
      if (s1[i] == s2[i]) {
        prefix++;
      } else {
        break;
      }
    }

    return jaro + (0.1 * prefix * (1 - jaro));
  }

  static double _jaroSimilarity(String s1, String s2) {
    final len1 = s1.length;
    final len2 = s2.length;

    if (len1 == 0 && len2 == 0) return 1.0;
    if (len1 == 0 || len2 == 0) return 0.0;

    final matchWindow = (max(len1, len2) / 2 - 1).floor();
    final s1Matches = List.filled(len1, false);
    final s2Matches = List.filled(len2, false);

    int matches = 0;
    int transpositions = 0;

    // Find matches
    for (int i = 0; i < len1; i++) {
      final start = max(0, i - matchWindow);
      final end = min(i + matchWindow + 1, len2);

      for (int j = start; j < end; j++) {
        if (s2Matches[j] || s1[i] != s2[j]) continue;
        s1Matches[i] = true;
        s2Matches[j] = true;
        matches++;
        break;
      }
    }

    if (matches == 0) return 0.0;

    // Count transpositions
    int k = 0;
    for (int i = 0; i < len1; i++) {
      if (!s1Matches[i]) continue;
      while (!s2Matches[k]) k++;
      if (s1[i] != s2[k]) transpositions++;
      k++;
    }

    return (matches / len1 + matches / len2 + (matches - transpositions / 2) / matches) / 3;
  }

  /// Calculates Jaccard similarity for character sets
  static double _jaccardSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty && s2.isEmpty) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final set1 = s1.toLowerCase().split('').toSet();
    final set2 = s2.toLowerCase().split('').toSet();

    final intersection = set1.intersection(set2).length;
    final union = set1.union(set2).length;

    return intersection / union;
  }

  /// Calculates weighted similarity combining multiple algorithms
  static double _calculateWeightedSimilarity(String s1, String s2) {
    final levenshtein = 1.0 - (_levenshteinDistance(s1, s2) / max(s1.length, s2.length));
    final jaroWinkler = _jaroWinklerSimilarity(s1, s2);
    final jaccard = _jaccardSimilarity(s1, s2);

    // Weighted combination optimized for medical terms
    return (levenshtein * 0.4) + (jaroWinkler * 0.5) + (jaccard * 0.1);
  }

  /// Preprocesses text for better matching
  static String _preprocessText(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s\-]'), ' ')  // Remove special chars except hyphens
        .replaceAll(RegExp(r'\s+'), ' ')        // Normalize whitespace
        .replaceAll(RegExp(r'\-+'), '-')        // Normalize hyphens
        .trim();
  }

  /// Enhanced prefix matching for brand names
  static double _calculatePrefixSimilarity(String s1, String s2) {
    final minLength = min(s1.length, s2.length);
    if (minLength < 3) return 0.0;
    
    int matchingChars = 0;
    for (int i = 0; i < minLength; i++) {
      if (s1[i] == s2[i]) {
        matchingChars++;
      } else {
        break;
      }
    }
    
    // Boost score for good prefix matches
    return matchingChars / max(s1.length, s2.length);
  }

  /// Finds the best match for a vaccine name
  static MatchResult correctVaccineName(String ocrText) {
    if (ocrText.trim().isEmpty) {
      return MatchResult(
        originalText: ocrText,
        correctedName: 'Vaccination',
        standardizedName: 'Vaccination',
        similarity: 0.0,
        confidence: 0.0,
        matchType: 'empty_input',
      );
    }

    final processedInput = _preprocessText(ocrText);
    final matches = <_MatchCandidate>[];

    // Search through all vaccine names and their variants
    for (final entry in _frenchVaccineDatabase.entries) {
      final standardName = entry.key;
      final variants = entry.value;

      // Check against standard name
      final standardSimilarity = _calculateWeightedSimilarity(processedInput, _preprocessText(standardName));
      if (standardSimilarity > 0.4) {
        matches.add(_MatchCandidate(
          standardName: standardName,
          matchedVariant: standardName,
          similarity: standardSimilarity,
          matchType: 'standard',
        ));
      }

      // Check against all variants
      for (final variant in variants) {
        final processedVariant = _preprocessText(variant);
        final variantSimilarity = _calculateWeightedSimilarity(processedInput, processedVariant);
        final prefixSimilarity = _calculatePrefixSimilarity(processedInput, processedVariant);
        
        // Combine weighted and prefix similarities
        final combinedSimilarity = (variantSimilarity * 0.8) + (prefixSimilarity * 0.2);
        
        if (combinedSimilarity > 0.4) {
          matches.add(_MatchCandidate(
            standardName: standardName,
            matchedVariant: variant,
            similarity: combinedSimilarity,
            matchType: 'variant',
          ));
        }
      }
    }

    if (matches.isEmpty) {
      return MatchResult(
        originalText: ocrText,
        correctedName: ocrText,
        standardizedName: 'Vaccination non identifiée',
        similarity: 0.0,
        confidence: 0.0,
        matchType: 'no_match',
      );
    }

    // Sort by similarity and pick the best match
    matches.sort((a, b) => b.similarity.compareTo(a.similarity));
    final bestMatch = matches.first;

    // Calculate confidence based on similarity and context
    double confidence = bestMatch.similarity;
    
    // Boost confidence for exact matches
    if (processedInput == _preprocessText(bestMatch.matchedVariant)) {
      confidence = 1.0;
    }
    
    // Boost confidence for high-similarity prefix matches
    if (confidence > 0.7 && _hasCommonPrefix(processedInput, _preprocessText(bestMatch.matchedVariant))) {
      confidence = min(1.0, confidence + 0.15);
    }

    // Boost confidence for common French vaccine brands
    if (_isCommonFrenchBrand(bestMatch.matchedVariant)) {
      confidence = min(1.0, confidence + 0.1);
    }

    // Penalty for very short matches unless they're exact
    if (processedInput.length < 4 && confidence < 0.9) {
      confidence *= 0.9;
    }

    // Get alternative matches
    final alternatives = matches
        .skip(1)
        .take(3)
        .where((match) => match.similarity > 0.6)
        .map((match) => match.standardName)
        .toList();

    return MatchResult(
      originalText: ocrText,
      correctedName: bestMatch.matchedVariant,
      standardizedName: bestMatch.standardName,
      similarity: bestMatch.similarity,
      confidence: confidence,
      matchType: bestMatch.matchType,
      alternatives: alternatives,
    );
  }

  /// Checks if a vaccine name is a common French brand
  static bool _isCommonFrenchBrand(String name) {
    final commonBrands = {
      'infanrix', 'pentalog', 'repevax', 'revaxis', 'priorix', 'prevenar',
      'meningitec', 'engerix', 'havrix', 'twinrix', 'vaxigrip', 'influvac',
      'gardasil', 'cervarix', 'tetravac', 'hexyon', 'vaxelis'
    };
    
    return commonBrands.contains(name.toLowerCase());
  }

  /// Checks if two strings have a common prefix of at least 3 characters
  static bool _hasCommonPrefix(String s1, String s2) {
    final minLength = min(s1.length, s2.length);
    if (minLength < 3) return false;
    
    for (int i = 0; i < min(minLength, 4); i++) {
      if (s1[i] != s2[i]) return false;
    }
    return true;
  }

  /// Finds multiple potential matches with confidence scores
  static List<MatchResult> findMultipleMatches(String ocrText, {int maxResults = 5}) {
    if (ocrText.trim().isEmpty) return [];

    final processedInput = _preprocessText(ocrText);
    final matches = <_MatchCandidate>[];

    // Search through all vaccine names and their variants
    for (final entry in _frenchVaccineDatabase.entries) {
      final standardName = entry.key;
      final variants = entry.value;

      // Check against standard name
      final standardSimilarity = _calculateWeightedSimilarity(processedInput, _preprocessText(standardName));
      if (standardSimilarity > 0.5) {
        matches.add(_MatchCandidate(
          standardName: standardName,
          matchedVariant: standardName,
          similarity: standardSimilarity,
          matchType: 'standard',
        ));
      }

      // Check against variants
      for (final variant in variants) {
        final processedVariant = _preprocessText(variant);
        final variantSimilarity = _calculateWeightedSimilarity(processedInput, processedVariant);
        final prefixSimilarity = _calculatePrefixSimilarity(processedInput, processedVariant);
        
        final combinedSimilarity = (variantSimilarity * 0.8) + (prefixSimilarity * 0.2);
        
        if (combinedSimilarity > 0.5) {
          matches.add(_MatchCandidate(
            standardName: standardName,
            matchedVariant: variant,
            similarity: combinedSimilarity,
            matchType: 'variant',
          ));
        }
      }
    }

    // Sort by similarity and remove duplicates
    matches.sort((a, b) => b.similarity.compareTo(a.similarity));
    final uniqueMatches = <String, _MatchCandidate>{};
    
    for (final match in matches) {
      if (!uniqueMatches.containsKey(match.standardName)) {
        uniqueMatches[match.standardName] = match;
      }
    }

    // Convert to MatchResult objects
    return uniqueMatches.values
        .take(maxResults)
        .map((match) {
          double confidence = match.similarity;
          
          if (processedInput == _preprocessText(match.matchedVariant)) {
            confidence = 1.0;
          } else if (confidence > 0.7 && _hasCommonPrefix(processedInput, _preprocessText(match.matchedVariant))) {
            confidence = min(1.0, confidence + 0.15);
          }

          if (_isCommonFrenchBrand(match.matchedVariant)) {
            confidence = min(1.0, confidence + 0.1);
          }

          return MatchResult(
            originalText: ocrText,
            correctedName: match.matchedVariant,
            standardizedName: match.standardName,
            similarity: match.similarity,
            confidence: confidence,
            matchType: match.matchType,
          );
        })
        .toList();
  }

  /// Gets all available vaccine names for reference
  static List<String> getAllVaccineNames() {
    return _frenchVaccineDatabase.keys.toList()..sort();
  }

  /// Gets variants for a specific vaccine
  static List<String> getVaccineVariants(String vaccineName) {
    return _frenchVaccineDatabase[vaccineName] ?? [];
  }

  /// Validates if a string could be a vaccine name
  static bool couldBeVaccineName(String text) {
    if (text.trim().length < 3) return false;
    
    final result = correctVaccineName(text);
    return result.confidence > 0.4;
  }
}

/// Internal class for match candidates
class _MatchCandidate {
  final String standardName;
  final String matchedVariant;
  final double similarity;
  final String matchType;

  _MatchCandidate({
    required this.standardName,
    required this.matchedVariant,
    required this.similarity,
    required this.matchType,
  });
}