import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers.dart';
import '../patterns.dart';
import '../config.dart';

class RpmScreen extends ConsumerStatefulWidget {
  const RpmScreen({super.key});

  @override
  ConsumerState<RpmScreen> createState() => _RpmScreenState();
}

class _RpmScreenState extends ConsumerState<RpmScreen> {
  Timer? _timer;
  bool _isSending = false;
  Color _selectedColor = Colors.orangeAccent;
  int _lastSentRpm = -1;

  void _showColorPicker() {
    Color pickerColor = _selectedColor;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick RPM color'),
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
                setState(() => _selectedColor = pickerColor);
                Navigator.of(context).pop();
                _lastSentRpm = -1; // Force resend on color change
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // Start a fast timer to check if RPM changed and we need to push a new frame
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        _checkAndSendRpm();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkAndSendRpm() async {
    if (_isSending) return;
    
    final bleService = ref.read(bluetoothServiceProvider);
    if (bleService.connectedDevice == null) return;

    int currentRpm = bleService.rpmNotifier.value;
    
    // Only send if the RPM changed significantly (by at least 10 RPM) or we forced a resend
    if ((currentRpm - _lastSentRpm).abs() < 10 && _lastSentRpm != -1) return;

    _isSending = true;
    try {
      int r = (_selectedColor.r * 255.0).round().clamp(0, 255);
      int g = (_selectedColor.g * 255.0).round().clamp(0, 255);
      int b = (_selectedColor.b * 255.0).round().clamp(0, 255);
      
      // We have 9 chars max. "1450 RPM" is exactly 8 chars. Fits perfectly.
      String rpmText = "$currentRpm RPM";
      if (rpmText.length > 9) {
        rpmText = currentRpm.toString(); // Fallback if rpm gets insane
      }

      // Calculate start slice dynamically so the space lands at the hardware gap.
      // Gap is physically at the last slice.
      int rpmDigits = currentRpm.toString().length;
      int startSlice = ((PovConfig.numSlices - 1) - rpmDigits * 4) % PovConfig.numSlices;
      if (startSlice < 0) startSlice += PovConfig.numSlices;

      final matrix = PredefinedPatterns.getTextPattern(rpmText, r, g, b, startSlice: startSlice);
      await bleService.sendPattern(matrix);
      _lastSentRpm = currentRpm;
    } finally {
      if (mounted) {
        _isSending = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectionStatus = ref.watch(connectionStatusProvider);
    final bleService = ref.read(bluetoothServiceProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text('Live RPM Sync'),
        backgroundColor: Colors.black87,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.speed, size: 100, color: Colors.orangeAccent),
            const SizedBox(height: 30),
            
            // Listen to the RPM updates in real time
            ValueListenableBuilder<int>(
              valueListenable: bleService.rpmNotifier,
              builder: (context, rpm, child) {
                return Text(
                  "$rpm RPM",
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                );
              },
            ),
            
            const SizedBox(height: 10),
            Text(
              "Keep this screen open to beam live RPM to the display.",
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16),
            ),
            const SizedBox(height: 40),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Text Color: ', style: TextStyle(color: Colors.white, fontSize: 18)),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _showColorPicker,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: _selectedColor.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            connectionStatus.when(
              data: (isConnected) {
                if (isConnected) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Listening to ESP32 telemetry...",
                        style: TextStyle(color: Colors.greenAccent.withOpacity(0.8), fontSize: 14),
                      ),
                    ],
                  );
                } else {
                  return const Text(
                    "Device Disconnected.",
                    style: TextStyle(color: Colors.redAccent, fontSize: 16),
                  );
                }
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text("Error checking connection status", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
