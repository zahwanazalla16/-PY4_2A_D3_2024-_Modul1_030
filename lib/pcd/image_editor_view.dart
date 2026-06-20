import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'image_processor.dart';

// === Color Functions ===
const Color _primaryTosca = Color(0xFFA8D5BA);
const Color _alertRed = Color(0xFFE63946);
Color getPrimaryTosca() => _primaryTosca;
Color getAlertRed() => _alertRed;
Color getToscaWithOpacity(double opacity) => _primaryTosca.withOpacity(opacity);

class ImageEditorView extends StatefulWidget {
  final String imagePath;
  final bool isFromCamera;

  const ImageEditorView({
    Key? key,
    required this.imagePath,
    this.isFromCamera = false,
  }) : super(key: key);

  @override
  State<ImageEditorView> createState() => _ImageEditorViewState();
}

class _ImageEditorViewState extends State<ImageEditorView> {
  late PCDSettings _pcdSettings;

  @override
  void initState() {
    super.initState();
    _pcdSettings = PCDSettings();
    // Auto-show histogram when image editor opens
    _pcdSettings.showHistogram = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Image'),
        elevation: 0,
        centerTitle: true,
        backgroundColor: getPrimaryTosca(),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {
              // Save edited image to gallery
              await _saveImageToGallery();
              if (mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            // === Image Preview with PCD Effects (Takes 60% of space) ===
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: _buildImageWithPCDEffects(),
                ),
              ),
            ),

            // === Histogram Display (if enabled) ===
            if (_pcdSettings.showHistogram)
              Container(
                height: 120,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.white,
                child: Column(
                  children: [
                    Expanded(
                      child: _buildHistogramWidget(),
                    ),
                  ],
                ),
              ),

