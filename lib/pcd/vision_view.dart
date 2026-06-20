import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'vision_controller.dart';
import 'damage_painter.dart';
import 'image_processor.dart';
import 'image_editor_view.dart';

/// ===== COLOR PALETTE FUNCTIONS =====
const Color _primaryTosca = Color(0xFFA8D5BA);
const Color _alertRed = Color(0xFFE63946);

Color getPrimaryTosca() => _primaryTosca;
Color getAlertRed() => _alertRed;
Color getToscaWithOpacity(double opacity) => _primaryTosca.withOpacity(opacity);

class VisionView extends StatefulWidget {
  const VisionView({Key? key}) : super(key: key);

  @override
  State<VisionView> createState() => _VisionViewState();
}

class _VisionViewState extends State<VisionView> {
  late VisionController _visionController;
  late Timer _mockDetectionTimer;
  final List<DetectionBox> _detections = [];
  final Random _random = Random();
  
  // === UI State Management ===
  bool _isOverlayEnabled = true;
  late PCDSettings _pcdSettings;
  
  // === Detection State Management ===
  bool _hasDetectedObjects = false;  // TRUE = ada object terdeteksi (GREEN), FALSE = searching (RED)

  @override
  void initState() {
    super.initState();
    _visionController = VisionController();
    _pcdSettings = PCDSettings();
    
    // Continuous detection - Every 800ms attempt to detect objects
    // Detections PERSIST while object is same, clear when object changes
    _mockDetectionTimer = Timer.periodic(
      const Duration(milliseconds: 800),
      (_) => _generateMockDetection(),
    );
  }

  @override
  void dispose() {
    // Resource Guard - Auto-Dispose on Back Button
    _mockDetectionTimer.cancel();  // Stop detection timer
    _visionController.dispose();    // Dispose camera controller
    super.dispose();
  }

