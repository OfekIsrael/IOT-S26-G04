import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageProcessor {
  static const int numSlices = 36;
  static const int numRings = 29;

  /// Takes an image byte array, processes it, and returns the 36x29x3 matrix
  static List<List<int>> processImageToPolarMatrix(Uint8List imageBytes) {
    // 1. Decode Image
    img.Image? srcImg = img.decodeImage(imageBytes);
    if (srcImg == null) throw Exception("Failed to decode image");

    // 2. Crop to square
    int w = srcImg.width;
    int h = srcImg.height;
    int side = math.min(w, h);
    int left = (w - side) ~/ 2;
    int top = (h - side) ~/ 2;
    
    img.Image cropped = img.copyCrop(srcImg, x: left, y: top, width: side, height: side);

    // 3. Resize to diameter (2 * numRings + 1) = 59
    int diameter = 2 * numRings + 1;
    img.Image resized = img.copyResize(cropped, width: diameter, height: diameter, interpolation: img.Interpolation.linear);

    // 4. Sample into Polar Grid and Map to Hardware Array
    double cx = (diameter - 1) / 2.0;
    double cy = (diameter - 1) / 2.0;

    // Output matrix initialized to black
    List<List<int>> matrix = List.generate(numSlices, (_) => List.filled(numRings * 3, 0));

    for (int sOut = 0; sOut < numSlices; sOut++) {
      // Python FIX 1: reverse slice order to fix horizontal mirroring
      int mappedSlice = (numSlices - sOut) % numSlices;
      
      double theta = mappedSlice * (2 * math.pi / numSlices);
      double cosT = math.cos(theta);
      double sinT = math.sin(theta);

      for (int rOut = 0; rOut < numRings; rOut++) {
        // Python FIX 2: reverse ring order
        // rOut = 0 is the outer edge, so sample radius = numRings - 1
        int sampleRadius = (numRings - 1) - rOut;
        
        double dx = sampleRadius * cosT;
        double dy = sampleRadius * sinT;

        int col = (cx + dx).round();
        int row = (cy - dy).round(); // Image rows grow downward

        if (row >= 0 && row < diameter && col >= 0 && col < diameter) {
          img.Pixel pixel = resized.getPixel(col, row);
          
          if (pixel.a < 16) {
             matrix[sOut][rOut * 3 + 0] = 0;
             matrix[sOut][rOut * 3 + 1] = 0;
             matrix[sOut][rOut * 3 + 2] = 0;
          } else {
             matrix[sOut][rOut * 3 + 0] = pixel.r.toInt();
             matrix[sOut][rOut * 3 + 1] = pixel.g.toInt();
             matrix[sOut][rOut * 3 + 2] = pixel.b.toInt();
          }
        }
      }
    }

    return matrix;
  }
}