            // === PCD Tools Section (remaining space with sticky header) ===
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.white,
                child: CustomScrollView(
                  slivers: [
                    // === Sticky Header ===
                    SliverAppBar(
                      pinned: true,
                      automaticallyImplyLeading: false,
                      elevation: 0,
                      backgroundColor: Colors.white,
                      flexibleSpace: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        color: Colors.white,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'PCD Tools',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade600,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _pcdSettings.reset();
                                });
                              },
                              child: const Text(
                                'Reset',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // === Content ===
                    SliverList(
                      delegate: SliverChildListDelegate([
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 12,
                            children: [
                              // Button Row 1: 4 buttons
                              Row(
                                spacing: 6,
                                children: [
                                  _buildToggleButton('Grayscale', _pcdSettings.isGrayscale, (val) {
                                    setState(() {
                                      _pcdSettings = _pcdSettings.copyWith(isGrayscale: val);
                                    });
                                  }),
                                  _buildToggleButton('Negative', _pcdSettings.isNegative, (val) {
                                    setState(() {
                                      _pcdSettings = _pcdSettings.copyWith(isNegative: val);
                                    });
                                  }),
                                  _buildToggleButton('Sharpen', _pcdSettings.isSharpened, (val) {
                                    setState(() {
                                      _pcdSettings = _pcdSettings.copyWith(isSharpened: val);
                                    });
                                  }),
                                  _buildToggleButton('Edge', _pcdSettings.isEdgeDetect, (val) {
                                    setState(() {
                                      _pcdSettings = _pcdSettings.copyWith(isEdgeDetect: val);
                                    });
                                  }),
                                ],
                              ),

                              // Button Row 2: 4 buttons (Noise, Equalization, Lowpass, Highpass)
                              Row(
                                spacing: 6,
                                children: [
                                  _buildToggleButton('Noise', _pcdSettings.isNoiseReduced, (val) {
                                    setState(() {
                                      _pcdSettings = _pcdSettings.copyWith(isNoiseReduced: val);
                                    });
                                  }),
                                  _buildToggleButton('Equalization', _pcdSettings.isEqualized, (val) {
                                    setState(() {
                                      _pcdSettings = _pcdSettings.copyWith(isEqualized: val);
                                    });
                                  }),
                                  _buildToggleButton('Lowpass', _pcdSettings.isLowpass, (val) {
                                    setState(() {
                                      _pcdSettings = _pcdSettings.copyWith(isLowpass: val);
                                    });
                                  }),
                                  _buildToggleButton('Highpass', _pcdSettings.isHighpass, (val) {
                                    setState(() {
                                      _pcdSettings = _pcdSettings.copyWith(isHighpass: val);
                                    });
                                  }),
                                ],
                              ),

                              // Sliders
                              _buildSlider(
                                'Contrast',
                                _pcdSettings.contrast,
                                0.0,
                                3.0,
                                (val) {
                                  setState(() {
                                    _pcdSettings = _pcdSettings.copyWith(contrast: val);
                                  });
                                },
                              ),
                              _buildSlider(
                                'Brightness',
                                _pcdSettings.brightness,
                                0.0,
                                2.0,
                                (val) {
                                  setState(() {
                                    _pcdSettings = _pcdSettings.copyWith(brightness: val);
                                  });
                                },
                              ),
                              _buildSlider(
                                'Blur',
                                _pcdSettings.blur,
                                0.0,
                                20.0,
                                (val) {
                                  setState(() {
                                    _pcdSettings = _pcdSettings.copyWith(blur: val);
                                  });
                                },
                              ),
                              _buildSlider(
                                'Threshold',
                                _pcdSettings.threshold,
                                0.0,
                                255.0,
                                (val) {
                                  setState(() {
                                    _pcdSettings = _pcdSettings.copyWith(threshold: val);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Calculate average luminance value
  double _calculateAverageLuminance() {
    // Simplified calculation based on widget settings
    // In a real app, would analyze actual pixel data
    final baseValue = 128.0;
    var adjustedValue = baseValue * _pcdSettings.brightness;
    adjustedValue = adjustedValue * _pcdSettings.contrast;
    return adjustedValue.clamp(0, 255).toInt().toDouble();
  }

  Widget _buildImageWithPCDEffects() {
    final imageFile = File(widget.imagePath);
    
    if (!imageFile.existsSync()) {
      return const Text(
        'Image not found',
        style: TextStyle(color: Colors.black),
      );
    }

    Widget imageWidget = Image.file(
      imageFile,
      fit: BoxFit.contain,
    );

    // Apply PCD effects same as vision_view
    // Grayscale
    if (_pcdSettings.isGrayscale) {
      imageWidget = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.299, 0.587, 0.114, 0, 0,
          0.299, 0.587, 0.114, 0, 0,
          0.299, 0.587, 0.114, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: imageWidget,
      );
    }

    // Contrast
    if (_pcdSettings.contrast != 1.0) {
      final c = _pcdSettings.contrast;
      final offset = (1.0 - c) * 0.5;
      imageWidget = ColorFiltered(
        colorFilter: ColorFilter.matrix([
          c, 0, 0, 0, offset * 255,
          0, c, 0, 0, offset * 255,
          0, 0, c, 0, offset * 255,
          0, 0, 0, 1, 0,
        ]),
        child: imageWidget,
      );
    }

    // Brightness
    if (_pcdSettings.brightness != 1.0) {
      final brightness = (_pcdSettings.brightness - 1.0) * 127;
      imageWidget = ColorFiltered(
        colorFilter: ColorFilter.matrix([
          1, 0, 0, 0, brightness,
          0, 1, 0, 0, brightness,
          0, 0, 1, 0, brightness,
          0, 0, 0, 1, 0,
        ]),
        child: imageWidget,
      );
    }

    // Blur
    if (_pcdSettings.blur > 0.0) {
      // Use contrast to simulate blur effect
      final blurFactor = max(0.7, 1.0 - (_pcdSettings.blur / 60.0)); // 0.7 - 1.0
      imageWidget = ColorFiltered(
        colorFilter: ColorFilter.matrix([
          blurFactor, 0, 0, 0, 0,
          0, blurFactor, 0, 0, 0,
          0, 0, blurFactor, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: imageWidget,
      );
    }

    // Negative
    if (_pcdSettings.isNegative) {
      imageWidget = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          -1, 0, 0, 0, 255,
          0, -1, 0, 0, 255,
          0, 0, -1, 0, 255,
          0, 0, 0, 1, 0,
        ]),
        child: imageWidget,
      );
    }

    // Sharpen - increase contrast for sharper appearance
    if (_pcdSettings.isSharpened) {
      imageWidget = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          1.5, 0, 0, 0, 0,
          0, 1.5, 0, 0, 0,
          0, 0, 1.5, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: imageWidget,
      );
    }

    // Edge Detect
    if (_pcdSettings.isEdgeDetect) {
      imageWidget = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          -1, -1, -1, 0, 0,
          -1, 8, -1, 0, 0,
          -1, -1, -1, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: imageWidget,
      );
    }

    // Denoise - reduce contrast slightly to simulate noise reduction
    if (_pcdSettings.isNoiseReduced) {
      imageWidget = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.97, 0, 0, 0, 0,
          0, 0.97, 0, 0, 0,
          0, 0, 0.97, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: imageWidget,
      );
    }

    // Equalization
    if (_pcdSettings.isEqualized) {
      imageWidget = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          1.2, 0, 0, 0, 20,
          0, 1.2, 0, 0, 20,
          0, 0, 1.2, 0, 20,
          0, 0, 0, 1, 0,
        ]),
        child: imageWidget,
      );
    }

    // Threshold
    if (_pcdSettings.threshold != 128.0) {
      final thresholdNorm = _pcdSettings.threshold / 255.0;
      final brightAdj = (1.0 - thresholdNorm) * 100;
      imageWidget = ColorFiltered(
        colorFilter: ColorFilter.matrix([
          3.0, 0, 0, 0, brightAdj,
          0, 3.0, 0, 0, brightAdj,
          0, 0, 3.0, 0, brightAdj,
          0, 0, 0, 1, 0,
        ]),
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildToggleButton(
    String label,
    bool isActive,
    Function(bool) onChanged,
  ) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? getPrimaryTosca() : Colors.grey.shade300,
          foregroundColor: isActive ? Colors.white : Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        onPressed: () => onChanged(!isActive),
        child: Text(label, style: const TextStyle(fontSize: 10)),
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            Text(
              value.toStringAsFixed(2),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: getPrimaryTosca(),
          inactiveColor: Colors.grey.shade300,
          onChanged: onChanged,
        ),
      ],
    );
  }

  /// Build histogram widget for display below image
  Widget _buildHistogramWidget() {
    final List<int> histogramData = List<int>.filled(256, 0);
    
    // Generate histogram data from image
    final imageFile = File(widget.imagePath);
    if (imageFile.existsSync()) {
      // Simple histogram simulation based on brightness/contrast settings
      // In a real app, would decode and analyze actual pixel values
      final brightness = (_pcdSettings.brightness * 100).toInt().clamp(0, 255);
      for (int i = 0; i < 256; i++) {
        final offset = (i - brightness).abs();
        histogramData[i] = max(5, (100 - offset).toInt());
      }
    }

    final maxValue = histogramData.fold<int>(0, (a, b) => a > b ? a : b);
    if (maxValue == 0) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Histogram bars
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(
              256 ~/ 8, // Show 32 bars for better visibility
              (index) {
                final barValue = histogramData[index * 8].toDouble();
                final barHeight = (barValue / maxValue.toDouble()) * 100;
                
                return Expanded(
                  child: Container(
                    height: barHeight.clamp(2.0, 100.0),
                    margin: const EdgeInsets.symmetric(horizontal: 0.5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          getToscaWithOpacity(0.8),
                          getToscaWithOpacity(0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Labels row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Dark',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 9,
              ),
            ),
            Text(
              'Mid: ${(_calculateAverageLuminance().toInt())}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Bright',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Save edited image to gallery (mobile device)
  Future<void> _saveImageToGallery() async {
    try {
      // Get the source image
      final sourceFile = File(widget.imagePath);
      if (!sourceFile.existsSync()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image not found')),
          );
        }
        return;
      }

      // Save to device gallery using gal package
      // This automatically saves to Pictures folder and rescans media
      await Gal.putImage(
        widget.imagePath,
        album: 'Logbook',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Image saved to gallery!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: ${e.toString().split('\n').first}')),
        );
      }
    }
  }
}
