// lib/utils/vaccination_parser_test.dart - Test utility for debugging vaccination parsing
import 'package:flutter/material.dart';
import '../services/french_vaccination_parser.dart';
import '../constants/app_colors.dart';

class VaccinationParserTestScreen extends StatefulWidget {
  final String imagePath;
  
  const VaccinationParserTestScreen({
    Key? key,
    required this.imagePath,
  }) : super(key: key);

  @override
  State<VaccinationParserTestScreen> createState() => _VaccinationParserTestScreenState();
}

class _VaccinationParserTestScreenState extends State<VaccinationParserTestScreen> {
  final _parser = FrenchVaccinationParser();
  List<VaccinationEntry> _results = [];
  bool _isProcessing = false;
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    setState(() {
      _isProcessing = true;
      _debugInfo = '';
    });

    try {
      final results = await _parser.processVaccinationCard(widget.imagePath);
      
      setState(() {
        _results = results;
        _isProcessing = false;
        _debugInfo = 'Processing completed successfully';
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _debugInfo = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vaccination Parser Test'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildImagePreview(),
            const SizedBox(height: 20),
            _buildResults(),
            const SizedBox(height: 20),
            _buildDebugInfo(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _processImage,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vaccination Parser Test Results',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Image: ${widget.imagePath.split('/').last}',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Status: ${_isProcessing ? "Processing..." : "Complete"}',
            style: TextStyle(
              fontSize: 14,
              color: _isProcessing ? AppColors.warning : AppColors.success,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textMuted.withOpacity(0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          widget.imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  SizedBox(height: 8),
                  Text('Error loading image'),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_isProcessing) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_results.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.warning_amber, size: 48, color: AppColors.warning),
              SizedBox(height: 12),
              Text(
                'No Vaccinations Detected',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'The parser could not detect any vaccination entries in this image.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success),
              const SizedBox(width: 12),
              Text(
                '${_results.length} Vaccination(s) Detected',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(_results.length, (index) {
          final vaccination = _results[index];
          return _buildVaccinationCard(vaccination, index + 1);
        }),
      ],
    );
  }

  Widget _buildVaccinationCard(VaccinationEntry vaccination, int index) {
    final confidenceColor = vaccination.confidence >= 0.8 
        ? AppColors.success 
        : vaccination.confidence >= 0.5 
            ? AppColors.warning 
            : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textMuted.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: confidenceColor.withOpacity(0.1),
          child: Text(
            index.toString(),
            style: TextStyle(
              color: confidenceColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          vaccination.vaccineName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        subtitle: Text(
          '${vaccination.date} • Confidence: ${(vaccination.confidence * 100).toStringAsFixed(1)}%',
          style: TextStyle(
            color: confidenceColor,
            fontSize: 12,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('📅 Date:', vaccination.date),
                _buildDetailRow('💉 Vaccine:', vaccination.vaccineName),
                _buildDetailRow('🏷️ Lot:', vaccination.lot.isNotEmpty ? vaccination.lot : 'Not detected'),
                _buildDetailRow('📋 Line:', vaccination.lineNumber.toString()),
                _buildDetailRow('🎯 Confidence:', '${(vaccination.confidence * 100).toStringAsFixed(1)}%'),
                const SizedBox(height: 12),
                const Text(
                  'Raw Line:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    vaccination.rawLine,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.info),
              SizedBox(width: 8),
              Text(
                'Debug Information',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _debugInfo,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Parser Features:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          ...[
            '• Detects French vaccination card format',
            '• Extracts multiple vaccinations per page',
            '• Handles various date formats (DD/MM/YY, DD/MM/YYYY)',
            '• Recognizes French vaccine names and brands',
            '• Extracts lot numbers with flexible patterns',
            '• Calculates confidence scores for each entry',
            '• Filters out header lines and invalid entries',
          ].map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              feature,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          )),
        ],
      ),
    );
  }
}

// Usage example widget
class VaccinationParserDemo extends StatelessWidget {
  const VaccinationParserDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vaccination Parser Demo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.document_scanner,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 24),
            const Text(
              'French Vaccination Card Parser',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'This parser is optimized for French vaccination cards '
                'with horizontal table format containing date, vaccine name, and lot number.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Example usage - replace with actual image path
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VaccinationParserTestScreen(
                      imagePath: 'path/to/your/vaccination/card/image.jpg',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Test Parser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}