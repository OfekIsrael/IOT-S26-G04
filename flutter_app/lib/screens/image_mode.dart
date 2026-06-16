import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

class ImageModeScreen extends ConsumerStatefulWidget {
  const ImageModeScreen({super.key});

  @override
  ConsumerState<ImageModeScreen> createState() => _ImageModeScreenState();
}

class _ImageModeScreenState extends ConsumerState<ImageModeScreen> {
  File? _imageFile;
  bool _isProcessing = false;
  
  // LED Strip specific settings (can be configured later)
  final int _ledCount = 64; // e.g., 64 LEDs on the rotating strip
  final int _rotationSlices = 128; // e.g., 128 slices for a full rotation (resolution)

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _processAndSendImage() async {
    if (_imageFile == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Read the image file
      final bytes = await _imageFile!.readAsBytes();
      
      // Decode the image
      img.Image? originalImage = img.decodeImage(bytes);
      
      if (originalImage != null) {
        // Resize the image to fit the POV resolution (e.g., 128x64)
        // width = rotationSlices (x axis for rotation), height = ledCount (y axis for led strip)
        img.Image resizedImage = img.copyResize(
          originalImage, 
          width: _rotationSlices, 
          height: _ledCount,
        );

        // Convert to 1D RGB Array
        List<int> rgbArray = [];
        
        for (int y = 0; y < resizedImage.height; y++) {
          for (int x = 0; x < resizedImage.width; x++) {
            // Get pixel color (ARGB format)
            img.Pixel pixel = resizedImage.getPixel(x, y);
            
            // Extract RGB values
            rgbArray.add(pixel.r.toInt());
            rgbArray.add(pixel.g.toInt());
            rgbArray.add(pixel.b.toInt());
          }
        }

        // Send to ESP32 using the unified CommunicationService
        final commService = ref.read(communicationServiceProvider);
        
        // Tell the ESP32 we are entering image mode
        bool modeSuccess = await commService.setMode('image');
        
        if (modeSuccess) {
           bool uploadSuccess = await commService.sendImageData(rgbArray);
           if (uploadSuccess && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Image sent successfully!'), backgroundColor: Colors.green),
              );
           } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to upload image data'), backgroundColor: Colors.red),
              );
           }
        } else if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to set ESP32 to image mode'), backgroundColor: Colors.red),
           );
        }

      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing image: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Mode'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_imageFile != null)
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(_imageFile!, fit: BoxFit.contain),
                ),
              )
            else
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).primaryColor, width: 2, style: BorderStyle.solid),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_search, size: 64, color: Theme.of(context).primaryColor),
                        const SizedBox(height: 16),
                        const Text('No image selected', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Select from Gallery'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: (_imageFile == null || _isProcessing) ? null : _processAndSendImage,
              icon: _isProcessing 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send),
              label: Text(_isProcessing ? 'Processing & Sending...' : 'Send to POV LED'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
