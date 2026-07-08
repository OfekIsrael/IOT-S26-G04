import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers.dart';

class PolarPlayground extends ConsumerStatefulWidget {
  const PolarPlayground({super.key});

  @override
  ConsumerState<PolarPlayground> createState() => _PolarPlaygroundState();
}

class _PolarPlaygroundState extends ConsumerState<PolarPlayground> {
  final int numSlices = 36;
  final int numRings = 29;

  late List<List<Color?>> grid;

  // Define pure colors for exact matching
  static const Color pureRed = Color(0xFFFF0000);
  static const Color pureGreen = Color(0xFF00FF00);
  static const Color pureBlue = Color(0xFF0000FF);
  static const Color pureYellow = Color(0xFFFFFF00);
  static const Color pureCyan = Color(0xFF00FFFF);
  static const Color purePurple = Color(0xFFFF00FF);
  static const Color pureWhite = Color(0xFFFFFFFF);
  
  // New Colors
  static const Color orange = Color(0xFFFFA500);
  static const Color pink = Color(0xFFFF1493);
  static const Color lime = Color(0xFF32CD32);
  static const Color gold = Color(0xFFFFD700);
  static const Color skyBlue = Color(0xFF87CEEB);
  static const Color violet = Color(0xFF8A2BE2);

  Color? selectedColor = pureRed;
  bool isBucketMode = false;

  @override
  void initState() {
    super.initState();
    _clearGrid();
  }

  void _clearGrid() {
    setState(() {
      grid = List.generate(numSlices, (_) => List.filled(numRings, null));
    });
  }

  void _floodFill(
    int startSlice,
    int startRing,
    Color? targetColor,
    Color? replacementColor,
  ) {
    if (targetColor == replacementColor) return;

    List<math.Point<int>> queue = [math.Point(startSlice, startRing)];

    while (queue.isNotEmpty) {
      var p = queue.removeLast();
      int s = p.x;
      int r = p.y;

      if (grid[s][r] == targetColor) {
        grid[s][r] = replacementColor;
        // Check standard 4-way neighbors (with Slice wrap-around)
        if (r + 1 < numRings) queue.add(math.Point(s, r + 1));
        if (r - 1 >= 0) queue.add(math.Point(s, r - 1));
        queue.add(math.Point((s + 1) % numSlices, r));
        queue.add(math.Point((s - 1 + numSlices) % numSlices, r));
      }
    }
  }

  void _handleTouch(Offset localPosition, Size size) {
    Offset center = Offset(size.width / 2, size.height / 2);
    double maxRadius = math.min(size.width, size.height) / 2;
    double ringThickness = maxRadius / numRings;
    double sliceAngle = (2 * math.pi) / numSlices;

    double dx = localPosition.dx - center.dx;
    double dy = localPosition.dy - center.dy;

    double distance = math.sqrt(dx * dx + dy * dy);
    int ring = (distance / ringThickness).floor();

    double angle = math.atan2(dy, dx);
    if (angle < 0) angle += 2 * math.pi;
    int slice = (angle / sliceAngle).floor();

    if (ring >= 0 && ring < numRings && slice >= 0 && slice < numSlices) {
      setState(() {
        if (isBucketMode) {
          _floodFill(slice, ring, grid[slice][ring], selectedColor);
        } else {
          grid[slice][ring] = selectedColor;
        }
      });
    }
  }

