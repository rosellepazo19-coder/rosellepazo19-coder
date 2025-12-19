import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../providers/app_provider.dart';
import '../models/scan_record.dart';
import '../services/classifier_service.dart';
import '../services/file_helper_stub.dart'
    if (dart.library.io) '../services/file_helper.dart' as file_helper;

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  ClassifierResult? _lastResult;
  String? _capturedImagePath;
  final ImagePicker _picker = ImagePicker();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _isInitialized = false;
        });
        return;
      }

      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _captureAndClassify() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile image = await _controller!.takePicture();
      if (kIsWeb) {
        // Web platform - read as bytes instead
        final bytes = await image.readAsBytes();
        await _processImageBytes(bytes);
      } else {
        // Non-web: use File path
        await _processImageFromPath(image.path);
      }
    } catch (e) {
      print('Error capturing image: $e');
      _showSnackBar('Error capturing image');
    }

    setState(() {
      _isProcessing = false;
    });
  }

  Future<void> _pickFromGallery() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        if (kIsWeb) {
          // Web platform - read as bytes instead
          final bytes = await image.readAsBytes();
          await _processImageBytes(bytes);
        } else {
          await _processImageFromPath(image.path);
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      _showSnackBar('Error picking image');
    }

    setState(() {
      _isProcessing = false;
    });
  }

  Future<void> _processImageFromPath(String imagePath) async {
    if (kIsWeb) {
      // Should not reach here on web
      return;
    }
    
    final provider = Provider.of<AppProvider>(context, listen: false);
    
    // On non-web, read file bytes using helper
    final imageBytes = await file_helper.FileHelper.readFileAsBytes(imagePath);
    final result = await provider.classifier.classifyBytes(imageBytes);

    if (result != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final sourceFile = file_helper.FileHelper.createFile(imagePath);
      final savedImagePath = path.join(appDir.path, fileName);
      await file_helper.FileHelper.copyFile(
        sourceFile,
        savedImagePath,
      );

      setState(() {
        _lastResult = result;
        _capturedImagePath = savedImagePath;
      });

      await provider.addRecord(ScanRecord(
        containerType: result.label,
        confidence: result.confidence,
        scanDate: DateTime.now(),
        imagePath: savedImagePath,
      ));

      if (mounted) {
        _showResultDialog(result, savedImagePath);
      }
    } else {
      _showSnackBar('Failed to classify image');
    }
  }

  Future<void> _processImageBytes(Uint8List imageBytes) async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final result = await provider.classifier.classifyBytes(imageBytes);

    if (result != null) {
      setState(() {
        _lastResult = result;
        _capturedImagePath = null; // Web doesn't save files locally
      });

      await provider.addRecord(ScanRecord(
        containerType: result.label,
        confidence: result.confidence,
        scanDate: DateTime.now(),
        imagePath: null, // Web doesn't save files locally
      ));

      if (mounted) {
        _showResultDialog(result, null);
      }
    } else {
      _showSnackBar('Failed to classify image');
    }
  }

  void _showResultDialog(ClassifierResult result, String? imagePath) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              
              // Success indicator
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getContainerColor(result.label).withOpacity(0.2),
                      _getContainerColor(result.label).withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: _getContainerColor(result.label),
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              
              const Text(
                'Container Identified! ✨',
                style: TextStyle(
                  color: Color(0xFF2D2D3A),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Saved to your records',
                style: TextStyle(
                  color: const Color(0xFF2D2D3A).withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              
              // Image preview
              if (imagePath != null && !kIsWeb)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _buildImagePreview(imagePath),
                )
              else
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _getContainerColor(result.label).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.image_outlined,
                    color: _getContainerColor(result.label),
                    size: 48,
                  ),
                ),
              const SizedBox(height: 20),
              
              // Result card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _getContainerColor(result.label).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getContainerColor(result.label).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _getContainerColor(result.label).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _getContainerIcon(result.label),
                        color: _getContainerColor(result.label),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.label,
                            style: const TextStyle(
                              color: Color(0xFF2D2D3A),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                'Confidence',
                                style: TextStyle(
                                  color: const Color(0xFF2D2D3A).withOpacity(0.5),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getContainerColor(result.label).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${(result.confidence * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: _getContainerColor(result.label),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Prediction distribution
              _buildDistributionSection(result),
                const SizedBox(height: 24),
                
                // Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE891B0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Continue Scanning',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2D2D3A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDistributionSection(ClassifierResult result) {
    final maxHeight = 320.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Prediction Distribution',
                    style: TextStyle(
                      color: Color(0xFF2D2D3A),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE891B0).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Top: ${result.label}',
                      style: const TextStyle(
                        color: Color(0xFFE891B0),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...result.distribution.map((item) {
                final percent = (item.confidence * 100).clamp(0, 100);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.label,
                              style: const TextStyle(
                                color: Color(0xFF2D2D3A),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                minHeight: 8,
                                value: percent / 100,
                                backgroundColor: Colors.grey.withOpacity(0.15),
                                valueColor: AlwaysStoppedAnimation(
                                  _getContainerColor(result.label).withOpacity(
                                    item.index == result.index ? 0.9 : 0.55,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 54,
                        child: Text(
                          '${percent.toStringAsFixed(2)}%',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: item.index == result.index
                                ? _getContainerColor(result.label)
                                : const Color(0xFF2D2D3A).withOpacity(0.65),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(String imagePath) {
    // This method is only called when !kIsWeb, so File constructor is safe
    if (kIsWeb) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.image_outlined,
          color: Colors.grey,
          size: 48,
        ),
      );
    }
    // Use file helper to create File object
    final file = file_helper.FileHelper.createFile(imagePath);
    return Image.file(
      file as dynamic,
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

  Color _getContainerColor(String type) {
    switch (type.toLowerCase()) {
      case 'aluminum can':
        return const Color(0xFF64B5F6);
      case 'coconut shell':
        return const Color(0xFF8D6E63);
      case 'glass bottle':
        return const Color(0xFF81C784);
      case 'mug':
        return const Color(0xFFFFB74D);
      case 'paper cup':
        return const Color(0xFFE57373);
      case 'plastic bottle':
        return const Color(0xFF9575CD);
      case 'thermos flask':
        return const Color(0xFF4DD0E1);
      case 'tumbler':
        return const Color(0xFFF06292);
      case 'water jug':
        return const Color(0xFF4FC3F7);
      case 'wine glass':
        return const Color(0xFFBA68C8);
      default:
        return const Color(0xFFE891B0);
    }
  }

  IconData _getContainerIcon(String type) {
    switch (type.toLowerCase()) {
      case 'aluminum can':
        return Icons.local_drink;
      case 'coconut shell':
        return Icons.eco;
      case 'glass bottle':
        return Icons.wine_bar;
      case 'mug':
        return Icons.coffee;
      case 'paper cup':
        return Icons.coffee_outlined;
      case 'plastic bottle':
        return Icons.water_drop;
      case 'thermos flask':
        return Icons.thermostat;
      case 'tumbler':
        return Icons.local_cafe;
      case 'water jug':
        return Icons.water;
      case 'wine glass':
        return Icons.wine_bar_outlined;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F9),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE891B0), Color(0xFFD4A5FF)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE891B0).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.document_scanner_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scanner',
                          style: TextStyle(
                            color: Color(0xFF2D2D3A),
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Point at a container to identify',
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Camera Preview
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE891B0).withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: _isInitialized && _controller != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            CameraPreview(_controller!),
                            // Scanning frame
                            Center(
                              child: AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _isProcessing ? 1.0 : _pulseAnimation.value,
                                    child: Container(
                                      width: 220,
                                      height: 220,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: const Color(0xFFE891B0).withOpacity(0.8),
                                          width: 3,
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          _buildCorner(Alignment.topLeft),
                                          _buildCorner(Alignment.topRight),
                                          _buildCorner(Alignment.bottomLeft),
                                          _buildCorner(Alignment.bottomRight),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Hint
                            Positioned(
                              bottom: 20,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Align container within frame',
                                    style: TextStyle(
                                      color: Color(0xFF2D2D3A),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Processing overlay
                            if (_isProcessing)
                              Container(
                                color: Colors.white.withOpacity(0.9),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE891B0).withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation(Color(0xFFE891B0)),
                                          strokeWidth: 3,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      const Text(
                                        'Analyzing...',
                                        style: TextStyle(
                                          color: Color(0xFF2D2D3A),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Identifying container type',
                                        style: TextStyle(
                                          color: const Color(0xFF2D2D3A).withOpacity(0.5),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Container(
                          color: Colors.white,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE891B0).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation(Color(0xFFE891B0)),
                                    strokeWidth: 3,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Initializing Camera...',
                                  style: TextStyle(
                                    color: Color(0xFF2D2D3A),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ),

            // Controls
            Padding(
              padding: const EdgeInsets.all(30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Gallery button
                  GestureDetector(
                    onTap: _isProcessing ? null : _pickFromGallery,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.photo_library_rounded,
                        color: const Color(0xFF2D2D3A).withOpacity(0.6),
                        size: 26,
                      ),
                    ),
                  ),

                  // Capture button
                  GestureDetector(
                    onTap: _isProcessing ? null : _captureAndClassify,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE891B0), Color(0xFFD4A5FF)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE891B0).withOpacity(0.4),
                            blurRadius: 25,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Icon(
                          _isProcessing ? Icons.hourglass_top_rounded : Icons.camera_alt_rounded,
                          color: const Color(0xFFE891B0),
                          size: 32,
                        ),
                      ),
                    ),
                  ),

                  // Placeholder
                  const SizedBox(width: 62, height: 62),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    final isTop = alignment == Alignment.topLeft || alignment == Alignment.topRight;
    final isLeft = alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;
    
    return Positioned(
      top: isTop ? -1 : null,
      bottom: !isTop ? -1 : null,
      left: isLeft ? -1 : null,
      right: !isLeft ? -1 : null,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(color: Color(0xFFE891B0), width: 4)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: Color(0xFFE891B0), width: 4)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: Color(0xFFE891B0), width: 4)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: Color(0xFFE891B0), width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
