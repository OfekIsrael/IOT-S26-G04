import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers.dart';
import '../patterns.dart';

class CustomTextScreen extends ConsumerStatefulWidget {
  const CustomTextScreen({super.key});

  @override
  ConsumerState<CustomTextScreen> createState() => _CustomTextScreenState();
}

class _CustomTextScreenState extends ConsumerState<CustomTextScreen> {
  final TextEditingController _textController = TextEditingController();
  Color _selectedColor = Colors.cyanAccent;
  bool _isSending = false;

  void _showColorPicker() {
    Color pickerColor = _selectedColor;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick text color'),
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
              },
            ),
          ],
        );
      },
    );
  }

  void _sendText() async {
    String text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some text!')),
      );
      return;
    }

    setState(() => _isSending = true);
    
    final bleService = ref.read(bluetoothServiceProvider);
    
    int r = (_selectedColor.r * 255.0).round().clamp(0, 255);
    int g = (_selectedColor.g * 255.0).round().clamp(0, 255);
    int b = (_selectedColor.b * 255.0).round().clamp(0, 255);

    final matrix = PredefinedPatterns.getTextPattern(text, r, g, b);
    
    bool success = await bleService.sendPattern(matrix);
    
    if (mounted) {
      setState(() => _isSending = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Text sent successfully!'), backgroundColor: Colors.green),
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
        title: const Text('Custom Text Input'),
        backgroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter up to 9 characters to wrap around the display:',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _textController,
              maxLength: 9,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              inputFormatters: [
                UpperCaseTextFormatter(),
              ],
              decoration: InputDecoration(
                hintText: 'HELLO',
                hintStyle: TextStyle(color: Colors.white24),
                counterStyle: const TextStyle(color: Colors.white54),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white24, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _selectedColor, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: Colors.black26,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Text Color: ', style: TextStyle(color: Colors.white, fontSize: 18)),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _showColorPicker,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: _selectedColor.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _isSending ? null : _sendText,
              child: _isSending
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'BEAM TO DISPLAY',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
