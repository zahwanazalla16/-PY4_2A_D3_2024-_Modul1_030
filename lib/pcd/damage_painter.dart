import 'package:flutter/material.dart';

/// Model untuk deteksi damage (YOLO-like detection)
class DetectionBox {
  final Offset position; // center position (x, y)
  final double width;
  final double height;
  final double confidence; // 0.0 - 1.0
  final String label;

  DetectionBox({
    required this.position,
    required this.width,
    required this.height,
    required this.confidence,
    required this.label,
  });
}

class DamagePainter extends CustomPainter {
  /// List detection boxes dari YOLO (atau mock detection)
  final List<DetectionBox> detections;

  DamagePainter({this.detections = const []});

  @override
  void paint(Canvas canvas, Size size) {
    // RIGID POSITIONING: Calculate center coordinates
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Determine crosshair color based on detection state
    final crosshairColor = detections.isNotEmpty
        ? const Color(0xFFA8D5BA)  // GREEN - Detection found!
        : const Color(0xFFE63946); // RED - Searching (no object detected yet)

    // Paint untuk crosshair dan scanning area
    final scanPaint = Paint()
      ..color = const Color(0xFFA8D5BA)  // Scanning area always green/tosca
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Paint untuk crosshair line - Color changes based on detection
    final crosshairPaint = Paint()
      ..color = crosshairColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Static Anchor - Crosshair di tengah
    final crosshairLength = 40.0; // Panjang garis crosshair

    // Garis vertikal (tengah)
    canvas.drawLine(
      Offset(centerX, centerY - crosshairLength),
      Offset(centerX, centerY + crosshairLength),
      crosshairPaint,
    );

    // Garis horizontal (tengah)
    canvas.drawLine(
      Offset(centerX - crosshairLength, centerY),
      Offset(centerX + crosshairLength, centerY),
      crosshairPaint,
    );

    // Lingkaran kecil di center (target point) - Changes color with detection
    canvas.drawCircle(
      Offset(centerX, centerY),
      4.0,
      Paint()
        ..color = crosshairColor
        ..style = PaintingStyle.fill,
    );

    // Scanning Area Indicator (Square) ===
    // Ukuran scanning area adalah 40% dari canvas width (rigid calculation)
    final scanningAreaSize = size.width * 0.4;
    final scanningAreaRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: scanningAreaSize,
      height: scanningAreaSize,
    );

    canvas.drawRect(scanningAreaRect, scanPaint);

    // Corner accents (hiasan sudut-sudut area pemindaian)
    final cornerLength = 15.0;
    final cornerStroke = 2.5;
    final cornerPaint = Paint()
      ..color = const Color(0xFFA8D5BA)
      ..strokeWidth = cornerStroke
      ..style = PaintingStyle.stroke;