  void _showColorPicker() {
    Color pickerColor = selectedColor ?? pureRed;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (Color color) {
                pickerColor = color;
              },
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false,
              displayThumbColor: true,
              paletteType: PaletteType.hsvWithHue,
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Got it'),
              onPressed: () {
                setState(() => selectedColor = pickerColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // --- SEND VIA BLUETOOTH ---
  void _sendToESP32() async {
    final bleService = ref.read(bluetoothServiceProvider);
    
    // UI feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transmitting drawing to ESP32...')),
    );

    List<List<int>> matrixData = [];
    
    for (int s = 0; s < numSlices; s++) {
      // Mirroring logic
      int mappedSlice = (numSlices - s) % numSlices;

      List<int> sliceData = [];
      // Reverse ring logic
      for (int r = 0; r < numRings; r++) {
         int reversedRing = (numRings - 1) - r;
         Color? c = grid[mappedSlice][reversedRing];
         if (c == null) {
            sliceData.addAll([0, 0, 0]);
         } else {
            int red = (c.r * 255.0).round().clamp(0, 255);
            int green = (c.g * 255.0).round().clamp(0, 255);
            int blue = (c.b * 255.0).round().clamp(0, 255);
            sliceData.addAll([red, green, blue]);
         }
      }
      matrixData.add(sliceData);
    }
    
    bool success = await bleService.sendPattern(matrixData);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Custom drawing sent!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send. Check Bluetooth.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text('POV Canvas'),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearGrid,
            tooltip: 'Clear Grid',
          ),
          // Bluetooth Send Button
          ElevatedButton.icon(
            icon: const Icon(Icons.bluetooth_connected),
            label: const Text("Send"),
            style: ElevatedButton.styleFrom(
               backgroundColor: Colors.blueAccent,
               foregroundColor: Colors.white,
            ),
            onPressed: _sendToESP32,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    Size size = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    return GestureDetector(
                      onPanUpdate: (details) =>
                          _handleTouch(details.localPosition, size),
                      onTapDown: (details) =>
                          _handleTouch(details.localPosition, size),
                      child: CustomPaint(
                        size: size,
                        painter: PolarPainter(grid, numSlices, numRings),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          _buildToolbar(),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    List<Color?> colors = [
      pureRed,
      pureGreen,
      pureBlue,
      pureYellow,
      pureCyan,
      purePurple,
      orange,
      pink,
      lime,
      gold,
      skyBlue,
      violet,
      pureWhite,
      null, // Eraser
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      color: Colors.black87,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ToggleButtons(
                isSelected: [!isBucketMode, isBucketMode],
                onPressed: (index) => setState(() => isBucketMode = index == 1),
                color: Colors.white54,
                selectedColor: Colors.white,
                fillColor: Colors.blueGrey.withOpacity(0.5),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.brush),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.format_paint),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            alignment: WrapAlignment.center,
            children: [
              ...colors.map((color) {
                bool isSelected = selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => selectedColor = color),
                  child: Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: color ?? Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.white30,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: color == null
                        ? const Icon(
                            Icons.cleaning_services,
                            color: Colors.white54,
                            size: 18,
                          )
                        : null,
                  ),
                );
              }),
              // Color Picker Wheel Button
              GestureDetector(
                onTap: _showColorPicker,
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    gradient: const SweepGradient(
                      colors: [
                        Colors.red,
                        Colors.yellow,
                        Colors.green,
                        Colors.cyan,
                        Colors.blue,
                        Colors.purple,
                        Colors.red,
                      ],
                    ),
                  ),
                  child: const Icon(Icons.colorize, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PolarPainter extends CustomPainter {
  final List<List<Color?>> grid;
  final int numSlices;
  final int numRings;

  PolarPainter(this.grid, this.numSlices, this.numRings);

  @override
  void paint(Canvas canvas, Size size) {
    Offset center = Offset(size.width / 2, size.height / 2);
    double ringThickness = (math.min(size.width, size.height) / 2) / numRings;
    double sliceAngle = (2 * math.pi) / numSlices;

    Paint strokePaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    Paint fillPaint = Paint()..style = PaintingStyle.fill;

    for (int s = 0; s < numSlices; s++) {
      for (int r = 0; r < numRings; r++) {
        if (grid[s][r] != null) {
          fillPaint.color = grid[s][r]!;
          Path segmentPath = Path()
            ..arcTo(
              Rect.fromCircle(center: center, radius: (r + 1) * ringThickness),
              s * sliceAngle,
              sliceAngle,
              false,
            )
            ..arcTo(
              Rect.fromCircle(center: center, radius: r * ringThickness),
              s * sliceAngle + sliceAngle,
              -sliceAngle,
              false,
            )
            ..close();
          canvas.drawPath(segmentPath, fillPaint);
        }
      }
    }

    for (int r = 1; r <= numRings; r++) {
      canvas.drawCircle(center, r * ringThickness, strokePaint);
    }
    for (int s = 0; s < numSlices; s++) {
      canvas.drawLine(
        center,
        Offset(
          center.dx + (numRings * ringThickness) * math.cos(s * sliceAngle),
          center.dy + (numRings * ringThickness) * math.sin(s * sliceAngle),
        ),
        strokePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PolarPainter oldDelegate) => true;
}
