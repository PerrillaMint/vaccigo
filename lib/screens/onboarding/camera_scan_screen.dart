// lib/screens/onboarding/camera_scan_screen.dart - FIXED overlay and control overflow issues
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
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  final GoogleVisionService _visionService = GoogleVisionService();
  CameraController? _cameraController;
  bool _isProcessing = false;
  bool _isInitialized = false;
  bool _flashOn = false;
  String? _error;
  bool _isDisposed = false;
  bool _isMounted = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isMounted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isMounted) {
        _initializeCamera();
      }
    });
  }

  @override
  void dispose() {
    _isMounted = false;
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (_isDisposed || !_isMounted) return;
    
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    switch (state) {
      case AppLifecycleState.inactive:
        _pauseCamera();
        break;
      case AppLifecycleState.paused:
        _pauseCamera();
        break;
      case AppLifecycleState.detached:
        _disposeCamera();
        break;
      case AppLifecycleState.resumed:
        if (!_isDisposed && _isMounted) {
          _resumeCamera();
        }
        break;
      case AppLifecycleState.hidden:
        _pauseCamera();
        break;
    }
  }

  Future<void> _pauseCamera() async {
    if (_cameraController?.value.isInitialized == true && !_isProcessing) {
      try {
        await _cameraController!.pausePreview();
      } catch (e) {
        debugPrint('Error pausing camera: $e');
      }
    }
  }

  Future<void> _resumeCamera() async {
    if (_cameraController?.value.isInitialized == true && !_isProcessing) {
      try {
        await _cameraController!.resumePreview();
      } catch (e) {
        debugPrint('Error resuming camera: $e');
        _initializeCamera();
      }
    }
  }

  Future<void> _initializeCamera() async {
    if (_isDisposed || !_isMounted) return;
    
    if (_isInitialized || _isProcessing) return;
    
    setState(() {
      _error = null;
      _isInitialized = false;
    });

    try {
      final hasPermissions = await CameraService.hasPermissions();
      if (!hasPermissions) {
        final permissionsGranted = await CameraService.requestPermissions();
        if (!permissionsGranted) {
          if (_isMounted && !_isDisposed) {
            setState(() {
              _error = 'Permissions de caméra requises pour scanner';
            });
          }
          return;
        }
      }

      if (!CameraService.isAvailable) {
        if (_isMounted && !_isDisposed) {
          setState(() {
            _error = 'Aucune caméra disponible sur cet appareil';
          });
        }
        return;
      }

      if (_cameraController != null) {
        await _disposeCamera();
        await Future.delayed(const Duration(milliseconds: 100));
      }

      _cameraController = await CameraService.getCameraController();
      
      if (_cameraController != null && _isMounted && !_isDisposed) {
        _cameraController!.addListener(_onCameraError);
        
        setState(() {
          _isInitialized = true;
          _error = null;
        });
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (_isMounted && !_isDisposed) {
        setState(() {
          _error = 'Erreur d\'initialisation: ${e.toString()}';
          _isInitialized = false;
        });
      }
    }
  }

  void _onCameraError() {
    if (_cameraController != null && _cameraController!.value.hasError) {
      debugPrint('Camera error: ${_cameraController!.value.errorDescription}');
      if (_isMounted && !_isDisposed) {
        setState(() {
          _error = 'Erreur de caméra: ${_cameraController!.value.errorDescription}';
          _isInitialized = false;
        });
      }
    }
  }

  Future<void> _disposeCamera() async {
    if (_cameraController != null) {
      try {
        _cameraController!.removeListener(_onCameraError);
        
        if (_cameraController!.value.isInitialized) {
          await _cameraController!.dispose();
        }
      } catch (e) {
        debugPrint('Error disposing camera: $e');
      } finally {
        _cameraController = null;
        if (_isMounted) {
          setState(() {
            _isInitialized = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (_error != null) {
      return _buildErrorView();
    }

    if (!_isInitialized || _cameraController == null) {
      return _buildLoadingView();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: WillPopScope(
        onWillPop: () async {
          if (_isProcessing) {
            return false;
          }
          return true;
        },
        child: SafeArea(
          child: Stack(
            children: [
              // Camera preview
              _buildCameraPreview(),
              
              // Processing overlay
              if (_isProcessing) _buildProcessingOverlay(),
              
              // Scanning frame
              if (!_isProcessing) _buildScanningFrame(),
              
              // Control buttons
              if (!_isProcessing) _buildControlButtons(),
              
              // Back button
              _buildBackButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
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
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // FIXED: Add constraints to prevent overflow
                Container(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    _error ?? 'Une erreur inconnue s\'est produite',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 24),
                // FIXED: Stack buttons vertically on small screens
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 300) {
                      return Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Retour'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _initializeCamera,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Réessayer'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Row(
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
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final aspectRatio = _cameraController!.value.aspectRatio;
        
        late double scale;
        if (size.aspectRatio > aspectRatio) {
          scale = size.height / (size.width / aspectRatio);
        } else {
          scale = size.width / (size.height * aspectRatio);
        }

        return Transform.scale(
          scale: scale,
          child: Center(
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: CameraPreview(_cameraController!),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 4,
              ),
            ),
            SizedBox(height: 24),
            Text(
              "IA en cours d'analyse...",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              "Veuillez patienter",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Responsive scanning frame with better text handling
  Widget _buildScanningFrame() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final frameWidth = screenWidth * 0.8;
        final frameHeight = frameWidth * 1.2;
        
        return Center(
          child: Container(
            width: frameWidth,
            height: frameHeight,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.center_focus_strong,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 16),
                // FIXED: Add container with constraints to prevent text overflow
                Container(
                  constraints: BoxConstraints(
                    maxWidth: frameWidth - 32, // Account for padding
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Text(
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // FIXED: Responsive control buttons with proper positioning
  Widget _buildControlButtons() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // FIXED: Adjust layout based on screen width
              if (constraints.maxWidth < 400) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildControlButton(
                          icon: _flashOn ? Icons.flash_on : Icons.flash_off,
                          onPressed: _toggleFlash,
                        ),
                        _buildControlButton(
                          icon: Icons.photo_library,
                          onPressed: _selectFromGallery,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCaptureButton(),
                  ],
                );
              } else {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: _flashOn ? Icons.flash_on : Icons.flash_off,
                      onPressed: _toggleFlash,
                    ),
                    _buildCaptureButton(),
                    _buildControlButton(
                      icon: Icons.photo_library,
                      onPressed: _selectFromGallery,
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon, 
    VoidCallback? onPressed
  }) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.6),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 24),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _captureAndProcess,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          color: Colors.transparent,
        ),
        child: Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: const Icon(
              Icons.camera_alt,
              color: Colors.black,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: 0,
      left: 0,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(20),
          child: GestureDetector(
            onTap: _isProcessing ? null : () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
              ),
              child: Icon(
                Icons.close,
                color: _isProcessing ? Colors.grey : Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !CameraService.isControllerInitialized || _isProcessing) {
      return;
    }
    
    try {
      _flashOn = !_flashOn;
      await _cameraController!.setFlashMode(
        _flashOn ? FlashMode.torch : FlashMode.off,
      );
      if (_isMounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error toggling flash: $e');
      if (_isMounted) {
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
    if (_isDisposed || _isProcessing || !_isMounted) return;
    
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showErrorDialog('Caméra non initialisée');
      return;
    }
    
    setState(() => _isProcessing = true);
    
    try {
      final imagePath = await Future.any([
        CameraService.captureImage(),
        Future.delayed(const Duration(seconds: 10), () => throw TimeoutException('Capture timeout')),
      ]);
      
      if (imagePath == null) {
        throw Exception('Échec de la capture d\'image');
      }
      
      bool isValid = await _visionService.isValidVaccinationCard(imagePath);
      
      if (!isValid) {
        _showErrorDialog('Image non reconnue comme carnet de vaccination');
        return;
      }
      
      ScannedVaccinationData data = await _visionService.processVaccinationImage(imagePath);
      
      if (_isMounted && !_isDisposed) {
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
      if (_isMounted && !_isDisposed) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _selectFromGallery() async {
    if (_isDisposed || _isProcessing || !_isMounted) return;
    
    setState(() => _isProcessing = true);
    
    try {
      final imagePath = await Future.any([
        CameraService.pickImageFromGallery(),
        Future.delayed(const Duration(seconds: 30), () => throw TimeoutException('Gallery timeout')),
      ]);
      
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
      
      if (_isMounted && !_isDisposed) {
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
      if (_isMounted && !_isDisposed) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    if (!_isMounted || _isDisposed) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error),
            SizedBox(width: 8),
            Expanded( // FIXED: Prevent title overflow
              child: Text(
                'Erreur',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 300), // FIXED: Limit dialog width
          child: Text(
            message,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
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

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => 'TimeoutException: $message';
}