    // Top-left corner
    canvas.drawLine(
      Offset(scanningAreaRect.left, scanningAreaRect.top),
      Offset(scanningAreaRect.left + cornerLength, scanningAreaRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanningAreaRect.left, scanningAreaRect.top),
      Offset(scanningAreaRect.left, scanningAreaRect.top + cornerLength),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(scanningAreaRect.right, scanningAreaRect.top),
      Offset(scanningAreaRect.right - cornerLength, scanningAreaRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanningAreaRect.right, scanningAreaRect.top),
      Offset(scanningAreaRect.right, scanningAreaRect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(scanningAreaRect.left, scanningAreaRect.bottom),
      Offset(scanningAreaRect.left + cornerLength, scanningAreaRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanningAreaRect.left, scanningAreaRect.bottom),
      Offset(scanningAreaRect.left, scanningAreaRect.bottom - cornerLength),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(scanningAreaRect.right, scanningAreaRect.bottom),
      Offset(scanningAreaRect.right - cornerLength, scanningAreaRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanningAreaRect.right, scanningAreaRect.bottom),
      Offset(scanningAreaRect.right, scanningAreaRect.bottom - cornerLength),
      cornerPaint,
    );

    // Vision Label dengan TextPainter
    // Text label "Searching for Road Damage..."
    const labelText = 'Searching for Road Damage...';
    final textPainter = TextPainter(
      text: const TextSpan(
        text: labelText,
        style: TextStyle(
          color: Color(0xFFA8D5BA),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Rigid Positioning
    // Posisi text di atas scanning area, di tengah
    final textOffsetX = centerX - (textPainter.width / 2);
    final textOffsetY = scanningAreaRect.top - 30; // 30px di atas scanning area

    textPainter.paint(
      canvas,
      Offset(textOffsetX, textOffsetY),
    );

    // Mock Detection Logic - RENDER Detection Boxes
    // Render semua YOLO detections yang di-generate
    if (detections.isNotEmpty) {
      for (final detection in detections) {
        _drawDetectionBox(canvas, detection, size);
      }
    }
  }

  /// Draw individual detection box dengan scaling calibration
  void _drawDetectionBox(Canvas canvas, DetectionBox box, Size size) {
    // === TASK 2: Scaling Calibration ===
    // Box width/height proporsional terhadap canvas width
    final scaledWidth = box.width;
    final scaledHeight = box.height;

    // Calculate box rectangle dari center position
    final detectionRect = Rect.fromCenter(
      center: box.position,
      width: scaledWidth,
      height: scaledHeight,
    );

    // Detection Style & Color Branding
    // Get color based on damage type (severity/category)
    final boxColor = _getDamageColor(box.label);

    // Paint untuk detection box border
    final detectionPaint = Paint()
      ..color = boxColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Draw box rectangle
    canvas.drawRect(detectionRect, detectionPaint);

    // Draw confidence badge di top-left corner
    final confidenceText = '${(box.confidence * 100).toStringAsFixed(0)}%';
    
    // Text Shadow untuk Readability ===
    _drawTextWithShadow(
      canvas,
      confidenceText,
      Offset(detectionRect.left + 4, detectionRect.top - 22),
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );

    // Draw label di bottom-left corner dengan shadow
    if (box.label.isNotEmpty) {
      _drawTextWithShadow(
        canvas,
        box.label,
        Offset(detectionRect.left + 4, detectionRect.bottom + 2),
        fontSize: 11,
        fontWeight: FontWeight.w600,
      );
    }
  }

  /// Dynamic Color Branding berdasar Damage Type
  Color _getDamageColor(String label) {
    // RDD-2022 damage classification dengan color mapping
    if (label.contains('D03') || label.contains('Potholes')) {
      // Pothole (Heavy) → RED
      return const Color(0xFFE63946); // Merah (heavy damage)
    } else if (label.contains('D02') || label.contains('Patches')) {
      // Patches (Medium) → ORANGE
      return const Color(0xFFFB5607); // Orange (medium damage)
    } else if (label.contains('D01') || label.contains('Cracks')) {
      // Cracks (Light) → YELLOW
      return const Color(0xFFFFBE0B); // Kuning (light damage)
    } else {
      // Default → TOSCA
      return const Color(0xFFA8D5BA);
    }
  }

  /// Draw text dengan shadow untuk readability 
  void _drawTextWithShadow(
    Canvas canvas,
    String text,
    Offset position, {
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    // Shadow layer (offset, dark color)
    final shadowPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.black.withOpacity(0.7), // Dark shadow
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    shadowPainter.layout();
    
    // Draw shadow dengan offset
    shadowPainter.paint(canvas, position + const Offset(1, 1));
    
    // Main text layer (white text)
    final mainPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    mainPainter.layout();
    
    // Draw main text
    mainPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(DamagePainter oldDelegate) {
    // Repaint ketika detection list berubah
    return detections.length != oldDelegate.detections.length ||
        detections != oldDelegate.detections;
  }
}