// lib/screens/onboarding/camera_scan_screen.dart - FIXED memory management and error handling
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../services/google_vision_service.dart';
import '../../services/camera_service.dart';
import '../../models/scanned_vaccination_data.dart';
import '../../constants/app_colors.dart';

class CameraScanScreen extends StatefulWidget {
  const CameraScanScreen({Key? key}) : super(key: key);

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen>
    with WidgetsBindingObserver {
  final GoogleVisionService _visionService = GoogleVisionService();
  CameraController? _cameraController;
  bool _isProcessing = false;
  bool _isInitialized = false;
  bool _flashOn = false;
  String? _error;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    switch (state) {
      case AppLifecycleState.inactive:
        _disposeCamera();
        break;
      case AppLifecycleState.resumed:
        if (!_isDisposed) {
          _initializeCamera();
        }
        break;
      default:
        break;
    }
  }

  Future<void> _initializeCamera() async {
    if (_isDisposed) return;
    
    setState(() {
      _error = null;
      _isInitialized = false;
    });

    try {
      // Check permissions first
      final hasPermissions = await CameraService.hasPermissions();
      if (!hasPermissions) {
        final permissionsGranted = await CameraService.requestPermissions();
        if (!permissionsGranted) {
          if (mounted && !_isDisposed) {
            setState(() {
              _error = 'Permissions de caméra requises pour scanner';
            });
          }
          return;
        }
      }

      // Check if cameras are available
      if (!CameraService.isAvailable) {
        if (mounted && !_isDisposed) {
          setState(() {
            _error = 'Aucune caméra disponible sur cet appareil';
          });
        }
        return;
      }

      // Get camera controller
      _cameraController = await CameraService.getCameraController();
      
      if (_cameraController != null && mounted && !_isDisposed) {
        setState(() {
          _isInitialized = true;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        setState(() {
          _error = 'Erreur d\'initialisation: ${e.toString()}';
          _isInitialized = false;
        });
      }
    }
  }

  Future<void> _disposeCamera() async {
    if (_cameraController != null) {
      try {
        await _cameraController!.dispose();
      } catch (e) {
        debugPrint('Error disposing camera: $e');
      } finally {
        _cameraController = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorView();
    }

    if (!_isInitialized || _cameraController == null) {
      return _buildLoadingView();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          _buildCameraPreview(),
          
          // Processing overlay
          if (_isProcessing) _buildProcessingOverlay(),
          
          // Scanning frame
          _buildScanningFrame(),
          
          // Control buttons
          _buildControlButtons(),
          
          // Back button
          _buildBackButton(),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Erreur de caméra',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _error ?? 'Une erreur inconnue s\'est produite',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Retour'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _initializeCamera,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Initialisation de la caméra...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _cameraController!.value.previewSize!.height,
          height: _cameraController!.value.previewSize!.width,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
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
    );
  }

  Widget _buildScanningFrame() {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.width * 1.2,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Positionnez votre carnet\ndans le cadre",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
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
    );
  }

  Widget _buildControlButtons() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: _flashOn ? Icons.flash_on : Icons.flash_off,
            onPressed: _isProcessing ? null : _toggleFlash,
          ),
          _buildCaptureButton(),
          _buildControlButton(
            icon: Icons.photo_library,
            onPressed: _isProcessing ? null : _selectFromGallery,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon, 
    VoidCallback? onPressed
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.6),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isProcessing ? Colors.grey : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
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
    );
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !CameraService.isControllerInitialized) {
      return;
    }
    
    try {
      _flashOn = !_flashOn;
      await _cameraController!.setFlashMode(
        _flashOn ? FlashMode.torch : FlashMode.off,
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error toggling flash: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de contrôler le flash'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _captureAndProcess() async {
    if (_isDisposed || _isProcessing) return;
    
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
      if (mounted && !_isDisposed) {
        Navigator.pushReplacementNamed(
          context, 
          '/scan-preview', 
          arguments: data,
        );
      }
    } catch (e) {
      debugPrint('Capture error: $e');
      _showErrorDialog('Erreur lors du traitement: ${e.toString()}');
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _selectFromGallery() async {
    if (_isDisposed || _isProcessing) return;
    
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
      
      if (mounted && !_isDisposed) {
        Navigator.pushReplacementNamed(
          context, 
          '/scan-preview', 
          arguments: data,
        );
      }
    } catch (e) {
      debugPrint('Gallery selection error: $e');
      _showErrorDialog('Erreur lors du traitement: ${e.toString()}');
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted || _isDisposed) return;
    
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