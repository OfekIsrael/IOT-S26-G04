import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers.dart';
import '../utils/image_processor.dart';

class ImageScreen extends ConsumerStatefulWidget {
  const ImageScreen({super.key});

  @override
  ConsumerState<ImageScreen> createState() => _ImageScreenState();
}

class _ImageScreenState extends ConsumerState<ImageScreen> {
  Uint8List? _imageBytes;
  bool _isProcessing = false;
  bool _isSending = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _processAndSend() async {
    if (_imageBytes == null || _isProcessing || _isSending) return;

    final bleService = ref.read(bluetoothServiceProvider);
    if (bleService.connectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect to the POV Display first!')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Process image to matrix (do this in a microtask to allow UI to update to 'Processing...')
      final matrix = await Future.microtask(() => ImageProcessor.processImageToPolarMatrix(_imageBytes!));
      
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isSending = true;
        });
      }

      // Send via BLE
      bool success = await bleService.sendPattern(matrix);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image beamed successfully!'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to send image.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Processing error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text('Upload Image'),
        backgroundColor: Colors.black87,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_imageBytes != null)
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: MemoryImage(_imageBytes!),
                    fit: BoxFit.cover,
                  ),
                  border: Border.all(color: Colors.white, width: 2),
                ),
              )
            else
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white10,
                  border: Border.all(color: Colors.white30, width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.image, size: 80, color: Colors.white54),
                ),
              ),
            
            const SizedBox(height: 40),
            
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Choose Photo'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            
            const SizedBox(height: 20),
            
            if (_imageBytes != null)
              ElevatedButton.icon(
                onPressed: _isProcessing || _isSending ? null : _processAndSend,
                icon: _isProcessing || _isSending 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.upload),
                label: Text(_isProcessing ? 'Processing...' : (_isSending ? 'Beaming...' : 'Beam to Display')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