  /// Generate detection boxes dengan smart persistence
  /// Logic:
  /// - Jika sudah ada detection: 90% persist (keep), 10% clear/change object
  /// - Jika tidak ada detection: 30% generate initial
  void _generateMockDetection() {
    if (!mounted) return;

    final screenSize = MediaQuery.of(context).size;
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;
    final scanningAreaSize = screenSize.width * 0.4;

    setState(() {
      // === Ada detections existing - SMART PERSISTENCE ===
      if (_detections.isNotEmpty) {
        // 70% chance untuk tetap persist (keep detections)
        if (_random.nextDouble() < 0.7) {
          _hasDetectedObjects = true;  // GREEN - object masih terdeteksi
          return;  // Keep existing detections, jangan regenerate
        } else {
          // 30% chance untuk clear atau change object
          // Ini buat object bisa berganti tipe atau disappear segera
          if (_random.nextDouble() < 0.5) {
            // 50% clear detections (searching mode)
            _detections.clear();
            _hasDetectedObjects = false;
          } else {
            // 50% change detection (object type changes)
            _detections.clear();
            // Fall through to regenerate new detection below
          }
        }
      }

      // === Tidak ada detections - Normal detection attempt ===
      if (_detections.isEmpty) {
        // 30% chance untuk detect object = generate 1-3 boxes
        if (_random.nextDouble() < 0.3) {
          final numDetections = 1 + _random.nextInt(3);  // 1-3 boxes

          for (int i = 0; i < numDetections; i++) {
            // Random position within scanning area
            final offsetX =
                (_random.nextDouble() - 0.5) * scanningAreaSize * 0.6;
            final offsetY =
                (_random.nextDouble() - 0.5) * scanningAreaSize * 0.6;

            final detectionX = centerX + offsetX;
            final detectionY = centerY + offsetY;

            // Box size
            final boxWidth =
                screenSize.width * (0.12 + _random.nextDouble() * 0.08);
            final boxHeight =
                screenSize.height * (0.10 + _random.nextDouble() * 0.06);

            // High confidence for detected objects
            final confidence = 0.75 + _random.nextDouble() * 0.25;

            const damageLabels = ['D01-Cracks', 'D02-Patches', 'D03-Potholes'];
            final label = damageLabels[_random.nextInt(damageLabels.length)];

            _detections.add(DetectionBox(
              position: Offset(detectionX, detectionY),
              width: boxWidth,
              height: boxHeight,
              confidence: confidence,
              label: label,
            ));
          }

          _hasDetectedObjects = true;  // GREEN crosshair
        } else {
          // === SEARCHING State: No detection this cycle ===
          _hasDetectedObjects = false;  // RED crosshair
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vision Preview'),
        elevation: 0,
        centerTitle: false,
        backgroundColor: getPrimaryTosca(),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Overlay Toggle Button
          IconButton(
            icon: Icon(
              _isOverlayEnabled ? Icons.visibility : Icons.visibility_off,
            ),
            color: Colors.white,
            onPressed: () {
              setState(() {
                _isOverlayEnabled = !_isOverlayEnabled;
              });
            },
          ),
          // Flash Toggle Button
          IconButton(
            icon: Icon(
              _visionController.isFlashOn ? Icons.flash_on : Icons.flash_off,
            ),
            color: _visionController.isFlashOn ? Colors.amber : Colors.white,
            onPressed: () async {
              await _visionController.toggleFlash();
              setState(() {});
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _visionController,
        builder: (context, child) {
          // === TASK 2: Better Error Handling ===
          if (_visionController.errorMessage != null) {
            return _buildErrorState(context);
          }

          // === TASK 2: Better Loading State ===
          if (!_visionController.isInitialized) {
            return _buildLoadingState();
          }

          return _buildVisionStack();
        },
      ),
    );
  }

  /// === TASK 2: Informative Vision State - Loading dengan custom text ===
  Widget _buildLoadingState() {
    return Container(
      color: Colors.grey.shade50,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Custom loading indicator dengan animasi
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFFA8D5BA).withOpacity(0.6),
                    ),
                    strokeWidth: 3,
                  ),
                ),
                const Icon(
                  Icons.camera_alt,
                  size: 40,
                  color: Color(0xFFA8D5BA),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Instructional text
            const Text(
              'Menghubungkan ke Sensor Visual...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFA8D5BA),
              ),
            ),
            const SizedBox(height: 8),
            
            const Text(
              'Inisialisasi kamera dalam proses',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// === TASK 2: Informative Vision State - Error dengan Open Settings ===
  Widget _buildErrorState(BuildContext context) {
    return Container(
      color: Colors.grey.shade50,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.videocam_off,
                  size: 40,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 24),
              
              // Error title
              const Text(
                'Akses Kamera Ditolak',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              
              // Error message
              Text(
                _visionController.errorMessage ?? 'Kamera tidak tersedia',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              
              Text(
                'Pastikan aplikasi memiliki izin akses ke kamera Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA8D5BA),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      // === TASK 2: Open Settings ===
                      openAppSettings();
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Buka Pengaturan'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Kembali'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisionStack() {
    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            // === MAIN: Large Camera Preview (Full Width) ===
            Column(
              children: [
                // Header Info Bar (minimal) - White Background
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: getPrimaryTosca(),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _hasDetectedObjects
                              ? 'Damage Detected!'
                              : 'Searching for Road Damage...',
                          style: TextStyle(
                            color: _hasDetectedObjects
                                ? Colors.green
                                : Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        _hasDetectedObjects ? '✓ Found' : '⊘ Scanning',
                        style: TextStyle(
                          color: _hasDetectedObjects
                              ? Colors.green
                              : Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // === Expanded Camera Preview (No boxes, just full size) ===
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFA8D5BA),
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // === Camera Feed with PCD Effects Applied ===
                        _buildCameraWithPCDEffects(),

                        // Scanning area + crosshair + detection boxes (CONDITIONAL on _isOverlayEnabled)
                        if (_isOverlayEnabled)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: DamagePainter(detections: _detections),
                            ),
                          ),

                        // === Histogram Display (Top Right) ===
                        if (_pcdSettings.showHistogram)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: _buildHistogramWidget(),
                          ),
                      ],
                    ),
                  ),
                ),

                // Bottom Control Bar - White Background
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 12,
                    children: [
                      // Upload Image Button
                      SizedBox(
                        height: 44,
                        width: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            await _pickImageFromGallery();
                          },
                          child: const Icon(Icons.image, size: 24),
                        ),
                      ),

                      // Take Photo Button (main action)
                      SizedBox(
                        height: 56,
                        width: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            await _takePhoto();
                          },
                          child: const Icon(Icons.camera_alt, size: 28),
                        ),
                      ),

                      // PCD Tools Button
                      SizedBox(
                        height: 44,
                        width: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: getPrimaryTosca(),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => _showPCDToolsModal(context),
                          child: const Icon(Icons.tune, size: 24),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),


          ],
        ),
      ),
    );
  }

  /// PCD Tools Modal Bottom Sheet
  void _showPCDToolsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 12,
                  children: [
                    // === Header with Reset ===
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PCD Tools',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          onPressed: () {
                            setModalState(() {
                              _pcdSettings.reset();
                            });
                            setState(() {});
                          },
                          child: const Text(
                            'Reset',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Divider(color: Colors.grey),

                    // === Button Row 1: 4 buttons (Grayscale, Negative, Sharpen, Edge) ===
                    Row(
                      spacing: 8,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _pcdSettings.isGrayscale
                                  ? getPrimaryTosca()
                                  : Colors.grey.shade400,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              setModalState(() {
                                _pcdSettings = _pcdSettings.copyWith(
                                  isGrayscale: !_pcdSettings.isGrayscale,
                                );
                              });
                            },
                            child: const Text('Grayscale', style: TextStyle(fontSize: 10)),
                          ),
                        ),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _pcdSettings.isNegative
                                  ? getPrimaryTosca()
                                  : Colors.grey.shade400,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              setModalState(() {
                                _pcdSettings = _pcdSettings.copyWith(
                                  isNegative: !_pcdSettings.isNegative,
                                );
                              });
                              setState(() {});
                            },
                            child: const Text('Negative', style: TextStyle(fontSize: 10)),
                          ),
                        ),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _pcdSettings.isSharpened
                                  ? getPrimaryTosca() 
                                  : Colors.grey.shade400,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              setModalState(() {
                                _pcdSettings = _pcdSettings.copyWith(
                                  isSharpened: !_pcdSettings.isSharpened,
                                );
                              });
                              setState(() {});
                            },
                            child: const Text('Sharpen', style: TextStyle(fontSize: 10)),
                          ),
                        ),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _pcdSettings.isEdgeDetect
                                  ? getPrimaryTosca()
                                  : Colors.grey.shade400,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              setModalState(() {
                                _pcdSettings = _pcdSettings.copyWith(
                                  isEdgeDetect: !_pcdSettings.isEdgeDetect,
                                );
                              });
                              setState(() {});
                            },
                            child: const Text('Edge', style: TextStyle(fontSize: 10)),
                          ),
                        ),
                      ],
                    ),

                    // === Button Row 2: 4 buttons (Noise, Equalization, Lowpass, Highpass) ===
                    Row(
                      spacing: 8,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _pcdSettings.isNoiseReduced
                                  ? getPrimaryTosca()
                                  : Colors.grey.shade400,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              setModalState(() {
                                _pcdSettings = _pcdSettings.copyWith(
                                  isNoiseReduced: !_pcdSettings.isNoiseReduced,
                                );
                              });
                              setState(() {});
                            },
                            child: const Text('Noise', style: TextStyle(fontSize: 10)),
                          ),
                        ),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _pcdSettings.isEqualized
                                  ? getPrimaryTosca()
                                  : Colors.grey.shade400,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              setModalState(() {
                                _pcdSettings = _pcdSettings.copyWith(
                                  isEqualized: !_pcdSettings.isEqualized,
                                );
                              });
                              setState(() {});
                            },
                            child: const Text('Equalization', style: TextStyle(fontSize: 10)),
                          ),
                        ),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _pcdSettings.isLowpass
                                  ? getPrimaryTosca()
                                  : Colors.grey.shade400,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              setModalState(() {
                                _pcdSettings = _pcdSettings.copyWith(
                                  isLowpass: !_pcdSettings.isLowpass,
                                );
                              });
                              setState(() {});
                            },
                            child: const Text('Lowpass', style: TextStyle(fontSize: 10)),
                          ),
                        ),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _pcdSettings.isHighpass
                                  ? getPrimaryTosca()
                                  : Colors.grey.shade400,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              setModalState(() {
                                _pcdSettings = _pcdSettings.copyWith(
                                  isHighpass: !_pcdSettings.isHighpass,
                                );
                              });
                              setState(() {});
                            },
                            child: const Text('Highpass', style: TextStyle(fontSize: 10)),
                          ),
                        ),
                      ],
                    ),



                    const Divider(color: Colors.grey),

                    // === Histogram Widget (Bottom of PCD Tools) ===
                    if (_pcdSettings.showHistogram) ...[
                      SizedBox(
                        height: 120,
                        child: _buildHistogramWidget(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // === Sliders ===
                    // Contrast
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Contrast',
                                style: TextStyle(
                                    color: Colors.black, fontWeight: FontWeight.w500)),
                            Text(_pcdSettings.contrast.toStringAsFixed(2),
                                style: const TextStyle(
                                    color: Colors.black, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Slider(
                          value: _pcdSettings.contrast,
                          min: 0.0,
                          max: 3.0,
                          activeColor: getPrimaryTosca(),
                          inactiveColor: Colors.grey.shade300,
                          onChanged: (value) {
                            setModalState(() {
                              _pcdSettings = _pcdSettings.copyWith(contrast: value);
                            });
                            setState(() {});
                          },
                        ),
                      ],
                    ),

                    // Brightness
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Brightness',
                                style: TextStyle(
                                    color: Colors.black, fontWeight: FontWeight.w500)),
                            Text(_pcdSettings.brightness.toStringAsFixed(2),
                                style: const TextStyle(
                                    color: Colors.black, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Slider(
                          value: _pcdSettings.brightness,
                          min: 0.0,
                          max: 2.0,
                          activeColor: getPrimaryTosca(),
                          inactiveColor: Colors.grey.shade300,
                          onChanged: (value) {
                            setModalState(() {
                              _pcdSettings = _pcdSettings.copyWith(brightness: value);
                            });
                            setState(() {});
                          },
                        ),
                      ],
                    ),

                    // Blur
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Convolution Blur',
                                style: TextStyle(
                                    color: Colors.black, fontWeight: FontWeight.w500)),
                            Text(_pcdSettings.blur.toStringAsFixed(2),
                                style: const TextStyle(
                                    color: Colors.black, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Slider(
                          value: _pcdSettings.blur,
                          min: 0.0,
                          max: 20.0,
                          activeColor: getPrimaryTosca(),
                          inactiveColor: Colors.grey.shade300,
                          onChanged: (value) {
                            setModalState(() {
                              _pcdSettings = _pcdSettings.copyWith(blur: value);
                            });
                            setState(() {});
                          },
                        ),
                      ],
                    ),

                    // Threshold
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Threshold',
                                style: TextStyle(
                                    color: Colors.black, fontWeight: FontWeight.w500)),
                            Text(_pcdSettings.threshold.toStringAsFixed(0),
                                style: const TextStyle(
                                    color: Colors.black, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Slider(
                          value: _pcdSettings.threshold,
                          min: 0.0,
                          max: 255.0,
                          activeColor: getPrimaryTosca(),
                          inactiveColor: Colors.grey.shade300,
                          onChanged: (value) {
                            setModalState(() {
                              _pcdSettings = _pcdSettings.copyWith(threshold: value);
                            });
                            setState(() {});
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Build camera preview with PCD effects applied
  Widget _buildCameraWithPCDEffects() {
    Widget cameraWidget = CameraPreview(_visionController.controller!);

    // === Apply Grayscale Effect ===
    if (_pcdSettings.isGrayscale) {
      cameraWidget = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.299, 0.587, 0.114, 0, 0,
          0.299, 0.587, 0.114, 0, 0,
          0.299, 0.587, 0.114, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: cameraWidget,
      );
    }

    // === Apply Contrast Effect ===
    if (_pcdSettings.contrast != 1.0) {
      // Contrast matrix: scale RGB around 0.5 (middle gray)
      final c = _pcdSettings.contrast;
      final offset = (1.0 - c) * 0.5;
      
      cameraWidget = ColorFiltered(
        colorFilter: ColorFilter.matrix([
          c, 0, 0, 0, offset * 255,
          0, c, 0, 0, offset * 255,
          0, 0, c, 0, offset * 255,
          0, 0, 0, 1, 0,
        ]),
        child: cameraWidget,
      );
    }

    // === Apply Brightness Effect ===
    if (_pcdSettings.brightness != 1.0) {
      // Brightness: 0.0 = black, 1.0 = original, 2.0 = very bright
      final brightness = (_pcdSettings.brightness - 1.0) * 127;
      
      cameraWidget = ColorFiltered(
        colorFilter: ColorFilter.matrix([
          1, 0, 0, 0, brightness,
          0, 1, 0, 0, brightness,
          0, 0, 1, 0, brightness,
          0, 0, 0, 1, 0,
        ]),
        child: cameraWidget,
      );
    }

    // === Apply Blur Effect ===
    // Blur makes image smooth, soft, less sharp
    if (_pcdSettings.blur > 0.0) {
      // Blur ranges 0-20, convert to proper sigma value (0-15)
      // Higher blur value = stronger blur effect
      final sigma = (_pcdSettings.blur / 20.0) * 25.0;  // 0 to 25 sigma
      
      cameraWidget = BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: sigma,
          sigmaY: sigma,
        ),
        child: Container(
          color: Colors.transparent,
          child: cameraWidget,
        ),
      );
    }

    // === Apply Negative (Invert) Effect ===
    if (_pcdSettings.isNegative) {
      cameraWidget = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          -1, 0, 0, 0, 255,
          0, -1, 0, 0, 255,
          0, 0, -1, 0, 255,
          0, 0, 0, 1, 0,
        ]),
        child: cameraWidget,
      );
    }

    // === Apply Sharpen Effect ===
    // Sharpen makes edges more prominent, increases local contrast
    // Reference: Canyon image with strong edge contrast
    if (_pcdSettings.isSharpened) {
      // Unsharp mask approximation: high-pass filter + boost dengan kekuatan lebih besar
      cameraWidget = ColorFiltered(
        colorFilter: ColorFilter.matrix([
          3.0, 0, 0, 0, -150,     // Strong sharpening: 3.0x contrast boost
          0, 3.0, 0, 0, -150,
          0, 0, 3.0, 0, -150,
          0, 0, 0, 1, 0,
        ]),
        child: cameraWidget,
      );
    }

    // === Apply Edge Detection (High-Pass Filter via Contrast + Negative Offset) ===
    // Edge detection emphasizes boundaries - implemented as high-pass filter using extreme contrast
    // Similar to Laplacian/Sobel by detecting areas where pixel values change sharply
    if (_pcdSettings.isEdgeDetect) {
      cameraWidget = ColorFiltered(
        colorFilter: ColorFilter.matrix([
          4.0, 0, 0, 0, -256,  // 4x contrast with strong negative offset
          0, 4.0, 0, 0, -256,  // Brings mid-tones to black, emphasizes edges
          0, 0, 4.0, 0, -256,  // Creates high-pass filter effect: light edges on dark background
          0, 0, 0, 1, 0,
        ]),
        child: cameraWidget,
      );
    }

    // === Apply Noise/Denoise Control ===
    // Slider value: 0-128
    // 0-64 (left) = sharpen & enhance grain (noise visualization)
    // 64-128 (right) = reduce noise (smooth/blur)
    // Reference: Grain texture like image 4
    if (_pcdSettings.isNoiseReduced && _pcdSettings.threshold != 128.0) {  // Only apply if Noise button is active
      final noiseControl = _pcdSettings.threshold;
      
      if (noiseControl < 64) {
        // LEFT SIDE: Sharpen noise (enhance grain details)
        final sharpAmount = (64 - noiseControl) / 64.0;  // 0 to 1
        cameraWidget = ColorFiltered(
          colorFilter: ColorFilter.matrix([
            1.0 + (sharpAmount * 2.0), 0, 0, 0, -(sharpAmount * 80),  // Increased sharpening for more grain
            0, 1.0 + (sharpAmount * 2.0), 0, 0, -(sharpAmount * 80),
            0, 0, 1.0 + (sharpAmount * 2.0), 0, -(sharpAmount * 80),
            0, 0, 0, 1, 0,
          ]),
          child: cameraWidget,
        );
      } else if (noiseControl > 64) {
        // RIGHT SIDE: Denoise (reduce noise)
        final denoiseAmount = (noiseControl - 64) / 64.0;  // 0 to 1
        final denoiseSigma = denoiseAmount * 15.0;  // 0 to 15 sigma
        
        cameraWidget = BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: denoiseSigma, sigmaY: denoiseSigma),
          child: Container(color: Colors.transparent, child: cameraWidget),
        );
      }
    }

    // === Apply Histogram Equalization (brightness boost approximation) ===
    if (_pcdSettings.isEqualized) {
      // Histogram equalization approximation: increase saturation and contrast
      cameraWidget = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          1.2, 0, 0, 0, 20,
          0, 1.2, 0, 0, 20,
          0, 0, 1.2, 0, 20,
          0, 0, 0, 1, 0,
        ]),
        child: cameraWidget,
      );
    }

    // === Apply Threshold (Binary Binarization) ===
    // Threshold creates pure black & white based on threshold value
    // Reference: Pure black/white like image 3
    if (_pcdSettings.threshold != 128.0) {
      // Extreme contrast creates threshold effect - values become pure black or white
      final thresholdNorm = _pcdSettings.threshold / 255.0;
      final brightAdj = (0.5 - thresholdNorm) * 512;  // Offset untuk push ke black/white
      
      cameraWidget = ColorFiltered(
        colorFilter: ColorFilter.matrix([
          10.0, 0, 0, 0, brightAdj,  // Extreme contrast (10x) untuk binary effect
          0, 10.0, 0, 0, brightAdj,
          0, 0, 10.0, 0, brightAdj,
          0, 0, 0, 1, 0,
        ]),
        child: cameraWidget,
      );
    }

    // === Apply Lowpass Filter (Smoothing) ===
    // Lowpass removes high-frequency noise, creates smooth blurring effect
    if (_pcdSettings.isLowpass) {
      // Lowpass is a strong blur that smooths out details
      const double lowpassSigma = 8.0;  // Moderate to strong smoothing
      
      cameraWidget = BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: lowpassSigma,
          sigmaY: lowpassSigma,
        ),
        child: Container(
          color: Colors.transparent,
          child: cameraWidget,
        ),
      );
    }

    // === Apply Highpass Filter (Edge Enhancement) ===
    // Highpass enhances edges and details by removing smooth areas
    if (_pcdSettings.isHighpass) {
      // Highpass approximation: boost contrast and sharpen
      cameraWidget = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          2.0, 0, 0, 0, -128,    // High-pass: boost edges, remove smooth gradients
          0, 2.0, 0, 0, -128,
          0, 0, 2.0, 0, -128,
          0, 0, 0, 1, 0,
        ]),
        child: cameraWidget,
      );
    }

    return cameraWidget;
  }

  /// Calculate histogram and color based on current detections
  Map<String, dynamic> _calculateHistogramForDetections() {
    final List<int> histogramData = List.filled(256, 0);
    int totalLuminance = 0;

    if (_detections.isEmpty) {
      // No detection - flat histogram
      for (int i = 0; i < 256; i++) {
        histogramData[i] = 50;  // Flat baseline
      }
      totalLuminance = 128 * 256 * 50;
    } else {
      // Has detection - create histogram based on damage type distribution
      for (final detection in _detections) {
        // Different distribution based on damage type
        if (detection.label.contains('D01')) {
          // Cracks - high contrast, peaks at darker values
          for (int i = 0; i < 256; i++) {
            histogramData[i] = (80 * (1 - (i / 256).abs())).toInt();
          }
        } else if (detection.label.contains('D02')) {
          // Patches - medium brightness
          for (int i = 80; i < 200; i++) {
            histogramData[i] = (100 * (1 - ((i - 140).abs() / 120))).toInt().clamp(0, 100);
          }
        } else if (detection.label.contains('D03')) {
          // Potholes - wide range, high entropy
          for (int i = 0; i < 256; i++) {
            histogramData[i] = (70 + (i % 50)).toInt();
          }
        }
      }
      
      // Calculate average luminance
      for (int i = 0; i < 256; i++) {
        totalLuminance += i * histogramData[i];
      }
    }

    final avgLuminance = (totalLuminance ~/ (histogramData.fold(1, (a, b) => a + b))).clamp(0, 255);

    // Determine bar color based on primary detection type
    Color barColor = Colors.amber;  // Default
    if (_detections.isNotEmpty) {
      final primaryLabel = _detections.first.label;
      if (primaryLabel.contains('D01')) {
        barColor = const Color(0xFFFFBE0B);  // Yellow for Cracks
      } else if (primaryLabel.contains('D02')) {
        barColor = const Color(0xFFFB5607);  // Orange for Patches
      } else if (primaryLabel.contains('D03')) {
        barColor = const Color(0xFFE63946);  // Red for Potholes
      }
    }

    return {
      'data': histogramData,
      'average': avgLuminance,
      'color': barColor,
    };
  }

  /// Build histogram visualization widget (top-right corner)
  Widget _buildHistogramWidget() {
    final histData = _calculateHistogramForDetections();
    final List<int> histogramData = histData['data'];
    final int avgLuminance = histData['average'];
    final Color barColor = histData['color'];

    // Find max value for scaling
    final maxValue = histogramData.fold<int>(0, (a, b) => a > b ? a : b);
    final scale = maxValue > 0 ? 60.0 / maxValue : 1.0;

    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black87,
        border: Border.all(color: barColor, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with Luma value
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Histogram',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Luma: ${avgLuminance.toStringAsFixed(1)}',
                style: TextStyle(
                  color: barColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Histogram bars (more detailed: show every 5th value)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (int i = 0; i < 256; i += 10)
                Container(
                  width: 5,
                  height: (histogramData[i] * scale).clamp(0, 60),
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Take photo from camera and navigate to Image Editor
  Future<void> _takePhoto() async {
    try {
      if (_visionController.controller == null || !_visionController.controller!.value.isInitialized) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera not ready')),
        );
        return;
      }

      // Capture image
      final XFile image = await _visionController.controller!.takePicture();
      
      if (!mounted) return;
      
      // Navigate to Image Editor
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageEditorView(
            imagePath: image.path,
            isFromCamera: true,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e')),
      );
    }
  }

  /// Pick image from gallery and navigate to Image Editor
  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null) return;

      if (!mounted) return;

      // Navigate to Image Editor
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageEditorView(
            imagePath: image.path,
            isFromCamera: false,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }
}

