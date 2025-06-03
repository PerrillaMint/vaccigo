// lib/screens/onboarding/camera_scan_screen.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../services/google_vision_service.dart';
import '../../services/camera_service.dart';
import '../../models/scanned_vaccination_data.dart';

class CameraScanScreen extends StatefulWidget {
  const CameraScanScreen({Key? key}) : super(key: key);

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen> {
  final GoogleVisionService _visionService = GoogleVisionService();
  CameraController? _cameraController;
  bool _isProcessing = false;
  bool _isInitialized = false;
  bool _flashOn = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final hasPermissions = await CameraService.requestPermissions();
      if (!hasPermissions) {
        setState(() {
          _error = 'Permissions de caméra requises';
        });
        return;
      }

      _cameraController = await CameraService.getCameraController();
      
      if (_cameraController != null) {
        setState(() {
          _isInitialized = true;
        });
      } else {
        setState(() {
          _error = 'Impossible d\'initialiser la caméra';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur: $e';
      });
    }
  }

  @override
  void dispose() {
    CameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(_error!, style: TextStyle(fontSize: 16)),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Retour'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _cameraController == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initialisation de la caméra...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(_cameraController!),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      "IA en cours d'analyse...",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.width * 1.2,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    "Positionnez votre carnet\ndans le cadre",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.6),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _flashOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                    ),
                    onPressed: _isProcessing ? null : _toggleFlash,
                  ),
                ),
                GestureDetector(
                  onTap: _isProcessing ? null : _captureAndProcess,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      color: Colors.transparent,
                    ),
                    child: Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.6),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.photo_library, color: Colors.white),
                    onPressed: _isProcessing ? null : _selectFromGallery,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: GestureDetector(
              onTap: _isProcessing ? null : () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;
    
    try {
      _flashOn = !_flashOn;
      await _cameraController!.setFlashMode(
        _flashOn ? FlashMode.torch : FlashMode.off,
      );
      setState(() {});
    } catch (e) {
      print('Error toggling flash: $e');
    }
  }

  Future<void> _captureAndProcess() async {
    setState(() => _isProcessing = true);
    
    try {
      final imagePath = await CameraService.captureImage();
      
      if (imagePath == null) {
        throw Exception('Échec de la capture d\'image');
      }
      
      // Check if it's a valid vaccination card
      bool isValid = await _visionService.isValidVaccinationCard(imagePath);
      
      if (!isValid) {
        _showErrorDialog('Image non reconnue comme carnet de vaccination');
        return;
      }
      
      // Process with AI
      ScannedVaccinationData data = await _visionService.processVaccinationImage(imagePath);
      
      // Navigate to preview with extracted data
      if (mounted) {
        Navigator.pushReplacementNamed(
          context, 
          '/scan-preview', 
          arguments: data,
        );
      }
    } catch (e) {
      _showErrorDialog('Erreur lors du traitement: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _selectFromGallery() async {
    setState(() => _isProcessing = true);
    
    try {
      final imagePath = await CameraService.pickImageFromGallery();
      
      if (imagePath == null) {
        setState(() => _isProcessing = false);
        return;
      }
      
      bool isValid = await _visionService.isValidVaccinationCard(imagePath);
      
      if (!isValid) {
        _showErrorDialog('Image non reconnue comme carnet de vaccination');
        return;
      }
      
      ScannedVaccinationData data = await _visionService.processVaccinationImage(imagePath);
      
      if (mounted) {
        Navigator.pushReplacementNamed(
          context, 
          '/scan-preview', 
          arguments: data,
        );
      }
    } catch (e) {
      _showErrorDialog('Erreur lors du traitement: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
