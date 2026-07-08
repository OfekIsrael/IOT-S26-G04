import 'dart:math';
import 'utils/digital_font.dart';

class PredefinedPatterns {
  
  // Creates an empty 36x29 black canvas
  static List<List<int>> _createCanvas() {
    return List.generate(36, (_) => List.filled(29 * 3, 0));
  }

  // Set pixel safely helper
  static void _setPixel(List<List<int>> canvas, int slice, int ledIndex, int r, int g, int b) {
    if (slice >= 0 && slice < 36 && ledIndex >= 0 && ledIndex < 29) {
      canvas[slice][ledIndex * 3] = r;
      canvas[slice][ledIndex * 3 + 1] = g;
      canvas[slice][ledIndex * 3 + 2] = b;
    }
  }

  // 1. Rainbow Spiral
  static List<List<int>> getSpiralPattern() {
    final canvas = _createCanvas();
    for (int s = 0; s < 36; s++) {
      for (int l = 0; l < 29; l++) {
        // Hue shift based on slice and led index
        double hue = (s / 36.0 + l / 29.0) % 1.0;
        final rgb = _hsvToRgb(hue, 1.0, 1.0);
        
        // Only light up a spiral shape
        if ((s + l) % 8 < 2) {
           _setPixel(canvas, s, l, rgb[0], rgb[1], rgb[2]);
        }
      }
    }
    return canvas;
  }

  // 2. Concentric Rings
  static List<List<int>> getRingsPattern() {
    final canvas = _createCanvas();
    for (int s = 0; s < 36; s++) {
      for (int l = 0; l < 29; l++) {
        if (l % 5 == 0) {
          int r = (s * 7) % 255;
          int g = (255 - s * 7) % 255;
          int b = 150;
          _setPixel(canvas, s, l, r, g, b);
        }
      }
    }
    return canvas;
  }

  // 3. Simple Star
  static List<List<int>> getStarPattern() {
    final canvas = _createCanvas();
    // A 5 point star roughly maps to 5 arms in polar coordinates
    for (int s = 0; s < 36; s++) {
      // 5 arms evenly spaced in 36 slices (roughly every 7 slices)
      if (s % 7 == 0) {
        for (int l = 0; l < 29; l++) {
           _setPixel(canvas, s, l, 255, 200, 0); // Yellow/Gold
        }
      }
    }
    return canvas;
  }

  // 4. Solid Color Test
  static List<List<int>> getSolidPattern(int r, int g, int b) {
    final canvas = _createCanvas();
    for (int s = 0; s < 36; s++) {
      for (int l = 0; l < 29; l++) {
        _setPixel(canvas, s, l, r, g, b);
      }
    }
    return canvas;
  }

  // Helper for HSV to RGB
  static List<int> _hsvToRgb(double h, double s, double v) {
    int r = 0, g = 0, b = 0;
    int i = (h * 6).floor();
    double f = h * 6 - i;
    double p = v * (1 - s);
    double q = v * (1 - f * s);
    double t = v * (1 - (1 - f) * s);
    switch (i % 6) {
      case 0: r = (v * 255).round(); g = (t * 255).round(); b = (p * 255).round(); break;
      case 1: r = (q * 255).round(); g = (v * 255).round(); b = (p * 255).round(); break;
      case 2: r = (p * 255).round(); g = (v * 255).round(); b = (t * 255).round(); break;
      case 3: r = (p * 255).round(); g = (q * 255).round(); b = (v * 255).round(); break;
      case 4: r = (t * 255).round(); g = (p * 255).round(); b = (v * 255).round(); break;
      case 5: r = (v * 255).round(); g = (p * 255).round(); b = (q * 255).round(); break;
    }
    return [r, g, b];
  }
  // 5. Digital Clock
  static List<List<int>> getDigitalClockPattern(DateTime time, int r, int g, int b) {
    final canvas = _createCanvas();
    
    String h = time.hour.toString().padLeft(2, '0');
    String m = time.minute.toString().padLeft(2, '0');
    String timeStr = "$h:$m";

    // Draw the clock only in the second half of the circle (slices 18-35)
    int startSlice = 18 + 1; // +1 to give it a little padding from the edge
    int currentSlice = startSlice;
    
    for (int i = 0; i < timeStr.length; i++) {
      String char = timeStr[i];
      List<List<int>>? charPattern = DigitalFont.font[char];
      
      if (charPattern != null) {
        int charWidth = charPattern[0].length;
        int charHeight = charPattern.length;
        int scaleY = 2; // Stretch vertically to make it bigger
        
        for (int cSlice = 0; cSlice < charWidth; cSlice++) {
          for (int cRing = 0; cRing < charHeight * scaleY; cRing++) {
            int originalRing = cRing ~/ scaleY; // Map back to 5-pixel height
            
            if (charPattern[originalRing][cSlice] == 1) {
                // Reverse the slice mapping to fix the mirroring on the physical display
                int displaySlice = (36 - (currentSlice + cSlice)) % 36;
                
                // LED 0 is on the OUTSIDE, LED 28 is on the INSIDE.
                // cRing=0 is the top of the character, which should be on the outside edge.
                int displayRing = cRing + 1;
                
                _setPixel(canvas, displaySlice, displayRing, r, g, b);
            }
          }
        }
        currentSlice += charWidth + 1; // Move past char and add 1 slice of spacing
      }
    }

    return canvas;
  }

  // 6. Custom Text
  static List<List<int>> getTextPattern(String text, int r, int g, int b) {
    final canvas = _createCanvas();
    String upperText = text.toUpperCase();

    int currentSlice = 19; // Start at slice 19 (second half of the rotation)

    for (int i = 0; i < upperText.length; i++) {
      String char = upperText[i];
      List<List<int>>? charPattern = DigitalFont.font[char];
      
      // Default to space if char not found
      charPattern ??= DigitalFont.font[' '];
      
      if (charPattern != null) {
        int charWidth = charPattern[0].length;
        int charHeight = charPattern.length;
        int scaleY = 2; // Stretch vertically to make it bigger

        for (int cSlice = 0; cSlice < charWidth; cSlice++) {
          for (int cRing = 0; cRing < charHeight * scaleY; cRing++) {
            int originalRing = cRing ~/ scaleY; 
            
            if (charPattern[originalRing][cSlice] == 1) {
                int targetSlice = (currentSlice + cSlice) % 36;
                // Reverse the slice mapping to fix the mirroring on the physical display
                int displaySlice = (36 - targetSlice) % 36;
                
                // LED 0 is on the OUTSIDE
                int displayRing = cRing + 1;
                
                _setPixel(canvas, displaySlice, displayRing, r, g, b);
            }
          }
        }
        currentSlice += charWidth + 1; // Move past char and add 1 slice of spacing
      }
    }

    return canvas;
  }
}
