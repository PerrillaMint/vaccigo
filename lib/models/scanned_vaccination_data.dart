// lib/models/scanned_vaccination_data.dart
class ScannedVaccinationData {
  final String vaccineName;
  final String lot;
  final String date;
  final String ps;
  final double confidence;

  ScannedVaccinationData({
    required this.vaccineName,
    required this.lot,
    required this.date,
    required this.ps,
    required this.confidence,
  });

  factory ScannedVaccinationData.fromAI(Map<String, dynamic> aiResult) {
    return ScannedVaccinationData(
      vaccineName: aiResult['vaccine_name'] ?? '',
      lot: aiResult['lot_number'] ?? '',
      date: aiResult['date'] ?? '',
      ps: aiResult['additional_info'] ?? '',
      confidence: (aiResult['confidence'] ?? 0.0).toDouble(),
    );
  }
}